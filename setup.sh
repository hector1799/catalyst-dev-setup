#!/bin/bash
# ============================================================================
# Catalyst Dev Setup Script
# ============================================================================
# Installs git hooks (pre-commit, post-commit) and Jest testing for
# Zoho Catalyst serverless projects.
#
# Usage: Run from the root of a Catalyst project
#   /path/to/catalyst-dev-setup/setup.sh
#
# What it does:
#   1. Validates you're in a Catalyst project
#   2. Adds Jest and test scripts to each function's package.json
#   3. Creates __tests__/ directory with placeholder test
#   4. Installs npm dependencies
#   5. Installs git hooks for automated testing and deployment
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
  echo ""
  echo -e "${BLUE}============================================================================${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}============================================================================${NC}"
  echo ""
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

# ============================================================================
# Validation
# ============================================================================

print_header "Catalyst Dev Setup"

echo "Validating Catalyst project..."

# Check if we're in a Catalyst project
if [ ! -f "catalyst.json" ] && [ ! -d "functions" ]; then
  print_error "This doesn't look like a Catalyst project."
  echo "    Missing catalyst.json and functions/ directory."
  echo "    Please run this script from a Catalyst project root."
  exit 1
fi

# Find the git directory (could be at project root or function level)
GIT_DIR=""
GIT_LEVEL="project"  # or "function"
if [ -d ".git" ]; then
  GIT_DIR="$(pwd)/.git"
  GIT_LEVEL="project"
  print_success "Found git repository at project root"
