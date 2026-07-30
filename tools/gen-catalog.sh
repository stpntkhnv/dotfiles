#!/usr/bin/env bash
# Генирует docs/catalog.md и проверяет, что документация покрывает
# каждую фичу каталога и каждый файл репозитория.
#
# Частью `chezmoi apply` НЕ является: это инструмент репозитория, а не машины.
# Запускается руками или агентом по правилу из CLAUDE.md.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

CHECK_ONLY=0
case "${1:-}" in
  --check) CHECK_ONLY=1 ;;
  "")      CHECK_ONLY=0 ;;
  *)       printf 'использование: %s [--check]\n' "${0##*/}" >&2; exit 2 ;;
esac

for tool in chezmoi jq git awk; do
  command -v "$tool" >/dev/null 2>&1 || { printf 'нет инструмента: %s\n' "$tool" >&2; exit 2; }
done

# Файлы, которые обязаны быть покрыты: всё под home/ плюс установщик.
covered_universe() { git ls-files home/ install.sh; }

# Документы с шапкой: только верхний уровень docs/.
#
# find, а не `git ls-files 'docs/*.md'`, по двум причинам. Во-первых, в git
# pathspec звёздочка пересекает слэш, поэтому этот шаблон захватывает ещё и
# docs/issues/**, у которых шапки нет и быть не должно. Во-вторых, find видит
# неотслеживаемые файлы, а значит фикстуры из тестов Task 1 работают без плясок
# с индексом.
#
# catalog.md исключён: он генерируется и шапки не носит.
# features.md исключён: он живёт до задачи 27 и шапки не носит.
doc_files() {
  find docs -maxdepth 1 -name '*.md' \
    ! -name 'catalog.md' \
    ! -name 'features.md' \
    -print | sort
}

# Разбор шапки. Печатает "<документ>\tfeature\t<ключ>", "<документ>\tpath\t<шаблон>"
# или ровно одну строку "<документ>\tHEADER-ERROR\t<причина>".
parse_header() {
  awk -v doc="$1" '
    FNR == 1 {
      if ($0 != "---") {
        printf "%s\tHEADER-ERROR\tнет frontmatter в первой строке\n", doc
        bailed = 1
        exit
      }
      next
    }
    $0 == "---" { closed = 1; exit }
    /^[[:space:]]*$/ { next }
    $0 == "covers:" { seen_covers = 1; next }
    /^  features: *\[/ {
      line = $0
      sub(/^  features: *\[/, "", line)
      sub(/\].*$/, "", line)
      gsub(/[[:space:]]/, "", line)
      if (line != "") {
        n = split(line, a, ",")
        for (i = 1; i <= n; i++) printf "%s\tfeature\t%s\n", doc, a[i]
      }
      next
    }
    /^  paths: *\[\][[:space:]]*$/ { sect = ""; next }
    /^  paths:[[:space:]]*$/ { sect = "paths"; next }
    sect == "paths" && /^    - / {
      p = $0; sub(/^    - /, "", p)
      printf "%s\tpath\t%s\n", doc, p
      next
    }
    {
      printf "%s\tHEADER-ERROR\tнеожиданная строка в шапке: %s\n", doc, $0
      bailed = 1
      exit
    }
    END {
      # bailed означает, что сообщение об ошибке уже напечатано выше.
      # awk выполняет END и после exit, поэтому без этой проверки одна
      # сломанная шапка давала бы две строки HEADER-ERROR.
      if (bailed) exit
      if (!seen_covers)  printf "%s\tHEADER-ERROR\tнет ключа covers\n", doc
      else if (!closed)  printf "%s\tHEADER-ERROR\tшапка не закрыта\n", doc
    }
  ' "$1"
}

headers() {
  local doc
  while IFS= read -r doc; do
    [[ -n "$doc" ]] || continue
    parse_header "$doc"
  done < <(doc_files)
}

# Битые внутренние ссылки. awk, а не grep: grep возвращает 1 на документе без
# ссылок, и под `set -euo pipefail` это убило бы весь скрипт.
broken_links() {
  local doc target dir
  while IFS= read -r doc; do
    [[ -n "$doc" ]] || continue
    dir="$(dirname "$doc")"
    while IFS= read -r target; do
      [[ -n "$target" ]] || continue
      case "$target" in
        http://*|https://*|mailto:*|'#'*) continue ;;
      esac
      target="${target%%#*}"
      [[ -n "$target" ]] || continue
      [[ -e "$dir/$target" ]] || printf 'BROKEN-LINK\t%s\t%s\n' "$doc" "$target"
    done < <(awk '
      {
        line = $0
        while (match(line, /\]\([^)]*\)/)) {
          t = substr(line, RSTART + 2, RLENGTH - 3)
          print t
          line = substr(line, RSTART + RLENGTH)
        }
      }
    ' "$doc")
  done < <(doc_files)
}

HEADERS="$(headers)"
FEATURES="$(chezmoi --source . execute-template '{{ .features | toJson }}')"

CATALOG_KEYS="$(printf '%s' "$FEATURES" | jq -r '.[].key')"
HEADER_FEATURES="$(printf '%s\n' "$HEADERS" | awk -F'\t' '$2 == "feature" { print $3 }')"
HEADER_PATHS="$(printf '%s\n' "$HEADERS" | awk -F'\t' '$2 == "path" { print $3 }')"

