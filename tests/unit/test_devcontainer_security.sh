#!/usr/bin/env bash
# Test: Devcontainer Security - Feature 0005

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() { echo -e "${GREEN}PASS${NC} $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
fail() { echo -e "${RED}FAIL${NC} $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
warn() { echo -e "${YELLOW}WARN${NC} $1"; }

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEVCONTAINER_DIR="$PROJECT_ROOT/.devcontainer"

echo "Testing Devcontainer Security Requirements..."
echo

echo "=== req_0027: Secrets Management (CRITICAL) ==="
for platform in ubuntu debian arch generic; do
    dockerfile="$DEVCONTAINER_DIR/$platform/Dockerfile"
    jsonfile="$DEVCONTAINER_DIR/$platform/devcontainer.json"
    dockerignore="$DEVCONTAINER_DIR/$platform/.dockerignore"
    
    # No SSH keys in Dockerfile
    TESTS_RUN=$((TESTS_RUN + 1))
    if ! grep -qi "COPY.*\.ssh\|ADD.*\.ssh\|id_rsa\|id_ed25519\|id_ecdsa" "$dockerfile"; then
        pass "$platform: No SSH keys in Dockerfile"
    else
        fail "$platform: SSH keys found in Dockerfile (req_0027)"
    fi
    
    # No secrets in ENV
    TESTS_RUN=$((TESTS_RUN + 1))
    if ! grep -qi "ENV.*PASSWORD\|ENV.*TOKEN\|ENV.*KEY.*=" "$dockerfile"; then
        pass "$platform: No secrets in ENV variables"
    else
        fail "$platform: Secrets found in ENV (req_0027)"
    fi
    
    # .dockerignore excludes SSH
    TESTS_RUN=$((TESTS_RUN + 1))
    if grep -q "\.ssh/" "$dockerignore" && grep -q "\*\.key" "$dockerignore"; then
        pass "$platform: .dockerignore excludes SSH keys"
    else
        fail "$platform: .dockerignore missing SSH exclusions (req_0027)"
    fi
    
    # .dockerignore excludes .env
    TESTS_RUN=$((TESTS_RUN + 1))
    if grep -q "\.env" "$dockerignore"; then
        pass "$platform: .dockerignore excludes .env files"
    else
        fail "$platform: .dockerignore missing .env exclusions (req_0027)"
    fi
    
    # SSH agent forwarding
    TESTS_RUN=$((TESTS_RUN + 1))
    if grep -q "SSH_AUTH_SOCK" "$jsonfile"; then
        pass "$platform: SSH agent forwarding configured"
    else
        warn "$platform: SSH agent forwarding not found"
    fi
done

echo
echo "=== req_0028: Base Image Verification (HIGH) ==="
for platform in ubuntu debian arch generic; do
    dockerfile="$DEVCONTAINER_DIR/$platform/Dockerfile"
    
    # SHA256 pinned
    TESTS_RUN=$((TESTS_RUN + 1))
    if grep -q "FROM.*@sha256:" "$dockerfile"; then
        pass "$platform: Base image pinned with SHA256"
    else
        fail "$platform: Base image not SHA256 pinned (req_0028)"
    fi
    
    # Official image
    TESTS_RUN=$((TESTS_RUN + 1))
    case $platform in
        ubuntu) expected="ubuntu:" ;;
        debian) expected="debian:" ;;
        arch) expected="archlinux:" ;;
        generic) expected="alpine:" ;;
    esac
    if grep -q "FROM ${expected}" "$dockerfile"; then
        pass "$platform: Uses expected official base image"
    else
        fail "$platform: Unexpected base image (req_0028)"
    fi
done