elif [ -d "functions" ]; then
  # Check if git is at function level (some projects have this structure)
  for dir in functions/*/; do
    if [ -d "$dir/.git" ]; then
      GIT_DIR="$(cd "$dir" && pwd)/.git"
      GIT_LEVEL="function"
      print_warning "Git repository found at function level: $dir"
      print_info "Hooks will be installed for this function only"
      break
    fi
  done
fi

if [ -z "$GIT_DIR" ]; then
  print_error "No git repository found."
  echo "    Initialize git first with: git init"
  exit 1
fi

# Check if functions directory exists
if [ ! -d "functions" ]; then
  print_error "No functions/ directory found."
  exit 1
fi

print_success "Valid Catalyst project detected"

# ============================================================================
# Setup Functions
# ============================================================================

print_header "Setting Up Functions"

FUNCTIONS_COUNT=0
FUNCTIONS_SETUP=0

for func_dir in functions/*/; do
  if [ ! -d "$func_dir" ]; then
    continue
  fi

  FUNC_NAME=$(basename "$func_dir")
  FUNCTIONS_COUNT=$((FUNCTIONS_COUNT + 1))

  echo ""
  echo "----------------------------------------"
  echo "Function: $FUNC_NAME"
  echo "----------------------------------------"

  # Check for package.json
  if [ ! -f "$func_dir/package.json" ]; then
    print_warning "No package.json found, skipping"
    continue
  fi

  # Update package.json with Jest config
  echo "  Updating package.json..."

  # Use node to safely modify package.json
  node -e "
    const fs = require('fs');
    const path = '$func_dir/package.json';
    const pkg = JSON.parse(fs.readFileSync(path, 'utf8'));

    // Add scripts
    pkg.scripts = pkg.scripts || {};
    pkg.scripts.test = 'jest';
    pkg.scripts['test:watch'] = 'jest --watch';
    pkg.scripts['test:coverage'] = 'jest --coverage';
    pkg.scripts.deploy = 'npm test && catalyst deploy';

    // Add devDependencies
    pkg.devDependencies = pkg.devDependencies || {};
    pkg.devDependencies.jest = '^29.7.0';

    // Add Jest config
    pkg.jest = {
      testEnvironment: 'node',
      testMatch: ['**/__tests__/**/*.test.js'],
      verbose: true
    };

    fs.writeFileSync(path, JSON.stringify(pkg, null, 2) + '\n');
    console.log('  ✅ package.json updated');
  "

  # Create __tests__ directory if it doesn't exist
  if [ ! -d "$func_dir/__tests__" ]; then
    mkdir -p "$func_dir/__tests__"
    print_success "__tests__/ directory created"
  else
    print_info "__tests__/ directory already exists"
  fi

  # Add placeholder test if no tests exist
  TEST_COUNT=$(find "$func_dir/__tests__" -name "*.test.js" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$TEST_COUNT" -eq 0 ]; then
    cp "$TEMPLATES_DIR/basic.test.js" "$func_dir/__tests__/placeholder.test.js"
    print_success "Placeholder test added"
  else
    print_info "Tests already exist ($TEST_COUNT test file(s))"
  fi

  # Install dependencies
  echo "  Installing dependencies..."
  (cd "$func_dir" && npm install --silent)
  print_success "Dependencies installed"

  FUNCTIONS_SETUP=$((FUNCTIONS_SETUP + 1))
done

echo ""
print_success "Set up $FUNCTIONS_SETUP of $FUNCTIONS_COUNT function(s)"

# ============================================================================
# Install Git Hooks
# ============================================================================

print_header "Installing Git Hooks"

HOOKS_DIR="$GIT_DIR/hooks"

# For function-level git, create modified hooks that work from that directory
if [ "$GIT_LEVEL" = "function" ]; then
  echo "Creating hooks for function-level git..."

  # Create pre-commit hook for function-level git
  cat > "$HOOKS_DIR/pre-commit" << 'HOOK_EOF'
#!/bin/bash
# Pre-commit hook: Run tests before allowing commit
# Installed by catalyst-dev-setup (function-level git)

echo "🧪 Running tests before commit..."
echo ""

# We're in the function directory (where .git is)
if [ -f "package.json" ]; then
  npm test --silent
  if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Commit blocked."
    exit 1
  fi
  echo "✅ Tests passed. Proceeding with commit."
else
  echo "⚠️  No package.json found, skipping tests."
fi
exit 0
HOOK_EOF

  # Create post-commit hook for function-level git
  cat > "$HOOKS_DIR/post-commit" << 'HOOK_EOF'
#!/bin/bash
# Post-commit hook: Deploy to Zoho Catalyst after successful commit
# Installed by catalyst-dev-setup (function-level git)

echo ""
echo "🚀 Deploying to Zoho Catalyst (Development)..."
echo ""

# Navigate to project root (two levels up from function)
cd ../..

catalyst deploy

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Deployment to Development complete!"
else
  echo ""
  echo "⚠️  Deployment failed. Check the errors above."
  echo "    You can manually deploy with: catalyst deploy"
fi
HOOK_EOF

else
  # Project-level git: use the standard templates
  echo "Installing hooks for project-level git..."
  cp "$TEMPLATES_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
  cp "$TEMPLATES_DIR/post-commit" "$HOOKS_DIR/post-commit"
fi

chmod +x "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/post-commit"
print_success "pre-commit hook installed"
print_success "post-commit hook installed"

# ============================================================================
# Create CLAUDE.md (if not exists)
# ============================================================================

print_header "Project Documentation"

if [ -f "CLAUDE.md" ]; then
  print_info "CLAUDE.md already exists, skipping"
else
  # Get project name from directory
  PROJECT_NAME=$(basename "$(pwd)")

  # Get first function name for template
  FIRST_FUNC=""
  for dir in functions/*/; do
    if [ -d "$dir" ]; then
      FIRST_FUNC=$(basename "$dir")
      break
    fi
  done

  # Copy template and replace placeholders
  cp "$TEMPLATES_DIR/CLAUDE.md" "CLAUDE.md"

  # Replace placeholders with actual values
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed requires empty string for -i
    sed -i '' "s/PROJECT_NAME/$PROJECT_NAME/g" "CLAUDE.md"
    sed -i '' "s/FUNCTION_NAME/${FIRST_FUNC:-YourFunction}/g" "CLAUDE.md"
  else
    # Linux sed
    sed -i "s/PROJECT_NAME/$PROJECT_NAME/g" "CLAUDE.md"
    sed -i "s/FUNCTION_NAME/${FIRST_FUNC:-YourFunction}/g" "CLAUDE.md"
  fi

  print_success "CLAUDE.md template created"
  print_info "Edit CLAUDE.md to add project-specific details"
fi

# ============================================================================
# Summary
# ============================================================================

print_header "Setup Complete!"

echo "What was installed:"
echo "  • Jest testing framework in each function"
echo "  • npm scripts: test, test:watch, test:coverage, deploy"
echo "  • Git pre-commit hook (runs tests before each commit)"
echo "  • Git post-commit hook (deploys to Catalyst after commit)"
echo "  • CLAUDE.md template (if not already present)"
echo ""
echo "Next steps:"
echo "  1. Edit CLAUDE.md with project-specific details"
echo "  2. Replace placeholder tests with real tests"
echo "  3. Run tests manually: cd functions/<name> && npm test"
echo "  4. Commit changes - tests run automatically!"
echo ""
echo "Deployment workflow:"
echo "  • Development: Automatic on every commit (post-commit hook)"
echo "  • Production: Manual via Zoho Catalyst Console"
echo ""
print_success "Happy coding!"
