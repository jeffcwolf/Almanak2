# CLAUDE.md - AI Assistant Guide for Almanak2

> **Project Status**: New/Empty Repository
> **Last Updated**: 2025-11-14
> **Purpose**: This document serves as a comprehensive guide for AI assistants working on the Almanak2 codebase.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Repository Structure](#repository-structure)
3. [Development Workflows](#development-workflows)
4. [Coding Conventions](#coding-conventions)
5. [Testing Guidelines](#testing-guidelines)
6. [Git Workflow](#git-workflow)
7. [AI Assistant Guidelines](#ai-assistant-guidelines)
8. [Common Tasks](#common-tasks)

---

## Project Overview

### About Almanak2

**Current State**: This is a new repository ready for initial setup and development.

**Project Name**: Almanak2
**Repository**: jeffcwolf/Almanak2
**Type**: [To be determined - likely calendar/almanac application based on name]

### Goals

- [Define primary project goals]
- [Define target users/use cases]
- [Define key features]

---

## Repository Structure

### Recommended Initial Structure

Since this is a new repository, here's a recommended structure for AI assistants to follow when creating files:

```
Almanak2/
├── .github/                    # GitHub specific files
│   ├── workflows/              # CI/CD workflows
│   └── ISSUE_TEMPLATE/         # Issue templates
├── docs/                       # Documentation
│   ├── architecture.md         # System architecture
│   ├── api.md                  # API documentation
│   └── setup.md                # Setup instructions
├── src/                        # Source code
│   ├── components/             # Reusable components
│   ├── services/               # Business logic
│   ├── utils/                  # Utility functions
│   ├── types/                  # Type definitions
│   └── index.ts/main.py        # Entry point (depends on language)
├── tests/                      # Test files
│   ├── unit/                   # Unit tests
│   ├── integration/            # Integration tests
│   └── e2e/                    # End-to-end tests
├── config/                     # Configuration files
├── scripts/                    # Build and utility scripts
├── .gitignore                  # Git ignore patterns
├── README.md                   # Project readme
├── CLAUDE.md                   # This file
├── LICENSE                     # License file
└── package.json/requirements.txt  # Dependencies (based on stack)
```

### Current Structure

**Status**: Empty repository - structure to be established during initial setup.

---

## Development Workflows

### Initial Setup Workflow

When setting up this project for the first time:

1. **Determine Technology Stack**
   - Ask the user about preferred languages/frameworks
   - Common options: JavaScript/TypeScript (Node.js, React), Python (Django, Flask), Go, Rust

2. **Initialize Project Structure**
   - Create directory structure based on chosen stack
   - Set up package manager (npm, pip, cargo, etc.)
   - Add .gitignore for the chosen technology

3. **Configure Development Environment**
   - Set up linting tools (ESLint, Pylint, etc.)
   - Configure formatting (Prettier, Black, etc.)
   - Add pre-commit hooks if needed

4. **Create Initial Documentation**
   - README.md with project description and setup instructions
   - CONTRIBUTING.md for contribution guidelines
   - Architecture documentation

### Feature Development Workflow

1. **Planning**
   - Use TodoWrite tool to break down feature into tasks
   - Identify affected files and dependencies
   - Consider test requirements

2. **Implementation**
   - Write tests first (TDD approach when appropriate)
   - Implement feature incrementally
   - Update documentation as needed

3. **Testing**
   - Run unit tests
   - Run integration tests if applicable
   - Manual testing for UI changes

4. **Review & Commit**
   - Review changes for security issues
   - Commit with descriptive messages
   - Push to feature branch

### Bug Fix Workflow

1. **Investigate**
   - Reproduce the issue
   - Identify root cause
   - Check for similar issues elsewhere

2. **Fix**
   - Write test that reproduces the bug
   - Implement fix
   - Verify test passes

3. **Validate**
   - Run full test suite
   - Check for regressions
   - Update relevant documentation

---

## Coding Conventions

### General Principles

1. **Code Quality**
   - Write clean, readable, and maintainable code
   - Follow DRY (Don't Repeat Yourself) principle
   - Keep functions small and focused
   - Use meaningful variable and function names

2. **Comments & Documentation**
   - Comment "why", not "what"
   - Document complex algorithms
   - Keep JSDoc/docstrings for public APIs
   - Update comments when code changes

3. **Error Handling**
   - Use proper error handling (try/catch, Result types, etc.)
   - Provide meaningful error messages
   - Log errors appropriately
   - Never swallow errors silently

### Language-Specific Conventions

#### JavaScript/TypeScript
- Use TypeScript for type safety
- Follow Airbnb or Google style guide
- Use async/await over callbacks
- Prefer const over let, avoid var
- Use arrow functions for callbacks
- Proper null/undefined handling

#### Python
- Follow PEP 8 style guide
- Use type hints (Python 3.5+)
- Use list/dict comprehensions when appropriate
- Proper exception handling
- Use virtual environments

#### Other Languages
[Add conventions as stack is determined]

### File Naming

- Use kebab-case for files: `user-service.ts`
- Use PascalCase for classes: `UserService`
- Use camelCase for variables/functions: `getUserData()`
- Use UPPER_SNAKE_CASE for constants: `MAX_RETRY_COUNT`

---

## Testing Guidelines

### Test Coverage

- Aim for 80%+ code coverage
- 100% coverage for critical business logic
- All public APIs must have tests
- Integration tests for key workflows

### Test Organization

```
tests/
├── unit/                       # Fast, isolated tests
│   └── [mirrors src structure]
├── integration/                # Tests with dependencies
│   └── [feature-based]
└── e2e/                        # Full workflow tests
    └── [user-journey-based]
```

### Testing Best Practices

1. **Test Naming**: Use descriptive names that explain what is being tested
   - Good: `test_user_login_with_invalid_password_returns_error`
   - Bad: `test_login_1`

2. **Test Structure**: Follow AAA pattern
   - Arrange: Set up test data
   - Act: Execute the code under test
   - Assert: Verify the results

3. **Test Independence**: Each test should be able to run independently

4. **Mock External Dependencies**: Use mocks/stubs for external services

---

## Git Workflow

### Branch Strategy

- `main` or `master`: Production-ready code
- `develop`: Integration branch for features
- `feature/*`: Individual features
- `bugfix/*`: Bug fixes
- `hotfix/*`: Emergency production fixes
- `claude/*`: AI assistant feature branches

### Commit Message Format

Follow Conventional Commits specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Example**:
```
feat(auth): add user authentication with JWT

- Implement JWT token generation
- Add login endpoint
- Create middleware for token validation

Closes #123
```

### Working with Claude Branches

When AI assistants create branches:
- Branch format: `claude/claude-md-[session-id]`
- Always push to the specified claude branch
- Never push directly to main/master
- Create PR when work is complete

---

## AI Assistant Guidelines

### Core Principles

1. **Always Use TodoWrite Tool**
   - Break down complex tasks into steps
   - Track progress throughout implementation
   - Mark tasks as completed immediately after finishing

2. **Read Before Writing**
   - Always read files before editing
   - Understand context before making changes
   - Check for similar patterns in codebase

3. **Security First**
   - Check for OWASP Top 10 vulnerabilities
   - Validate and sanitize all inputs
   - Use parameterized queries for databases
   - Avoid storing secrets in code
   - Use environment variables for configuration

4. **Test Thoroughly**
   - Run tests after changes
   - Add new tests for new functionality
   - Fix failing tests before committing

5. **Clear Communication**
   - Explain what you're doing and why
   - Reference specific files and line numbers
   - Ask for clarification when ambiguous

### When to Ask for Clarification

Always ask the user for clarification when:
- Technology stack or framework choice is unclear
- Multiple valid approaches exist
- Requirements are ambiguous
- Security or performance implications are significant
- Breaking changes might be introduced

### File Creation Guidelines

1. **Prefer Editing Over Creating**
   - Always edit existing files when possible
   - Only create new files when absolutely necessary

2. **When Creating Files**
   - Follow the established directory structure
   - Use appropriate file naming conventions
   - Include necessary headers/imports
   - Add appropriate license headers if required

### Code Review Checklist

Before committing, verify:
- [ ] Code follows project conventions
- [ ] No security vulnerabilities introduced
- [ ] Tests pass
- [ ] No debugging code left behind
- [ ] Comments are clear and necessary
- [ ] Error handling is appropriate
- [ ] Performance implications considered
- [ ] Documentation updated if needed

### Using Task Tool

Use the Task tool with specialized agents for:
- **Explore agent**: Understanding codebase structure
- **Plan agent**: Planning complex implementations
- Use "quick", "medium", or "very thorough" based on complexity

### Parallel Tool Execution

When possible, run independent operations in parallel:
```
# Good: Parallel when independent
- Read multiple files simultaneously
- Run multiple git commands that don't depend on each other
- Search multiple patterns at once

# Bad: Parallel when dependent
- Don't read and edit the same file in parallel
- Don't commit before adding files
```

---

## Common Tasks

### Starting a New Feature

```bash
# 1. Ensure you're on the correct branch
git status

# 2. Plan the implementation
# Use TodoWrite tool to break down the feature

# 3. Create necessary files following structure
# Use Write tool for new files, Edit for existing

# 4. Implement incrementally
# Test after each meaningful change

# 5. Commit and push
git add .
git commit -m "feat(scope): description"
git push -u origin <branch-name>
```

### Fixing a Bug

```bash
# 1. Reproduce the issue
# Read relevant files and understand the problem

# 2. Write a test that demonstrates the bug
# This ensures the bug is fixed and won't regress

# 3. Fix the issue
# Make minimal changes necessary

# 4. Verify fix
# Run tests and manual verification

# 5. Commit
git commit -m "fix(scope): description of bug fix"
```

### Refactoring Code

```bash
# 1. Ensure tests exist and pass
# Run existing test suite

# 2. Make incremental changes
# Refactor in small steps

# 3. Run tests after each change
# Ensure no regressions

# 4. Commit each logical refactoring
git commit -m "refactor(scope): description"
```

### Adding Tests

```bash
# 1. Identify what needs testing
# Check coverage reports if available

# 2. Write tests following project conventions
# Use appropriate testing framework

# 3. Ensure tests pass
# Run test suite

# 4. Commit
git commit -m "test(scope): add tests for [feature]"
```

### Updating Documentation

```bash
# 1. Identify what changed
# Code changes, API changes, etc.

# 2. Update relevant documentation
# README, API docs, inline comments

# 3. Verify documentation accuracy
# Check links, code examples

# 4. Commit
git commit -m "docs(scope): update [what] documentation"
```

---

## Project-Specific Notes

### Technology Stack

**To be determined** - Update this section once the stack is chosen:

- **Frontend**: [Framework/Library]
- **Backend**: [Framework/Language]
- **Database**: [Database system]
- **Testing**: [Testing frameworks]
- **Build Tools**: [Build system]
- **Deployment**: [Deployment platform]

### Dependencies

No dependencies yet. Update package.json/requirements.txt as they're added.

### Environment Variables

Document required environment variables here as they're added:

```bash
# Example:
# API_KEY=your_api_key
# DATABASE_URL=postgresql://localhost/almanak2
# NODE_ENV=development
```

### Known Issues

- None yet (new repository)

### Future Improvements

- [ ] Set up CI/CD pipeline
- [ ] Add automated testing
- [ ] Configure linting and formatting
- [ ] Add contribution guidelines
- [ ] Set up issue templates
- [ ] Add security scanning

---

## Resources

### Documentation

- [Project README](./README.md) - To be created
- [Architecture Docs](./docs/architecture.md) - To be created
- [API Documentation](./docs/api.md) - To be created

### External Resources

- [Git Commit Conventions](https://www.conventionalcommits.org/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Semantic Versioning](https://semver.org/)

### Contact

- **Repository Owner**: jeffcwolf
- **Project Repository**: jeffcwolf/Almanak2

---

## Maintenance

### Updating This Document

This document should be updated:
- When project structure changes significantly
- When new conventions are established
- When technology stack decisions are made
- When new workflows are introduced
- Periodically to reflect current state (quarterly review recommended)

### Version History

- **2025-11-14**: Initial creation - Empty repository documentation established

---

## Quick Reference for AI Assistants

### Essential Commands

```bash
# Check current state
git status
git branch

# Create feature branch
git checkout -b feature/feature-name

# Stage and commit
git add .
git commit -m "type(scope): message"

# Push to remote
git push -u origin branch-name

# Run tests (update based on stack)
npm test / pytest / go test / cargo test
```

### Essential Tools to Use

1. **TodoWrite**: Track all multi-step tasks
2. **Read**: Always read before editing
3. **Edit**: Prefer editing over writing new files
4. **Task (Explore)**: Understand codebase structure
5. **Bash**: Run commands, but prefer specialized tools for file operations

### Red Flags to Avoid

- ❌ Never commit secrets or API keys
- ❌ Never push to main/master directly
- ❌ Never skip tests if they exist
- ❌ Never ignore security vulnerabilities
- ❌ Never create files unnecessarily
- ❌ Never use bash commands when specialized tools exist
- ❌ Never push to wrong branch
- ❌ Never leave debugging code in commits

### Green Lights to Follow

- ✅ Always use TodoWrite for complex tasks
- ✅ Always read files before editing
- ✅ Always run tests before committing
- ✅ Always use descriptive commit messages
- ✅ Always check for security issues
- ✅ Always ask when uncertain
- ✅ Always reference files with line numbers
- ✅ Always push to claude branches

---

*This document is maintained for AI assistants working on the Almanak2 project. Keep it updated as the project evolves.*
