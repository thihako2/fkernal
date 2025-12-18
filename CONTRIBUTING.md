# Contributing to FKernal

First off, thank you for considering contributing to FKernal! It's people like you that make FKernal such a great tool.

## Code of Conduct
By participating in this project, you are expected to uphold our Code of Conduct. Please report any unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs
- **Check for duplicates**: Before opening a new issue, please check if the bug has already been reported.
- **Be specific**: Provide as much detail as possible, including steps to reproduce, expected behavior, and actual behavior.
- **Include environment details**: Flutter version, Dart version, OS, and any relevant package versions.

### Suggesting Enhancements
- **Explain the "Why"**: Describe the problem you're trying to solve and how the enhancement would help.
- **Provide examples**: If possible, include code snippets or diagrams to illustrate your idea.

### Pull Requests
1. **Fork the repository** and create your branch from `main`.
2. **Follow the style guide**: Ensure your code adheres to the project's linting rules and formatting.
3. **Write tests**: Any new features or bug fixes should include corresponding tests.
4. **Update documentation**: If your change affects how users interact with the framework, update the `README.md` or relevant files.
5. **Describe your changes**: In your PR description, explain what you did and why.

## Development Setup

1. **Clone the repo**:
   ```bash
   git clone https://github.com/opposive/fkernal.git
   ```
2. **Install dependencies**:
   ```bash
   cd packages/fkernal
   flutter pub get
   ```
3. **Run tests**:
   ```bash
   flutter test
   ```

## Design Principles
- **Configuration over Implementation**: If something can be declared in a config object, it should be.
- **Type Safety**: Leverage Dart's strong typing to catch errors at compile time.
- **Batteries Included**: Provide sensible defaults that work out of the box for most apps.

---
Happy coding! 🚀
