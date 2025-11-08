#!/bin/bash

run_timed() {
	local message="$1"
	local command="$2"

	echo "⌛️ $message"

	local start_time
	start_time=$(date +%s)

	eval "$command" 2>&1
	local exit_code=$?

	local end_time
	end_time=$(date +%s)
	local elapsed=$((end_time - start_time))

	local status_emoji
	status_emoji=$([[ $exit_code -eq 0 ]] && echo "✅" || echo "❌[ERROR]")
	echo "$status_emoji $message ${elapsed}s"

	[[ $exit_code -eq 0 ]] || exit 1
}

check_quality() {
	SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	cd "$SCRIPT_PATH" || exit

	echo ""
	echo "🔥🔥🔥 LET'S CHECK THAT QUALITY"
	TOTAL_START_TIME=$(date +%s)

	run_timed "Clean output directories" "rm -rf output dist"

	run_timed "Install brew dependencies" "brew bundle --quiet"

	run_timed "Npm install" "npm install 2>&1"

	run_timed "Format shell scripts" "find . -name '*.sh' -type f -exec shfmt -l -w {} +"

	run_timed "Lint shell scripts" "find . -name '*.sh' -type f -exec shellcheck --severity=warning {} +"

	run_timed "Prettier" "npm run format 2>&1"

	run_timed "Markdownlint" "npm run lint:md 2>&1"

	run_timed "TypeScript" "npm run typecheck 2>&1"

	run_timed "ESLint" "npm run lint 2>&1"

	run_timed "Check unused images" "npm run check:images 2>&1"

	run_timed "Build" "npm run build 2>&1"

	fuser -k 4321/tcp 2>/dev/null || true

	npm run preview >/dev/null 2>&1 &
	PREVIEW_PID=$!

	run_timed "Playwright Install Browsers" "npx playwright install chromium 2>&1"

	run_timed "Playwright Tests" "npm run test 2>&1"

	kill $PREVIEW_PID 2>/dev/null || true

	TOTAL_END_TIME=$(date +%s)
	TOTAL_ELAPSED=$((TOTAL_END_TIME - TOTAL_START_TIME))

	printf "✅✅✅ QUALITY PASSED (%ds)\n" "$TOTAL_ELAPSED"
}

# Run a Claude prompt in a loop until it returns [NO-FIX-NEEDED]
run_claude_until_no_changes() {
	local message="$1"
	local prompt="$2"
	local start_time
	start_time=$(date +%s)

	while true; do
		printf "⌛ %s\n" "$message"
		local step_start
		step_start=$(date +%s)
		output=$(claude --permission-mode acceptEdits --model Haiku --print "$prompt" 2>&1)
		local step_end
		step_end=$(date +%s)
		local step_seconds=$((step_end - step_start))
		local total_seconds=$((step_end - start_time))

		if echo "$output" | grep -q "\[NO-FIX-NEEDED\]"; then
			echo "✅️ No changes needed for '${message}' (${step_seconds}s)"
			echo "✅️✅️✅️ Moving on! (total ${total_seconds}s)"
			return 0
		else
			echo "⚠️ Changes made during '${message}' (${step_seconds}s)"
			echo "Will check quality, then do '${message}' again until no changes are needed."
			run_and_fix_quality_until_pass
		fi
	done
}

# Review content for a specific language
review_language() {
	local lang="$1"
	run_claude_until_no_changes "Review $lang content" "\
        For each $lang *.md in ./src/content/chapters/ and ./src/content/documents/, call one subagent ('Haiku' model): \
        \
        <subagent-instructions> \
        Fix ONLY objective errors in <file-to-review-path/>: spelling, grammar, broken markdown. \
        NO rephrasing, synonym changes, punctuation tweaks, or subjective improvements. \
        If ANY doubt about whether it's an error or how to fix it, do NOT change it. \
        If no errors, answer [NO-FIX-NEEDED]. If errors, fix and answer [FIXED]. \
        </subagent-instructions> \
        \
        If the subagents did ANY change, answer [FIXED]. \
        Else, if the subagents did NOT do ANY change, answer [NO-FIX-NEEDED]. \
        "
}

# Add missing translations for a specific language from English reference
add_missing_translations() {
	local lang="$1"
	run_claude_until_no_changes "Add missing $lang translations" "\
        Check all English *.md in ./src/content/chapters/en-us and ./src/content/documents/en-us have $lang counterparts. \
        For each missing $lang file, call one subagent ('Haiku' model): \
        \
        <subagent-instructions> \
        Translate <english-file/> to $lang at <target-path/>. Keep exact markdown structure. \
        DO NOT edit existing files. Answer [FIXED]. \
        </subagent-instructions> \
        \
        If any subagents were called, answer [FIXED]. \
        Else, answer [NO-FIX-NEEDED]. \
        "
}

# Update existing translations to match English reference
update_existing_translations() {
	local lang="$1"
	run_claude_until_no_changes "Update existing $lang translations" "\
        For each existing $lang *.md in ./src/content/chapters/ and ./src/content/documents/, call one subagent ('Haiku' model): \
        \
        <subagent-instructions> \
        Compare <translation-file/> with <english-reference/>. Update translation ONLY if: \
        - Missing sections/headings from English \
        - Different markdown structure (heading levels, list format) \
        - Clearly outdated content (version numbers, references) \
        If structure matches and content reasonably covers English topics, answer [NO-FIX-NEEDED]. \
        Otherwise update and answer [FIXED]. DO NOT rephrase or improve style. \
        </subagent-instructions> \
        \
        If the subagents did ANY change, answer [FIXED]. \
        Else, answer [NO-FIX-NEEDED]. \
        "
}

# Run quality checks and fix issues until all checks pass
run_and_fix_quality_until_pass() {
	echo "⌛ Checking quality"
	while true; do
		quality_output=$(check_quality 2>&1)
		if [ $? -eq 0 ]; then
			echo "✅️ Quality checks passed!"
			return 0
		else
			echo "$quality_output"
			echo "⚠️ Quality failed, fixing with claude"
			claude --permission-mode acceptEdits --tools Bash --print "\
                Fix all the errors reported below in the output of check_quality below \
                Focus on the reported issues and do NOT make any other changes. \
                Once done, check that it passes by running ./run_quality.sh \
                Persevere until all issues are fixed. \
                Ultrathink. \
                Once done, answer with a concise bullet list of the changes made. \
                <run-quality-output>\
                $quality_output \
                </run-quality-output>\
                "
		fi
	done
}
