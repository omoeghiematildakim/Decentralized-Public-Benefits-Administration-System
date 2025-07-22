;; Fraud Detection Contract
;; Identifies suspicious benefit claims and usage patterns

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-ALERT-NOT-FOUND (err u401))
(define-constant ERR-INVALID-SCORE (err u402))
(define-constant ERR-INVALID-INPUT (err u403))
(define-constant ERR-INVESTIGATION-NOT-FOUND (err u404))

;; Fraud thresholds
(define-constant FRAUD-THRESHOLD-LOW u30)
(define-constant FRAUD-THRESHOLD-MEDIUM u60)
(define-constant FRAUD-THRESHOLD-HIGH u80)

;; Data Variables
(define-data-var next-alert-id uint u1)
(define-data-var next-investigation-id uint u1)

;; Data Maps
(define-map fraud-alerts
  { alert-id: uint }
  {
    subject: principal,
    program-name: (string-ascii 50),
    alert-type: (string-ascii 30),
    severity: (string-ascii 10),
    fraud-score: uint,
    description: (string-ascii 300),
    created-date: uint,
    status: (string-ascii 20),
    investigated-by: (optional principal),
    resolution-date: (optional uint)
  }
)

(define-map fraud-scores
  { subject: principal, program-name: (string-ascii 50) }
  {
    current-score: uint,
    last-updated: uint,
    factors: (list 10 (string-ascii 50)),
    risk-level: (string-ascii 10)
  }
)

(define-map fraud-patterns
  { pattern-name: (string-ascii 50) }
  {
    description: (string-ascii 200),
    weight: uint,
    is-active: bool,
    detection-count: uint
  }
)

(define-map investigations
  { investigation-id: uint }
  {
    alert-id: uint,
    investigator: principal,
    subject: principal,
    program-name: (string-ascii 50),
    start-date: uint,
    end-date: (optional uint),
    status: (string-ascii 20),
    findings: (string-ascii 500),
    recommended-action: (string-ascii 100)
  }
)

(define-map subject-flags
  { subject: principal }
  {
    total-alerts: uint,
    high-risk-alerts: uint,
    investigations: uint,
    last-flag-date: uint,
    is-blacklisted: bool
  }
)

;; Initialize fraud patterns
(map-set fraud-patterns
  { pattern-name: "MULTIPLE_APPLICATIONS" }
  { description: "Multiple applications for same program", weight: u25, is-active: true, detection-count: u0 }
)

(map-set fraud-patterns
  { pattern-name: "INCOME_DISCREPANCY" }
  { description: "Reported income inconsistent with records", weight: u30, is-active: true, detection-count: u0 }
)

(map-set fraud-patterns
  { pattern-name: "RAPID_CHANGES" }
  { description: "Frequent changes to personal information", weight: u20, is-active: true, detection-count: u0 }
)

(map-set fraud-patterns
  { pattern-name: "SUSPICIOUS_TIMING" }
  { description: "Applications submitted at suspicious times", weight: u15, is-active: true, detection-count: u0 }
)

;; Private Functions
(define-private (is-authorized (caller principal))
  (or (is-eq caller CONTRACT-OWNER) (is-investigator caller))
)

(define-private (is-investigator (caller principal))
  ;; In a real implementation, this would check against a list of authorized investigators
  (is-eq caller CONTRACT-OWNER)
)

(define-private (calculate-risk-level (score uint))
  (if (>= score FRAUD-THRESHOLD-HIGH)
    "HIGH"
    (if (>= score FRAUD-THRESHOLD-MEDIUM)
      "MEDIUM"
      (if (>= score FRAUD-THRESHOLD-LOW)
        "LOW"
        "MINIMAL"
      )
    )
  )
)

(define-private (get-severity-from-score (score uint))
  (if (>= score FRAUD-THRESHOLD-HIGH)
    "CRITICAL"
    (if (>= score FRAUD-THRESHOLD-MEDIUM)
      "HIGH"
      (if (>= score FRAUD-THRESHOLD-LOW)
        "MEDIUM"
        "LOW"
      )
    )
  )
)

;; Public Functions
(define-public (create-fraud-alert (subject principal) (program-name (string-ascii 50)) (alert-type (string-ascii 30)) (fraud-score uint) (description (string-ascii 300)))
  (let
    (
      (alert-id (var-get next-alert-id))
      (severity (get-severity-from-score fraud-score))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= fraud-score u100) ERR-INVALID-SCORE)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)

    (map-set fraud-alerts
      { alert-id: alert-id }
      {
        subject: subject,
        program-name: program-name,
        alert-type: alert-type,
        severity: severity,
        fraud-score: fraud-score,
        description: description,
        created-date: block-height,
        status: "OPEN",
        investigated-by: none,
        resolution-date: none
      }
    )

    ;; Update subject flags
    (let
      (
        (current-flags (default-to
          { total-alerts: u0, high-risk-alerts: u0, investigations: u0, last-flag-date: u0, is-blacklisted: false }
          (map-get? subject-flags { subject: subject })
        ))
        (is-high-risk (>= fraud-score FRAUD-THRESHOLD-HIGH))
      )
      (map-set subject-flags
        { subject: subject }
        {
          total-alerts: (+ (get total-alerts current-flags) u1),
          high-risk-alerts: (+ (get high-risk-alerts current-flags) (if is-high-risk u1 u0)),
          investigations: (get investigations current-flags),
          last-flag-date: block-height,
          is-blacklisted: (get is-blacklisted current-flags)
        }
      )
    )

    (var-set next-alert-id (+ alert-id u1))
    (ok alert-id)
  )
)

