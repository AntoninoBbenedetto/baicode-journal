#!/usr/bin/env bash
set -euo pipefail

content_dir="${1:-content}"
now_epoch=$(date -u +%s)
failed=0

while IFS= read -r -d '' file; do
  delimiter_count=0
  frontmatter=""

  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      delimiter_count=$((delimiter_count + 1))
      if [[ $delimiter_count -eq 2 ]]; then
        break
      fi
      continue
    fi
    if [[ $delimiter_count -eq 1 ]]; then
      frontmatter+="$line"$'\n'
    fi
  done < "$file"

  if echo "$frontmatter" | grep -qE '^draft:[[:space:]]*true[[:space:]]*$'; then
    echo "FAIL: $file has draft: true"
    failed=1
  fi

  date_line=$(echo "$frontmatter" | grep -E '^date:' || true)
  if [[ -n "$date_line" ]]; then
    date_value=$(printf '%s\n' "$date_line" | sed -E "s/^date:[[:space:]]*//; s/^['\"]//; s/['\"][[:space:]]*\$//")
    date_epoch=$(date -u -d "$date_value" +%s 2>/dev/null || echo "")
    if [[ -n "$date_epoch" && "$date_epoch" -gt "$now_epoch" ]]; then
      echo "FAIL: $file has future date ($date_value)"
      failed=1
    fi
  fi
done < <(find "$content_dir" -name '*.md' -print0)

if [[ "$failed" -eq 1 ]]; then
  echo "Guardrail check failed: draft or future-dated content found under $content_dir"
  exit 1
fi

echo "Guardrail check passed: no draft or future-dated content under $content_dir"
