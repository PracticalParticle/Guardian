# Certora Formal Verification

This directory contains the Certora Prover specifications and configurations for formal verification of the smart contracts in this project.

## Directory Structure

- `specs/`: Contains the Certora Verification Language (CVL) specification files
- `conf/`: Contains the configuration files for running the Certora Prover
- `harness/`: Contains harness contracts for better testing of libraries and complex contracts

## Specifications

The following specification files are provided:

- `secureOwnable.spec`: Verifies the security properties of the `SecureOwnable` contract
- `secureOwnableInvariants.spec`: Verifies invariants that should always hold for the `SecureOwnable` contract
- `multiPhaseOperation.spec`: Verifies the security properties of the `MultiPhaseSecureOperation` library
- `propertyBasedTesting.spec`: Contains property-based tests with multiple inputs and edge cases
- `environment_model.spec`: Provides standard environment models and assumptions for verification
- `security_properties.spec`: Focused on critical security properties with high assurance requirements

## Harness Contracts

- `MultiPhaseSecureOperationHarness.sol`: Harness contract to test the `MultiPhaseSecureOperation` library functions in isolation
- `SecureOwnableHarness.sol`: Harness contract to expose internal state and functions of the `SecureOwnable` contract

## Configuration Files

- `secureOwnable.conf`: Basic verification of SecureOwnable contract
- `multiPhaseOperation.conf`: Basic verification of MultiPhaseSecureOperation library
- `default.conf`: Comprehensive verification of all contracts and specifications
- `security.conf`: Focused security verification with higher timeouts and more thorough analysis

## Running Locally

To run the formal verification locally, you need to:

1. Install the Certora CLI:
   ```bash
   pip install certora-cli
   ```

2. Set up your Certora API key as an environment variable:
   ```bash
   export CERTORAKEY=your_key_here
   ```

3. Install the required Solidity compiler version:
   ```bash
   pip install solc-select
   solc-select install 0.8.2
   solc-select use 0.8.2
   ```

4. Run individual verifications:
   ```bash
   certoraRun certora/conf/secureOwnable.conf
   certoraRun certora/conf/multiPhaseOperation.conf
   ```

5. For security-focused verification:
   ```bash
   certoraRun certora/conf/security.conf
   ```

6. Or run comprehensive verification:
   ```bash
   certoraRun certora/conf/default.conf
   ```

7. To verify specific rules only:
   ```bash
   certoraRun certora/conf/secureOwnable.conf --rule ownershipDoesNotChangeWithoutTransfer
   ```

## CI/CD Integration

The project includes a GitHub Actions workflow that automatically runs formal verification on pull requests and pushes to the main branch. The workflow is defined in `.github/workflows/certora-verification.yml`.

### Features of the CI/CD Workflow:

- **Matrix Strategy**: Runs verification for each contract/library in parallel
- **Security Verification**: Dedicated job for security-critical properties
- **Comprehensive Verification**: Runs all specs on push to main branch
- **Artifact Upload**: Saves verification reports as build artifacts
- **Custom Verification**: Supports running specific specs through workflow dispatch
- **Path Filtering**: Only triggers on relevant file changes
- **Security-Only Mode**: Option to run only security verification

### Setting Up CI/CD:

1. Add your Certora key as a GitHub secret named `CERTORAKEY` in your repository settings.

2. The workflow will automatically run on pull requests and pushes to main when relevant files change.

3. To manually trigger verification:
   - Go to the Actions tab in your repository
   - Select "Certora Formal Verification" workflow
   - Click "Run workflow"
   - Options:
     - Enter the spec file path and/or contract name if desired
     - Check "Run only security verification" for focused security runs

## Mutation Testing

The CI/CD workflow also includes mutation testing to estimate the coverage of the specifications:

```bash
certoraMutate --conf certora/conf/secureOwnable.conf --num_mutations 5
certoraMutate --conf certora/conf/multiPhaseOperation.conf --num_mutations 5
certoraMutate --conf certora/conf/security.conf --num_mutations 3
```

The mutation testing results are saved as artifacts in the CI/CD workflow.

## Environment Models

The project includes a dedicated environment model specification that provides standard assumptions and constraints for verification. This helps ensure consistency across different specifications.

Key features of environment models:
- Standard role-based environments (owner, broadcaster, recovery, other)
- Time-based environments for timelock testing
- Ghost constants for standardized parameter ranges
- Common filter definitions for invariants

## Security-Focused Verification

For critical security assurance, we provide dedicated security verification:

1. **Security Properties**: The `security_properties.spec` file contains high-assurance properties focused exclusively on critical security aspects
2. **Enhanced Configuration**: The `security.conf` file uses higher timeouts and more thorough analysis settings
3. **CI/CD Integration**: Security verification runs as a separate job for focused analysis

## Writing New Specifications

When adding new contracts to the project, consider adding Certora specifications for them:

1. Create a new `.spec` file in the `specs/` directory
2. Create a new `.conf` file in the `conf/` directory
3. Consider creating a harness contract in the `harness/` directory
4. Import the environment model for standardized assumptions
5. Add the verification job to the GitHub Actions workflow

## Best Practices

- **Focus on Critical Properties**: Prioritize security properties and invariants
- **Modular Specifications**: Split specifications into rules, invariants, and property-based tests
- **Harness Contracts**: Use harness contracts for libraries and complex contracts
- **Edge Cases**: Test edge cases with property-based testing
- **Environment Models**: Use the shared environment model for consistent assumptions
- **Graduated Verification**: Start with basic specs and gradually add more complex properties
- **Rule Isolation**: Test individual rules before running comprehensive verification
- **Cache Results**: Use caching to speed up verification of unchanged code

## Troubleshooting

- If verification fails with timeout errors, consider increasing the timeout in the configuration:
  ```json
  "prover_args": ["-mediumTimeout 300"]
  ```

- For complex contracts, you may need to set loop unrolling parameters:
  ```json
  "loop_iter": "3",
  "prover_args": ["-copyLoopUnroll 3"]
  ```

- If you get "undefined function" errors, check that your harness contract exposes all needed functions

- For better SMT solver performance, adjust the timeout:
  ```json
  "smt_timeout": 1800
  ```

- If your specification needs access to internal state, make sure your harness exposes all required state variables and functions 