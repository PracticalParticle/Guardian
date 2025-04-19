# Certora Formal Verification

This directory contains the Certora Prover specifications and configurations for formal verification of the smart contracts in this project.

## Directory Structure

- `specs/`: Contains the Certora Verification Language (CVL) specification files
- `conf/`: Contains the configuration files for running the Certora Prover

## Specifications

The following specification files are provided:

- `secureOwnable.spec`: Verifies the security properties of the `SecureOwnable` contract
- `multiPhaseOperation.spec`: Verifies the security properties of the `MultiPhaseSecureOperation` library

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

3. Run the verification:
   ```bash
   certoraRun certora/conf/secureOwnable.conf
   certoraRun certora/conf/multiPhaseOperation.conf
   ```

## CI/CD Integration

The project includes a GitHub Actions workflow that automatically runs formal verification on pull requests and pushes to the main branch. The workflow is defined in `.github/workflows/certora-verification.yml`.

To set up CI/CD integration:

1. Add your Certora key as a GitHub secret named `CERTORAKEY` in your repository settings.

2. The workflow will automatically run on pull requests and pushes to main.

## Mutation Testing

The CI/CD workflow also includes mutation testing to estimate the coverage of the specifications:

```bash
certoraMutate --conf certora/conf/secureOwnable.conf
certoraMutate --conf certora/conf/multiPhaseOperation.conf
```

You can run this locally to identify potential gaps in your specifications.

## Writing New Specifications

When adding new contracts to the project, consider adding Certora specifications for them:

1. Create a new `.spec` file in the `specs/` directory
2. Create a new `.conf` file in the `conf/` directory
3. Add the verification job to the GitHub Actions workflow

## Best Practices

- Focus on verifying critical security properties
- Write modular specifications that are maintainable
- Use invariants to express properties that should always hold
- Use rules to express properties about state transitions
- Start with simple properties and gradually add more complex ones 