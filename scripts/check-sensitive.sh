#!/usr/bin/env sh
# Check for sensitive information in staged files

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

should_check() {
  file="$1"
  
  case "$file" in
    *.tmpl|test_*.sh|README.md|*.git/*|lefthook.yml)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

check_file() {
  file="$1"
  
  if ! [ -f "$file" ]; then
    return 0
  fi
  
  if ! should_check "$file"; then
    return 0
  fi
  
  if grep -qE 'sk-ant-[a-zA-Z0-9_-]+' "$file" 2>/dev/null; then
    printf "${RED}✗ Anthropic API key detected in: %s${NC}\n" "$file" >&2
    return 1
  fi
  
  if grep -qE 'sk-[a-zA-Z0-9]{20,}' "$file" 2>/dev/null; then
    printf "${RED}✗ API key pattern detected in: %s${NC}\n" "$file" >&2
    return 1
  fi
  
  if grep -qE 'password\s*=\s*["\x27][^"\x27]{8,}["\x27]' "$file" 2>/dev/null; then
    printf "${RED}✗ Hardcoded password detected in: %s${NC}\n" "$file" >&2
    return 1
  fi
  
  if grep -qE 'BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY' "$file" 2>/dev/null; then
    printf "${RED}✗ Private key detected in: %s${NC}\n" "$file" >&2
    return 1
  fi
  
  if grep -qE '[a-f0-9]{64}' "$file" 2>/dev/null; then
    case "$file" in
      *.md|*.txt|*.json.tmpl)
        ;;
      *)
        printf "${YELLOW}⚠ Long hex string (possible token) in: %s${NC}\n" "$file" >&2
        printf "  Review manually or skip with: git commit --no-verify\n" >&2
        return 1
        ;;
    esac
  fi
  
  return 0
}

if [ $# -eq 0 ]; then
  printf "${YELLOW}No files to check${NC}\n" >&2
  exit 0
fi

failed=0
checked=0

for file in "$@"; do
  if check_file "$file"; then
    checked=$((checked + 1))
  else
    failed=$((failed + 1))
  fi
done

if [ "$failed" -gt 0 ]; then
  printf "\n${RED}Check failed: Found %d file(s) with potential sensitive data${NC}\n" "$failed" >&2
  printf "Skip with: git commit --no-verify\n" >&2
  exit 1
fi

if [ "$checked" -gt 0 ]; then
  printf "✓ Checked %d file(s), no sensitive data detected\n" "$checked" >&2
fi

exit 0
