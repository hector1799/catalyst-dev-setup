# CLAUDE.md

## Project Overview

**PROJECT_NAME** is a Zoho Catalyst serverless application that [DESCRIBE WHAT IT DOES].

## Tech Stack

- **Runtime**: Node.js 20
- **Platform**: Zoho Catalyst (serverless)
- **Dependencies**: `zcatalyst-sdk-node`, `axios`
- **APIs**: [LIST ZOHO/EXTERNAL APIS USED]

## Project Structure

```
PROJECT_NAME/
├── .catalystrc                    # Catalyst project config
├── catalyst.json                  # Function deployment targets
└── functions/
    └── FUNCTION_NAME/
        ├── index.js               # Main function code
        ├── catalyst-config.json   # Function deployment config
        ├── package.json           # Dependencies and scripts
        └── __tests__/             # Jest unit tests
```

## How It Works

1. [DESCRIBE TRIGGER - event, HTTP, cron, etc.]
2. [DESCRIBE MAIN LOGIC]
3. [DESCRIBE OUTPUT/RESULT]

## Development Commands

```bash
# Install dependencies
cd functions/FUNCTION_NAME
npm install

# Run tests
npm test                  # Run all tests
npm run test:watch        # Run tests in watch mode
npm run test:coverage     # Run tests with coverage report

# Deploy (runs tests first, then deploys)
npm run deploy
```

## Git Hooks (Automated Quality Gates)

The project uses git hooks to enforce code quality:

- **pre-commit**: Runs `npm test` before every commit. If tests fail, the commit is blocked.
- **post-commit**: Runs `catalyst deploy` after every successful commit.

This ensures:
1. All committed code passes tests
2. Development environment is always in sync with the latest commit

## Deployment Environments

| Environment | How to Deploy | When |
|-------------|---------------|------|
| Development | Automatic (post-commit hook) | Every commit |
| Production | Manual via [Zoho Catalyst Console](https://console.zoho.com/) | After testing in dev |

## Code Conventions

- `"use strict"` mode enabled
- Modular structure with clear section comments
- Try-catch error handling with email notifications
- Error emails sent to `error@legalbillreview.zohodesk.com`

## External Integrations

- **Zoho CRM**: [DESCRIBE USAGE]
- **Zoho Books**: [DESCRIBE USAGE IF APPLICABLE]
- **Zoho Desk**: Error notification routing

## Important Notes

- [ADD PROJECT-SPECIFIC NOTES, GOTCHAS, OR CONSTRAINTS]
