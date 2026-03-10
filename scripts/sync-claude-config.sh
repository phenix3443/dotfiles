#!/usr/bin/env bash
# Sync local Claude configuration to chezmoi repository
# Intelligently preserves template placeholders ({{ ... }})

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$REPO_ROOT/dotfiles/dot_claude"

detect_claude_config_path() {
  case "$(uname -s)" in
    Darwin|Linux)
      echo "$HOME/.claude"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "$HOME/.claude"
      ;;
    *)
      echo "Unsupported OS: $(uname -s)" >&2
      exit 1
      ;;
  esac
}

CLAUDE_CONFIG="$(detect_claude_config_path)"

if [ ! -d "$CLAUDE_CONFIG" ]; then
  echo "Error: Claude config directory not found: $CLAUDE_CONFIG" >&2
  exit 1
fi

echo "Claude config path: $CLAUDE_CONFIG"
echo "Repository template path: $TEMPLATE_DIR"
echo ""

sync_settings_json() {
  local local_file="$CLAUDE_CONFIG/settings.json"
  local template_file="$TEMPLATE_DIR/settings.json.tmpl"
  
  if [ ! -f "$local_file" ]; then
    echo "Warning: Local settings.json not found: $local_file"
    return 1
  fi
  
  if [ ! -f "$template_file" ]; then
    echo "Warning: Template file not found: $template_file"
    return 1
  fi
  
  echo "Processing settings.json..."
  
  local backup_file="${template_file}.backup"
  cp "$template_file" "$backup_file"
  echo "  Backup created: ${backup_file##*/}"
  
  if grep -q '{{.*}}' "$template_file"; then
    echo "  Template placeholders detected in original file"
    
    local temp_merged="/tmp/claude-sync-$$.json"
    local temp_placeholders="/tmp/claude-placeholders-$$.txt"
    local temp_script="/tmp/claude-sync-$$.js"
    
    grep '{{' "$template_file" > "$temp_placeholders" || true
    
    cat > "$temp_script" <<'NODEJS'
const fs = require('fs');

function stripJsonComments(str) {
  return str.replace(/\\"|"(?:\\"|[^"])*"|(\/\/.*|\/\*[\s\S]*?\*\/)/g, (m, g) => g ? "" : m);
}

function removeTrailingCommas(str) {
  return str.replace(/,(\s*[}\]])/g, '$1');
}

function extractPlaceholders(content) {
  const placeholders = {};
  
  try {
    const cleanedContent = stripJsonComments(content);
    const cleanedWithoutCommas = removeTrailingCommas(cleanedContent);
    const templateData = JSON.parse(cleanedWithoutCommas);
    
    function findPlaceholders(obj, placeholders) {
      if (typeof obj === 'object' && obj !== null && !Array.isArray(obj)) {
        for (const key in obj) {
          const value = obj[key];
          if (typeof value === 'string' && value.includes('{{') && value.includes('}}')) {
            placeholders[key] = value;
          } else if (typeof value === 'object') {
            findPlaceholders(value, placeholders);
          }
        }
      } else if (Array.isArray(obj)) {
        for (const item of obj) {
          if (typeof item === 'object') {
            findPlaceholders(item, placeholders);
          }
        }
      }
    }
    
    findPlaceholders(templateData, placeholders);
  } catch (error) {
    console.error('Warning: Could not parse template file, using line-by-line extraction');
    
    const lines = content.split('\n');
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || !trimmed.includes('{{')) continue;
      
      const match = trimmed.match(/"([^"]+)":\s*(.+),?$/);
      if (match) {
        const key = match[1];
        let value = match[2].replace(/,$/, '').trim();
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.slice(1, -1);
        }
        if (value.includes('{{') && value.includes('}}')) {
          placeholders[key] = value;
        }
      }
    }
  }
  
  return placeholders;
}