echo
echo "=== req_0029: Package Integrity (HIGH) ==="
for platform in ubuntu debian arch generic; do
    dockerfile="$DEVCONTAINER_DIR/$platform/Dockerfile"
    
    # No third-party repos
    TESTS_RUN=$((TESTS_RUN + 1))
    if ! grep -qi "add-apt-repository\|ppa:" "$dockerfile"; then
        pass "$platform: No third-party repositories"
    else
        fail "$platform: Third-party repos detected (req_0029)"
    fi
    
    # Uses package manager
    TESTS_RUN=$((TESTS_RUN + 1))
    case $platform in
        ubuntu|debian)
            if grep -q "apt-get install" "$dockerfile"; then
                pass "$platform: Uses apt package manager"
            else
                fail "$platform: Package manager not found"
            fi
            ;;
        arch)
            if grep -q "pacman -S" "$dockerfile"; then
                pass "$platform: Uses pacman package manager"
            else
                fail "$platform: Package manager not found"
            fi
            ;;
        generic)
            if grep -q "apk add" "$dockerfile"; then
                pass "$platform: Uses apk package manager"
            else
                fail "$platform: Package manager not found"
            fi
            ;;
    esac
done

echo
echo "=== req_0030: Privilege Restriction (HIGH) ==="
for platform in ubuntu debian arch generic; do
    dockerfile="$DEVCONTAINER_DIR/$platform/Dockerfile"
    jsonfile="$DEVCONTAINER_DIR/$platform/devcontainer.json"
    
    # USER directive present
    TESTS_RUN=$((TESTS_RUN + 1))
    if grep -q "^USER " "$dockerfile"; then
        pass "$platform: USER directive present in Dockerfile"
    else
        fail "$platform: No USER directive (runs as root) (req_0030)"
    fi
    
    # Non-root user
    TESTS_RUN=$((TESTS_RUN + 1))
    if grep -q "USER devuser\|USER \$USERNAME" "$dockerfile" && ! grep -q "USER root" "$dockerfile"; then
        pass "$platform: Runs as non-root user"
    else
        fail "$platform: Runs as root user (req_0030)"
    fi
    
    # remoteUser set
    TESTS_RUN=$((TESTS_RUN + 1))
    if grep -q '"remoteUser".*"devuser"' "$jsonfile"; then
        pass "$platform: remoteUser set to devuser"
    else
        fail "$platform: remoteUser not set (req_0030)"
    fi
    
    # Capabilities dropped
    TESTS_RUN=$((TESTS_RUN + 1))
    if grep -q "\-\-cap-drop=ALL" "$jsonfile"; then
        pass "$platform: Capabilities dropped (--cap-drop=ALL)"
    else
        fail "$platform: Capabilities not dropped (req_0030)"
    fi
    
    # No privileged mode
    TESTS_RUN=$((TESTS_RUN + 1))
    if ! grep -qi "privileged.*true\|--privileged" "$jsonfile"; then
        pass "$platform: No privileged mode"
    else
        fail "$platform: Privileged mode detected (req_0030)"
    fi
    
    # no-new-privileges
    TESTS_RUN=$((TESTS_RUN + 1))
    if grep -q "no-new-privileges" "$jsonfile"; then
        pass "$platform: no-new-privileges security option set"
    else
        warn "$platform: no-new-privileges not found"
    fi
done

echo
echo "=== req_0031: Build Security (MEDIUM) ==="
for platform in ubuntu debian arch generic; do
    dockerfile="$DEVCONTAINER_DIR/$platform/Dockerfile"
    dockerignore="$DEVCONTAINER_DIR/$platform/.dockerignore"
    
    # .dockerignore exists
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -f "$dockerignore" ]] && [[ -s "$dockerignore" ]]; then
        pass "$platform: .dockerignore exists and not empty"
    else
        fail "$platform: .dockerignore missing or empty (req_0031)"
    fi
    
    # .dockerignore comprehensive
    TESTS_RUN=$((TESTS_RUN + 1))
    patterns=(".ssh" ".gnupg" ".env" "*.key" "*.pem" "secrets")
    found=0
    for pattern in "${patterns[@]}"; do
        if grep -q "$pattern" "$dockerignore"; then
            found=$((found + 1))
        fi
    done
    if [[ $found -ge 5 ]]; then
        pass "$platform: .dockerignore has comprehensive exclusions"
    else
        fail "$platform: .dockerignore incomplete ($found/6 patterns) (req_0031)"
    fi
done

# Summary
echo
echo "================================"
echo "Security Test Summary:"
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    echo
    echo "SECURITY REQUIREMENTS NOT MET - DO NOT DEPLOY"
    exit 1
else
    echo
    echo "All security requirements verified"
    exit 0
fi
