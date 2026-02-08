#!/usr/bin/env bash
# Test: Devcontainer Structure - Feature 0005

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() { echo -e "${GREEN}PASS${NC} $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
fail() { echo -e "${RED}FAIL${NC} $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEVCONTAINER_DIR="$PROJECT_ROOT/.devcontainer"

echo "Testing Devcontainer Structure..."
echo

# Test .devcontainer exists
TESTS_RUN=$((TESTS_RUN + 1))
if [[ -d "$DEVCONTAINER_DIR" ]]; then
    pass ".devcontainer directory exists"
else
    fail ".devcontainer directory missing"
fi

# Test platform directories
for platform in ubuntu debian arch generic; do
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -d "$DEVCONTAINER_DIR/$platform" ]]; then
        pass "$platform directory exists"
    else
        fail "$platform directory missing"
    fi
done

# Test required files
for platform in ubuntu debian arch generic; do
    for file in Dockerfile devcontainer.json README.md BOM.md .dockerignore; do
        TESTS_RUN=$((TESTS_RUN + 1))
        if [[ -f "$DEVCONTAINER_DIR/$platform/$file" ]]; then
            pass "$platform/$file exists"
        else
            fail "$platform/$file missing"
        fi
    done
done

# Test Dockerfiles not empty
for platform in ubuntu debian arch generic; do
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -s "$DEVCONTAINER_DIR/$platform/Dockerfile" ]]; then
        pass "$platform/Dockerfile not empty"
    else
        fail "$platform/Dockerfile empty"
    fi
done

# Test JSON validity
for platform in ubuntu debian arch generic; do
    TESTS_RUN=$((TESTS_RUN + 1))
    if jq empty "$DEVCONTAINER_DIR/$platform/devcontainer.json" 2>/dev/null; then
        pass "$platform/devcontainer.json valid JSON"
    else
        fail "$platform/devcontainer.json invalid JSON"
    fi
done

# Test .dockerignore content
for platform in ubuntu debian arch generic; do
    TESTS_RUN=$((TESTS_RUN + 1))
    if grep -q ".ssh/" "$DEVCONTAINER_DIR/$platform/.dockerignore"; then
        pass "$platform/.dockerignore excludes .ssh/"
    else
        fail "$platform/.dockerignore missing .ssh/"
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    if grep -q ".env" "$DEVCONTAINER_DIR/$platform/.dockerignore"; then
        pass "$platform/.dockerignore excludes .env"
    else
        fail "$platform/.dockerignore missing .env"
    fi
done

echo
echo "================================"
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    exit 1
fi
echo "All tests passed!"
exit 0
