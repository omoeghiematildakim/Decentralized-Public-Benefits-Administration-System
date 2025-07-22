# Decentralized Public Benefits Administration System

A blockchain-based public benefits administration system built on Stacks using Clarity smart contracts. This system provides transparent, efficient, and fraud-resistant management of government assistance programs.

## System Overview

The system consists of five interconnected smart contracts that work together to manage public benefits:

### 1. Eligibility Verification Contract (`eligibility-verification.clar`)
- Determines qualification for government assistance programs
- Validates income, household size, and other eligibility criteria
- Maintains secure records of eligibility status
- Supports multiple program types (SNAP, TANF, Medicaid, etc.)

### 2. Benefit Distribution Contract (`benefit-distribution.clar`)
- Automates benefit payments to qualified recipients
- Prevents double-spending and unauthorized distributions
- Tracks payment history and remaining balances
- Supports multiple payment schedules and amounts

### 3. Case Management Contract (`case-management.clar`)
- Tracks individual cases across multiple assistance programs
- Maintains comprehensive case histories
- Manages case worker assignments and updates
- Provides audit trails for all case activities

### 4. Fraud Detection Contract (`fraud-detection.clar`)
- Identifies suspicious benefit claims and usage patterns
- Implements automated fraud scoring algorithms
- Flags cases for manual review when thresholds are exceeded
- Maintains fraud investigation records

### 5. Program Evaluation Contract (`program-evaluation.clar`)
- Measures effectiveness of public assistance programs
- Tracks key performance indicators and outcomes
- Generates reports on program utilization and success rates
- Supports data-driven policy decisions

## Key Features

- **Transparency**: All transactions and decisions are recorded on the blockchain
- **Fraud Prevention**: Automated detection and prevention of fraudulent claims
- **Efficiency**: Streamlined processes reduce administrative overhead
- **Privacy**: Sensitive data is protected while maintaining transparency
- **Interoperability**: Contracts work together to provide comprehensive benefits management
- **Auditability**: Complete audit trails for all system activities

## Technical Architecture

### Data Types
- **Applicant**: Individual applying for or receiving benefits
- **Program**: Specific assistance program (SNAP, TANF, etc.)
- **Case**: Individual benefit case with status and history
- **Payment**: Benefit payment record with amount and date
- **Alert**: Fraud detection alert with severity and details

### Security Features
- Role-based access control for administrators and case workers
- Input validation and sanitization
- Fraud detection algorithms
- Audit logging for all operations

### Error Handling
- Comprehensive error codes for different failure scenarios
- Graceful handling of edge cases
- Clear error messages for debugging and user feedback

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for deployment

### Installation
\`\`\`bash
git clone <repository-url>
cd public-benefits-admin
npm install
\`\`\`

### Testing
\`\`\`bash
npm test
\`\`\`

### Deployment
\`\`\`bash
clarinet deploy
\`\`\`

## Usage Examples

### Register New Applicant
\`\`\`clarity
(contract-call? .eligibility-verification register-applicant
"John Doe"
u25000
u3
"123 Main St")
\`\`\`

### Check Eligibility
\`\`\`clarity
(contract-call? .eligibility-verification check-eligibility
'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECNWWALK
"SNAP")
\`\`\`

### Distribute Benefits
\`\`\`clarity
(contract-call? .benefit-distribution distribute-benefits
'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECNWWALK
"SNAP"
u500)
\`\`\`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or support, please open an issue on GitHub or contact the development team.
