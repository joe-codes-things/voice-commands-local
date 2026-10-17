#!/bin/bash

read_project_version() {
    local project_root="$1"
    local version
    local project_spec="$project_root/VoiceCommandsLocal/project.yml"

    if [ ! -r "$project_spec" ]; then
        echo "ERROR: XcodeGen project specification not found or unreadable: $project_spec" >&2
        return 1
    fi

    version="$(awk '
        /^[[:space:]]*MARKETING_VERSION:[[:space:]]*/ {
            if (found++) {
                exit 1
            }
            sub(/^[[:space:]]*MARKETING_VERSION:[[:space:]]*/, "", $0)
            gsub(/^[[:space:]"]+|[[:space:]"]+$/, "", $0)
            print
        }
        END {
            if (found != 1) {
                exit 1
            }
        }
    ' "$project_spec")" || {
        echo "ERROR: Expected exactly one MARKETING_VERSION in $project_spec" >&2
        return 1
    }

    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "ERROR: Invalid MARKETING_VERSION in $project_spec: $version" >&2
        return 1
    fi

    printf 'v%s\n' "$version"
}

validate_release_version() {
    if [[ ! "$1" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "ERROR: Version must use vMAJOR.MINOR.PATCH format, received: $1" >&2
        return 1
    fi
}

run_xcodebuild() {
    local -a pipeline_status
    local pipefail_was_set=false

    if [[ -o pipefail ]]; then
        pipefail_was_set=true
    fi
    set -o pipefail
    if xcodebuild "$@" 2>&1 | grep -E '(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)'; then
        pipeline_status=("${PIPESTATUS[@]}")
    else
        pipeline_status=("${PIPESTATUS[@]}")
    fi

    if [[ "$pipefail_was_set" != true ]]; then
        set +o pipefail
    fi

    if (( pipeline_status[0] != 0 )); then
        echo "ERROR: xcodebuild failed with exit status ${pipeline_status[0]}" >&2
        return "${pipeline_status[0]}"
    fi

    if (( pipeline_status[1] > 1 )); then
        echo "ERROR: Failed to filter xcodebuild output" >&2
        return "${pipeline_status[1]}"
    fi

    return 0
}