try {
  const localFile = process.argv[2];
  const placeholdersFile = process.argv[3];
  const outputFile = process.argv[4];
  
  let localContent = fs.readFileSync(localFile, 'utf8');
  localContent = stripJsonComments(localContent);
  localContent = removeTrailingCommas(localContent);
  const localData = JSON.parse(localContent);
  
  const templateContent = fs.readFileSync(placeholdersFile, 'utf8');
  const placeholders = extractPlaceholders(templateContent);
  
  const PLACEHOLDER_PREFIX = '__CHEZMOI_PLACEHOLDER_';
  const placeholderMap = {};
  let placeholderIndex = 0;
  
  function restorePlaceholders(data, placeholders) {
    if (typeof data === 'object' && data !== null && !Array.isArray(data)) {
      for (const key in data) {
        if (placeholders[key]) {
          const marker = PLACEHOLDER_PREFIX + placeholderIndex + '__';
          placeholderMap[marker] = placeholders[key];
          data[key] = marker;
          placeholderIndex++;
        } else if (typeof data[key] === 'object') {
          restorePlaceholders(data[key], placeholders);
        }
      }
    } else if (Array.isArray(data)) {
      for (let i = 0; i < data.length; i++) {
        if (typeof data[i] === 'object') {
          restorePlaceholders(data[i], placeholders);
        }
      }
    }
    return data;
  }
  
  const mergedData = restorePlaceholders(localData, placeholders);
  
  let output = JSON.stringify(mergedData, null, 2);
  
  for (const marker in placeholderMap) {
    output = output.replace(`"${marker}"`, `"${placeholderMap[marker]}"`);
  }
  
  fs.writeFileSync(outputFile, output + '\n', 'utf8');
  
  console.log(`  Smart merge completed (preserved ${Object.keys(placeholders).length} template placeholders)`);
} catch (error) {
  console.error(`  Error during merge: ${error.message}`);
  console.error(error.stack);
  process.exit(1);
}
NODEJS
    
    node "$temp_script" "$local_file" "$temp_placeholders" "$temp_merged"
    local exit_code=$?
    
    rm -f "$temp_placeholders" "$temp_script"
    
    if [ $exit_code -eq 0 ] && [ -f "$temp_merged" ]; then
      mv "$temp_merged" "$template_file"
      echo "  Template updated with smart merge"
    else
      echo "  Error: Smart merge failed, restoring backup" >&2
      mv "$backup_file" "$template_file"
      return 1
    fi
  else
    echo "  No template placeholders found, direct copy"
    cp "$local_file" "$template_file"
    echo "  Template updated with direct copy"
  fi
  
  return 0
}

sync_skills_manifest() {
  local local_file="$CLAUDE_CONFIG/skills_manifest.txt"
  local template_file="$TEMPLATE_DIR/skills_manifest.txt"
  
  if [ ! -f "$local_file" ]; then
    echo "Warning: Local skills_manifest.txt not found: $local_file"
    return 1
  fi
  
  if [ ! -f "$template_file" ]; then
    echo "Warning: Template file not found: $template_file"
    return 1
  fi
  
  echo "Processing skills_manifest.txt..."
  
  local backup_file="${template_file}.backup"
  cp "$template_file" "$backup_file"
  echo "  Backup created: ${backup_file##*/}"
  
  cp "$local_file" "$template_file"
  echo "  File synced (direct copy)"
  
  return 0
}

echo "=== Syncing Claude Configuration ==="
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

if sync_settings_json; then
  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""

if sync_skills_manifest; then
  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""
echo "=== Sync Summary ==="
echo "Success: $SUCCESS_COUNT file(s)"
echo "Failed: $FAIL_COUNT file(s)"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
  echo "Next steps:"
  echo "  1. Review changes: cd $REPO_ROOT && git diff dotfiles/dot_claude/"
  echo "  2. Test templates: chezmoi diff"
  echo "  3. Commit changes: git add dotfiles/dot_claude/ && git commit -m 'sync: update Claude configuration'"
  exit 0
else
  echo "Some files failed to sync. Please check the errors above."
  exit 1
fi
