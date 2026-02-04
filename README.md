# Catalyst Dev Setup

A reusable setup script that installs git hooks, Jest testing, and npm scripts for any Zoho Catalyst serverless project.

## Quick Start

```bash
# Clone this repo anywhere you like (one-time setup)
git clone https://github.com/hector1799/catalyst-dev-setup.git ~/catalyst-dev-setup

# Navigate to any Catalyst project
cd /path/to/your/catalyst-project

# Run the setup script
~/catalyst-dev-setup/setup.sh
```

That's it! The script handles everything automatically.

**Note:** You can clone `catalyst-dev-setup` to any location. The script uses relative paths and will work regardless of where it's installed or where your Catalyst projects live.

## What Gets Installed

### For Each Function

| Item | Description |
|------|-------------|
| **Jest** | Testing framework (v29.7.0) |
| **`__tests__/`** | Test directory with placeholder test |
| **npm scripts** | `test`, `test:watch`, `test:coverage`, `deploy` |

### Git Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| **pre-commit** | Before each commit | Runs `npm test` in all functions. Blocks commit if tests fail. |
| **post-commit** | After each commit | Runs `catalyst deploy` to deploy to Development. |

## NPM Scripts

After setup, each function has these scripts:

```bash
cd functions/<function-name>

npm test              # Run all tests
npm run test:watch    # Run tests in watch mode (re-runs on file changes)
npm run test:coverage # Run tests with coverage report
npm run deploy        # Run tests, then deploy if they pass
```

## Deployment Workflow

| Environment | How to Deploy | When |
|-------------|---------------|------|
| **Development** | Automatic (post-commit hook) | Every git commit |
| **Production** | Manual via [Zoho Catalyst Console](https://console.zoho.com/) | After testing in dev |

### Production Deployment Steps

1. Test your changes in the Development environment
2. Go to [Zoho Catalyst Console](https://console.zoho.com/)
3. Select your project
4. Deploy/promote to Production environment

## Writing Tests

Replace the placeholder test with real tests for your functions.

### Example Test File

```javascript
// functions/MyFunction/__tests__/helpers.test.js

// Import the function to test
const { buildLineItem, formatDate } = require('../index.js');

describe('buildLineItem', () => {
  test('creates a line item with all fields', () => {
    const result = buildLineItem('Service', 100, 2);
    expect(result).toEqual({
      name: 'Service',
      rate: 100,
      quantity: 2
    });
  });

  test('handles missing quantity', () => {
    const result = buildLineItem('Service', 100);
    expect(result.quantity).toBe(1);
  });
});

describe('formatDate', () => {
  test('formats date correctly', () => {
    const date = new Date('2024-01-15');
    expect(formatDate(date)).toBe('01/15/2024');
  });
});
```

### Testing Tips

- Test helper functions, not the entire handler
- Export functions you want to test from `index.js`
- Use `describe` blocks to group related tests
- Keep tests focused on one behavior each

## Project Structure After Setup

```
YourCatalystProject/
├── .git/
│   └── hooks/
│       ├── pre-commit     ← Runs tests before commit
│       └── post-commit    ← Deploys after commit
├── catalyst.json
└── functions/
    └── YourFunction/
        ├── index.js
        ├── package.json   ← Updated with Jest config
        └── __tests__/
            └── placeholder.test.js
```

## Troubleshooting

### Tests fail and block my commit

Fix the failing tests first! That's the point of the pre-commit hook. Run `npm test` in the function directory to see the errors:

```bash
cd functions/<function-name>
npm test
```

### I need to commit without running tests (emergency)

Use `--no-verify` to skip hooks (use sparingly!):

```bash
git commit -m "Emergency fix" --no-verify
```

### Deployment fails in post-commit

The commit still goes through. Check the error output and run `catalyst deploy` manually to retry.

### Script says "not a Catalyst project"

Make sure you're in the project root (where `catalyst.json` or `functions/` is located).

## Updating the Setup

If templates are updated, re-run the script on your project. It will:
- Update git hooks with latest versions
- Skip functions that already have tests
- Not overwrite existing test files

## Files in This Directory

```
catalyst-dev-setup/
├── setup.sh              # Main setup script
├── templates/
│   ├── pre-commit        # Git hook template
│   ├── post-commit       # Git hook template
│   └── basic.test.js     # Placeholder test template
└── README.md             # This file
```