(define-public (update-fraud-score (subject principal) (program-name (string-ascii 50)) (new-score uint) (factors (list 10 (string-ascii 50))))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-score u100) ERR-INVALID-SCORE)

    (map-set fraud-scores
      { subject: subject, program-name: program-name }
      {
        current-score: new-score,
        last-updated: block-height,
        factors: factors,
        risk-level: (calculate-risk-level new-score)
      }
    )

    ;; Create alert if score is above threshold
    (if (>= new-score FRAUD-THRESHOLD-LOW)
      (create-fraud-alert subject program-name "AUTOMATED_DETECTION" new-score "Automated fraud detection triggered")
      (ok u0)
    )
  )
)

(define-public (start-investigation (alert-id uint) (investigator principal))
  (let
    (
      (alert-data (map-get? fraud-alerts { alert-id: alert-id }))
      (investigation-id (var-get next-investigation-id))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some alert-data) ERR-ALERT-NOT-FOUND)

    (let
      (
        (alert-info (unwrap! alert-data ERR-ALERT-NOT-FOUND))
      )
      ;; Update alert status
      (map-set fraud-alerts
        { alert-id: alert-id }
        (merge alert-info {
          status: "INVESTIGATING",
          investigated-by: (some investigator)
        })
      )

      ;; Create investigation record
      (map-set investigations
        { investigation-id: investigation-id }
        {
          alert-id: alert-id,
          investigator: investigator,
          subject: (get subject alert-info),
          program-name: (get program-name alert-info),
          start-date: block-height,
          end-date: none,
          status: "ACTIVE",
          findings: "",
          recommended-action: ""
        }
      )

      (var-set next-investigation-id (+ investigation-id u1))
      (ok investigation-id)
    )
  )
)

(define-public (close-investigation (investigation-id uint) (findings (string-ascii 500)) (recommended-action (string-ascii 100)))
  (let
    (
      (investigation-data (map-get? investigations { investigation-id: investigation-id }))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some investigation-data) ERR-INVESTIGATION-NOT-FOUND)
    (asserts! (> (len findings) u0) ERR-INVALID-INPUT)

    (let
      (
        (investigation-info (unwrap! investigation-data ERR-INVESTIGATION-NOT-FOUND))
        (alert-id (get alert-id investigation-info))
      )
      ;; Update investigation
      (map-set investigations
        { investigation-id: investigation-id }
        (merge investigation-info {
          end-date: (some block-height),
          status: "CLOSED",
          findings: findings,
          recommended-action: recommended-action
        })
      )

      ;; Update related alert
      (match (map-get? fraud-alerts { alert-id: alert-id })
        alert-data (map-set fraud-alerts
          { alert-id: alert-id }
          (merge alert-data {
            status: "RESOLVED",
            resolution-date: (some block-height)
          })
        )
        false
      )

      (ok true)
    )
  )
)

(define-public (blacklist-subject (subject principal) (reason (string-ascii 200)))
  (let
    (
      (current-flags (default-to
        { total-alerts: u0, high-risk-alerts: u0, investigations: u0, last-flag-date: u0, is-blacklisted: false }
        (map-get? subject-flags { subject: subject })
      ))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len reason) u0) ERR-INVALID-INPUT)

    (map-set subject-flags
      { subject: subject }
      (merge current-flags { is-blacklisted: true })
    )

    (ok true)
  )
)

(define-public (add-fraud-pattern (pattern-name (string-ascii 50)) (description (string-ascii 200)) (weight uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len pattern-name) u0) ERR-INVALID-INPUT)
    (asserts! (<= weight u50) ERR-INVALID-SCORE)

    (map-set fraud-patterns
      { pattern-name: pattern-name }
      {
        description: description,
        weight: weight,
        is-active: true,
        detection-count: u0
      }
    )

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-fraud-alert (alert-id uint))
  (map-get? fraud-alerts { alert-id: alert-id })
)

(define-read-only (get-fraud-score (subject principal) (program-name (string-ascii 50)))
  (map-get? fraud-scores { subject: subject, program-name: program-name })
)

(define-read-only (get-subject-flags (subject principal))
  (map-get? subject-flags { subject: subject })
)

(define-read-only (get-investigation (investigation-id uint))
  (map-get? investigations { investigation-id: investigation-id })
)

(define-read-only (get-fraud-pattern (pattern-name (string-ascii 50)))
  (map-get? fraud-patterns { pattern-name: pattern-name })
)

(define-read-only (is-subject-blacklisted (subject principal))
  (match (get-subject-flags subject)
    flags (get is-blacklisted flags)
    false
  )
)

(define-read-only (get-risk-assessment (subject principal) (program-name (string-ascii 50)))
  (match (get-fraud-score subject program-name)
    score-data {
      score: (get current-score score-data),
      risk-level: (get risk-level score-data),
      last-updated: (get last-updated score-data),
      factors: (get factors score-data)
    }
    {
      score: u0,
      risk-level: "MINIMAL",
      last-updated: u0,
      factors: (list)
    }
  )
)