REPORT="$(mktemp)"
MATCHED="$(mktemp)"
trap 'rm -f "$REPORT" "$MATCHED"' EXIT

# --- 0: шапки разобрались ---
printf '%s\n' "$HEADERS" | awk -F'\t' '$2 == "HEADER-ERROR" { printf "HEADER-ERROR\t%s\t%s\n", $1, $3 }' >> "$REPORT"

# --- 1: фича без документа ---
while IFS= read -r key; do
  [[ -n "$key" ]] || continue
  printf '%s\n' "$HEADER_FEATURES" | grep -qxF "$key" || printf 'UNCOVERED-FEATURE\t%s\n' "$key" >> "$REPORT"
done <<< "$CATALOG_KEYS"

# --- 2: фича у двух документов ---
while IFS= read -r key; do
  [[ -n "$key" ]] || continue
  owners="$(printf '%s\n' "$HEADERS" | awk -F'\t' -v k="$key" '$2 == "feature" && $3 == k { print $1 }' | paste -sd, -)"
  [[ "$owners" == *,* ]] && printf 'DOUBLE-FEATURE\t%s\t%s\n' "$key" "$owners" >> "$REPORT"
done <<< "$(printf '%s\n' "$HEADER_FEATURES" | sort -u)"

# --- 3: ключ, которого нет в каталоге ---
while IFS=$'\t' read -r doc kind key; do
  [[ "$kind" == "feature" ]] || continue
  printf '%s\n' "$CATALOG_KEYS" | grep -qxF "$key" || printf 'UNKNOWN-FEATURE\t%s\t%s\n' "$key" "$doc" >> "$REPORT"
done <<< "$HEADERS"

# --- 4: шаблон, не совпавший ни с одним файлом ---
while IFS=$'\t' read -r doc kind pattern; do
  [[ "$kind" == "path" ]] || continue
  if [[ -z "$(git ls-files -- "$pattern")" ]]; then
    printf 'EMPTY-PATTERN\t%s\t%s\n' "$pattern" "$doc" >> "$REPORT"
  fi
done <<< "$HEADERS"

# --- 5: файл, не попавший ни в один шаблон ---
: > "$MATCHED"
while IFS= read -r pattern; do
  [[ -n "$pattern" ]] || continue
  git ls-files -- "$pattern" >> "$MATCHED" || true
done <<< "$HEADER_PATHS"
sort -u -o "$MATCHED" "$MATCHED"

while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  grep -qxF "$file" "$MATCHED" || printf 'UNCOVERED-FILE\t%s\n' "$file" >> "$REPORT"
done <<< "$(covered_universe)"

# --- 6: битая внутренняя ссылка ---
broken_links >> "$REPORT"

cat "$REPORT"

FAIL=0
[[ -s "$REPORT" ]] && FAIL=1

{
  printf '\n'
  printf 'фич без документа:    %s\n'  "$(grep -c '^UNCOVERED-FEATURE' "$REPORT" || true)"
  printf 'файлов без документа: %s\n'  "$(grep -c '^UNCOVERED-FILE' "$REPORT" || true)"
  printf 'прочих замечаний:     %s\n'  "$(grep -cvE '^(UNCOVERED-FEATURE|UNCOVERED-FILE)' "$REPORT" || true)"
} >&2

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  exit "$FAIL"
fi

# --- генерация docs/catalog.md ---
{
  printf '# Каталог фич\n\n'
  printf '<!-- ФАЙЛ ГЕНЕРИРУЕТСЯ. Правки руками будут стёрты.\n'
  printf '     Источник: home/.chezmoidata.yaml и шапки covers в docs/*.md\n'
  printf '     Пересобрать: tools/gen-catalog.sh -->\n\n'
  printf 'Все %s фич каталога. Столбец «Документ» ведёт в подробное описание.\n\n' "$(printf '%s\n' "$CATALOG_KEYS" | wc -l)"
  printf '| Фича | Что это | Где | Как включается | Пакетов | Документ |\n'
  printf '|---|---|---|---|---|---|\n'
  printf '%s' "$FEATURES" | jq -r '
    .[] |
    [ .key,
      .label,
      .scope,
      (if .always then "всегда" elif .default then "галочка стоит" else "по выбору" end),
      ([(.pacman // []), (.aur // []), (.npm // []), (.dotnet // [])] | add | length | tostring)
    ] | @tsv' | while IFS=$'\t' read -r key label scope how pkgs; do
      doc="$(printf '%s\n' "$HEADERS" | awk -F'\t' -v k="$key" '$2 == "feature" && $3 == k { print $1; exit }')"
      if [[ -n "$doc" ]]; then
        link="[${doc#docs/}](${doc#docs/})"
      else
        link="—"
      fi
      printf '| `%s` | %s | %s | %s | %s | %s |\n' "$key" "$label" "$scope" "$how" "$pkgs" "$link"
    done
  printf '\nПакеты посчитаны из всех источников фичи: pacman, AUR, npm, dotnet tool.\n'
} > docs/catalog.md

exit "$FAIL"
