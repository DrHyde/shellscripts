#!/usr/bin/env bats

setup() {
    REPO_ROOT="$BATS_TEST_DIRNAME/.."
    SCRIPT="$REPO_ROOT/highlight"
    TMP_HOME="$BATS_TEST_TMPDIR/home"

    mkdir -p "$TMP_HOME/bin/lib"
    cp "$REPO_ROOT/lib/stdbashlib" "$TMP_HOME/bin/lib/stdbashlib"
}

run_highlight() {
    local input="$1"
    shift

    run bash -c 'printf "%s" "$1" | HOME="$2" "$3" "${@:4}"' bash "$input" "$TMP_HOME" "$SCRIPT" "$@"
}

run_highlight_pipeline() {
    local input="$1"
    local first_colour="$2"
    local first_regex="$3"
    local second_colour="$4"
    local second_regex="$5"

    run bash -c 'printf "%s" "$1" | HOME="$2" "$3" "$4" "$5" | HOME="$2" "$3" "$6" "$7"' \
        bash "$input" "$TMP_HOME" "$SCRIPT" "$first_colour" "$first_regex" "$second_colour" "$second_regex"
}

@test "shows help text" {
    run env HOME="$TMP_HOME" "$SCRIPT" --help

    [ "$status" -eq 0 ]
    [[ "$output" == *"usage: highlight [--colour perl-regex] ... [perl-regex ...]"* ]]
    [[ "$output" == *"--shell-completions"* ]]
}

@test "errors when no regexes are supplied" {
    run env HOME="$TMP_HOME" "$SCRIPT"

    [ "$status" -eq 1 ]
    [[ "$output" == *"highlight: at least one regex is required"* ]]
    [[ "$output" == *"usage: highlight [--colour perl-regex] ... [perl-regex ...]"* ]]
}

@test "lists available colours from stdbashlib" {
    run env HOME="$TMP_HOME" "$SCRIPT" --list-colours

    [ "$status" -eq 0 ]
    [ "$output" = $'black_on_blue\nblack_on_green\nblack_on_orange\nblack_on_purple\nblack_on_red\nblack_on_white\nblack_on_yellow\nblue\ngreen\norange\npurple\nred\nwhite\nyellow' ]
}

@test "prints shell completions" {
    run env HOME="$TMP_HOME" "$SCRIPT" --shell-completions

    [ "$status" -eq 0 ]
    [[ "$output" == *"_highlight_completions()"* ]]
    [[ "$output" == *'complete -F _highlight_completions highlight'* ]]
}

@test "highlights matches with the default colour" {
    run_highlight $'warning and error\n' 'error'

    [ "$status" -eq 0 ]
    [ "$output" = $'warning and \e[0;30;43merror\e[0m' ]
}

@test "highlights multiple regexes with explicit colours" {
    run_highlight $'ok fail error\n' --green 'ok' --red 'fail|error'

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[1;32mok\e[0m \e[1;31mfail\e[0m \e[1;31merror\e[0m' ]
}

@test "errors when a colour option is missing its regex" {
    run env HOME="$TMP_HOME" "$SCRIPT" --green

    [ "$status" -eq 1 ]
    [[ "$output" == *"highlight: missing regex for --green"* ]]
}

@test "errors when a named colour helper does not exist" {
    run env HOME="$TMP_HOME" "$SCRIPT" --teal 'match'

    [ "$status" -eq 1 ]
    [[ "$output" == *"highlight: no helper function named teal_text"* ]]
}

@test "preserves existing colour after a later nested highlight" {
    run_highlight_pipeline $'24 25 26 27 28 29 30\n' --green '25.*29' --red '28'

    [ "$status" -eq 0 ]
    [ "$output" = $'24 \e[1;32m25 26 27 \e[1;31m28\e[0m\e[1;32m 29\e[0m 30' ]
}

@test "multiple regexes in one invocation can nest highlights" {
    run_highlight $'24 25 26 27 28 29 30\n' --green '25.*29' --red '28'

    [ "$status" -eq 0 ]
    [ "$output" = $'24 \e[1;32m25 26 27 \e[1;31m28\e[0m\e[1;32m 29\e[0m 30' ]
}

@test "matches visible text across an existing colour change" {
    run_highlight_pipeline $'24 25 26 27 28 29 30\n' --green '25.*29' --red '29.*30'

    [ "$status" -eq 0 ]
    [ "$output" = $'24 \e[1;32m25 26 27 28 \e[1;31m29 30\e[0m' ]
}

@test "preserves leading ANSI colour codes when nothing matches" {
    run_highlight $'\e[1;32mhello\e[0m\n' 'nomatch'

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[1;32mhello\e[0m' ]
}
