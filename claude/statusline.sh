#!/bin/bash

# Read JSON input from stdin once, extract all fields in a single jq call
# (bash 3.2 on macOS has no mapfile/readarray, so join on a separator + `read`)
input=$(cat)
SEP=$'\x1e'
IFS="$SEP" read -r cwd model output_style context_remaining context_size \
    agent_name total_cost_usd total_input total_output duration_ms <<<"$(
    jq -j --arg sep "$SEP" '
        [
            .workspace.current_dir,
            .model.display_name,
            (.output_style.name // ""),
            (.context_window.remaining_percentage // ""),
            (.context_window.context_window_size // ""),
            (.agent.name // ""),
            (.cost.total_cost_usd // ""),
            (.context_window.total_input_tokens // 0),
            (.context_window.total_output_tokens // 0),
            (.cost.total_duration_ms // 0)
        ] | map(tostring) | join($sep)
    ' <<<"$input"
)"

# OS icon (matches oh-my-posh config: WSL = 🐧)
# os_icon="🐧"

# Username
# username="$(whoami)"

# Aura theme colors (using 256-color codes for compatibility)
BLUE=$'\033[38;5;68m'    # Soft blue
CYAN=$'\033[38;5;75m'    # Cyan
YELLOW=$'\033[38;5;221m' # Warm yellow
GRAY=$'\033[38;5;59m'    # Dark gray
WHITE=$'\033[38;5;254m'  # White
RED=$'\033[38;5;203m'    # Soft red
GREEN=$'\033[38;5;114m'  # Soft green
RESET=$'\033[0m'

# Shorten path to last 2 directory segments (home dir shown as ~; "..." marks pruned depth)
if [ "$cwd" = "$HOME" ]; then
    full_path="~"
else
    full_path=$(echo "$cwd" | awk -F/ '{depth=NF-1; if (depth>2) print ".../"$(NF-1)"/"$NF; else print $0}')
fi

# Get git info for right-aligned block
git_right=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    # --show-current exits 0 with empty output on detached HEAD, so test the value not the status
    git_branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    [ -z "$git_branch" ] && git_branch="detached@$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)"

    # Staged and unstaged file counts
    staged=$(git -C "$cwd" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    unstaged=$(git -C "$cwd" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    # Insertions/deletions across the whole working tree (staged + unstaged) vs HEAD,
    # so the counters match what the dirty marker implies.
    diff_stat=$(git -C "$cwd" diff HEAD --shortstat 2>/dev/null)
    # BSD sed compatible (no grep -P on macOS)
    ins=$(sed -n 's/.*[^0-9]\([0-9][0-9]*\) insertion.*/\1/p' <<<"$diff_stat")
    del=$(sed -n 's/.*[^0-9]\([0-9][0-9]*\) deletion.*/\1/p' <<<"$diff_stat")

    diff_info=""
    [ -n "$ins" ] && diff_info="${GREEN}+${ins}${RESET}"
    [ -n "$del" ] && diff_info="${diff_info:+$diff_info }${RED}-${del}${RESET}"

    status_icon=""
    [ "$staged" -gt 0 ] 2>/dev/null && status_icon="${YELLOW}●${RESET} "
    [ "$unstaged" -gt 0 ] 2>/dev/null && status_icon="${status_icon}${RED}✎${RESET} "

    # Ahead/behind upstream (silently skipped when no upstream is configured)
    track_info=""
    if ab=$(git -C "$cwd" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null); then
        behind=$(awk '{print $1}' <<<"$ab")
        ahead=$(awk '{print $2}' <<<"$ab")
        [ "${ahead:-0}" -gt 0 ] 2>/dev/null && track_info="${GREEN}↑${ahead}${RESET}"
        [ "${behind:-0}" -gt 0 ] 2>/dev/null && track_info="${track_info:+$track_info}${YELLOW}↓${behind}${RESET}"
    fi

    git_right="${status_icon}${CYAN}${git_branch}${RESET}"
    [ -n "$track_info" ] && git_right="$git_right $track_info"
    [ "${untracked:-0}" -gt 0 ] 2>/dev/null && git_right="$git_right ${GRAY}?${untracked}${RESET}"
    [ -n "$diff_info" ] && git_right="$git_right $diff_info"
fi

# Docker context (only show if docker is available and the daemon is actually reachable)
docker_info=""
if command -v docker >/dev/null 2>&1; then
    docker_context=$(docker context show 2>/dev/null)
    if [ -n "$docker_context" ] && [ "$docker_context" != "default" ]; then
        docker_endpoint=$(docker context inspect "$docker_context" --format '{{.Endpoints.docker.Host}}' 2>/dev/null)
        docker_socket="${docker_endpoint#unix://}"
        if [ -S "$docker_socket" ] && docker info >/dev/null 2>&1; then
            docker_info="docker:$docker_context "
        fi
    fi
fi

# Kubernetes (only if K8S_ACTIVE is set, matching oh-my-posh config)
k8s_info=""
if [ -n "$K8S_ACTIVE" ] && command -v kubectl >/dev/null 2>&1; then
    k8s_context=$(kubectl config current-context 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$k8s_context" ]; then
        k8s_namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
        k8s_info="󱃾 $k8s_context"
        if [ -n "$k8s_namespace" ]; then
            k8s_info="$k8s_info:$k8s_namespace "
        else
            k8s_info="$k8s_info "
        fi
    fi
fi

# Build status line with Aura colors
output="${WHITE}${full_path}${RESET} "

# Add k8s info with blue color
if [ -n "$k8s_info" ]; then
    output="$output${BLUE}${k8s_info}${RESET}"
fi

# Add Docker context
if [ -n "$docker_info" ]; then
    output="$output$docker_info"
fi

# Add Claude Code specific info with separator
# Abbreviate model name
model_short="${model#Claude }"

# Handle AWS Bedrock ARNs
if [[ "$model_short" =~ application-inference-profile/([a-z0-9]+) ]]; then
    # Extract just the profile ID from the ARN
    model_short="bedrock:${BASH_REMATCH[1]:0:8}"
# Handle LiteLLM aliases, e.g. "opus (bedrock)[1m]" -> "Opus [1m]"
elif [[ "$model_short" =~ ^(opus|sonnet|haiku)[[:space:]]*\(bedrock\)(.*)$ ]]; then
    tier="${BASH_REMATCH[1]}"
    suffix="${BASH_REMATCH[2]}"
    model_short="${tier:0:1}"
    model_short="$(tr '[:lower:]' '[:upper:]' <<<"$model_short")${tier:1}"
    [ -n "$suffix" ] && model_short="$model_short $suffix"
# Handle explicit LiteLLM model ids, e.g. "claude-sonnet-5 (claude-on-aws)[1m]" -> "Sonnet 5 [1m]"
elif [[ "$model_short" =~ ^claude-(opus|sonnet|haiku)-([0-9]+(-[0-9]+)*)[[:space:]]*"("[^\)]*")"(.*)$ ]]; then
    tier="${BASH_REMATCH[1]}"
    version="${BASH_REMATCH[2]//-/.}"
    suffix="${BASH_REMATCH[4]}"
    model_short="${tier:0:1}"
    model_short="$(tr '[:lower:]' '[:upper:]' <<<"$model_short")${tier:1} $version"
    [ -n "$suffix" ] && model_short="$model_short $suffix"
# Handle standard Claude model names
elif [[ "$model_short" =~ ^Opus[[:space:]]+([0-9.]+) ]]; then
    model_short="Opus ${BASH_REMATCH[1]} "
elif [[ "$model_short" =~ ^Sonnet[[:space:]]+([0-9.]+) ]]; then
    model_short="Sonnet ${BASH_REMATCH[1]}"
elif [[ "$model_short" =~ ^Haiku[[:space:]]+([0-9.]+) ]]; then
    model_short="Haiku ${BASH_REMATCH[1]} "

fi
output="$output${GRAY}|${RESET} ${BLUE}${model_short}${RESET}"

# Token usage with visual progress bar
if [ -n "$context_remaining" ] && [ -n "$context_size" ] && [ "$context_size" != "null" ]; then
    used_k=$(awk "BEGIN {printf \"%.0f\", $context_size * (1 - $context_remaining/100) / 1000}")
    total_k=$(awk "BEGIN {printf \"%.0f\", $context_size/1000}")
    # Choose bar color based on remaining percentage
    if awk "BEGIN {exit !($context_remaining > 50)}"; then
        bar_color="$GREEN"
    elif awk "BEGIN {exit !($context_remaining >= 20)}"; then
        bar_color="$YELLOW"
    else
        bar_color="$RED"
    fi
    # Build 10-char block bar (filled = used, empty = remaining); guard filled/empty=0 (BSD seq needs >=1 args)
    filled=$(awk "BEGIN {printf \"%d\", int((1 - $context_remaining/100) * 10 + 0.5)}")
    empty=$((10 - filled))
    bar=""
    [ "$filled" -gt 0 ] && bar=$(printf '▓%.0s' $(seq 1 "$filled"))
    [ "$empty" -gt 0 ] && bar="${bar}$(printf '░%.0s' $(seq 1 "$empty"))"
    output="$output ${bar_color}${bar}${RESET} ${bar_color}${used_k}k/${total_k}k${RESET} "
fi

# Output style (just the name, no "style:" prefix)
if [ -n "$output_style" ] && [ "$output_style" != "default" ]; then
    output="$output${GRAY}${output_style}${RESET} "
fi

# Agent mode (just the name, no "agent:" prefix)
if [ -n "$agent_name" ]; then
    output="$output${GRAY}${agent_name}${RESET} "
fi

# ── Cost ──────────────────────────────────────────────
# Prefer the harness-reported cost; only estimate when it is absent.
# Fallback rates (USD per Mtok in/out) are picked from the model tier so the
# estimate isn't ~5x off when running Opus.
cost_str=""
if [ -n "$total_cost_usd" ] && [ "$total_cost_usd" != "null" ]; then
    cost_str=$(printf "\$%.4f" "$total_cost_usd")
elif [ "$total_input" -gt 0 ] || [ "$total_output" -gt 0 ]; then
    case "$(tr '[:upper:]' '[:lower:]' <<<"$model_short")" in
        *opus*)  rate_in=15.00; rate_out=75.00 ;;
        *haiku*) rate_in=1.00;  rate_out=5.00  ;;
        *)       rate_in=3.00;  rate_out=15.00 ;;  # sonnet / unknown
    esac
    total_cost=$(echo "scale=6; ($total_input * $rate_in + $total_output * $rate_out) / 1000000" | bc -l 2>/dev/null || echo "0")
    cost_str=$(printf "\$%.4f" "$total_cost")
fi

# ── Duration ──────────────────────────────────────────
duration_str=""
if [ "$duration_ms" -gt 0 ]; then
    duration=$((duration_ms / 1000))
    hours=$((duration / 3600))
    minutes=$(( (duration % 3600) / 60 ))
    seconds=$((duration % 60))
    if [ $hours -gt 0 ]; then
        duration_str=$(printf "%dh%02dm%02ds" $hours $minutes $seconds)
    elif [ $minutes -gt 0 ]; then
        duration_str=$(printf "%dm%02ds" $minutes $seconds)
    else
        duration_str=$(printf "%ds" $seconds)
    fi
fi

# Append cost + duration to right-side extras
if [ -n "$cost_str" ] || [ -n "$duration_str" ]; then
    extras=""
    [ -n "$cost_str" ]     && extras="${CYAN}${cost_str}${RESET}"
    [ -n "$duration_str" ] && extras="${extras} ${GRAY}${duration_str}${RESET}"
    git_right="${git_right:+${git_right} ${GRAY}|${RESET} }${extras}"
fi

# Right-align git info if in a git repo
if [ -n "$git_right" ]; then
    # Strip ANSI codes to measure visible lengths.
    # wc -m (chars) not -c (bytes): the bar/status glyphs are 3-byte UTF-8, which
    # would otherwise overcount the width by ~2 cols each and wrap the line.
    visible_left=$(echo -e "$output" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\n' | wc -m)
    visible_right=$(echo -e "$git_right" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\n' | wc -m)
    term_width=$(tput cols 2>/dev/null || echo 120)
    padding=$((term_width - visible_left - visible_right - 1))
    [ $padding -lt 1 ] && padding=1
    printf -v spaces '%*s' "$padding" ''
    output="$output$spaces$git_right"
fi

echo "$output"
