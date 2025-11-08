#!/bin/bash

source "$(dirname "$0")/common.sh"

LANGUAGES=(
	"fr-fr"
	# "es-es"
	# "de-de"
	# "it-it"
)

script_start=$(date +%s)

echo "🔥🔥🔥 Review English Reference"
review_language "en-us"

echo "🔥🔥🔥 Add all missing translations"
for lang in "${LANGUAGES[@]}"; do
	add_missing_translations "$lang"
done

echo "🔥🔥🔥 Update all existing translations"
for lang in "${LANGUAGES[@]}"; do
	update_existing_translations "$lang"
done

echo "🔥🔥🔥 Reviewing all translations"
for lang in "${LANGUAGES[@]}"; do
	review_language "$lang"
done

script_end=$(date +%s)
script_total=$((script_end - script_start))
echo "🎉 All done! (${script_total}s)"
