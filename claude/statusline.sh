#!/bin/bash

# Read JSON input from stdin once, extract all fields
input=$(cat)
cwd=$(jq -r '.workspace.current_dir' <<<"$input")
model=$(jq -r '.model.display_name' <<<"$input")
output_style=$(jq -r '.output_style.name // empty' <<<"$input")
context_remaining=$(jq -r '.context_window.remaining_percentage // empty' <<<"$input")
context_size=$(jq -r '.context_window.context_window_size // empty' <<<"$input")
agent_name=$(jq -r '.agent.name // empty' <<<"$input")
total_cost_usd=$(jq -r '.cost.total_cost_usd // empty' <<<"$input")
total_input=$(jq -r '.context_window.total_input_tokens // 0' <<<"$input")
total_output=$(jq -r '.context_window.total_output_tokens // 0' <<<"$input")
duration_ms=$(jq -r '.cost.total_duration_ms // 0' <<<"$input")

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

# Shorten path (~, not /home/user)
full_path="${cwd/#$HOME/\~}"

# Get git info for right-aligned block
git_right=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    git_branch=$(git -C "$cwd" branch --show-current 2>/dev/null || echo "detached")

    # Staged and unstaged counts
    staged=$(git -C "$cwd" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    unstaged=$(git -C "$cwd" diff --numstat 2>/dev/null | wc -l | tr -d ' ')

    # Diff insertions/deletions summary (staged changes)
    diff_stat=$(git -C "$cwd" diff --cached --shortstat 2>/dev/null)
    ins=$(echo "$diff_stat" | grep -oP '\d+(?= insertion)' || echo "")
    del=$(echo "$diff_stat" | grep -oP '\d+(?= deletion)' || echo "")

    diff_info=""
    [ -n "$ins" ] && diff_info="${GREEN}+${ins}${RESET}"
    [ -n "$del" ] && diff_info="$diff_info ${RED}-${del}${RESET}"

    status_icon=""
    [ "$staged" -gt 0 ] 2>/dev/null && status_icon="${YELLOW}●${RESET} "
    [ "$unstaged" -gt 0 ] 2>/dev/null && status_icon="${status_icon}${RED}✎${RESET} "

    git_right="${status_icon}${CYAN}${git_branch}${RESET}"
    [ -n "$diff_info" ] && git_right="$git_right $diff_info"
fi

# Docker context (only show if docker is available and working)
docker_info=""
if command -v docker >/dev/null 2>&1; then
    docker_context=$(docker context show 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$docker_context" ] && [ "$docker_context" != "default" ]; then
        docker_info="docker:$docker_context "
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
# Handle standard Claude model names
elif [[ "$model_short" =~ ^Opus[[:space:]]+([0-9.]+) ]]; then
    model_short="Opus ${BASH_REMATCH[1]} "
elif [[ "$model_short" =~ ^Sonnet[[:space:]]+([0-9.]+) ]]; then
    model_short="Sonnet ${BASH_REMATCH[1] }"
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
    # Build 10-char block bar (filled = used, empty = remaining)
    filled=$(awk "BEGIN {printf \"%d\", int((1 - $context_remaining/100) * 10 + 0.5)}")
    empty=$((10 - filled))
    bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}▓"; done
    for ((i=0; i<empty; i++)); do bar="${bar}░"; done
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
cost_str=""
if [ -n "$total_cost_usd" ] && [ "$total_cost_usd" != "null" ]; then
    cost_str=$(printf "\$%.4f" "$total_cost_usd")
elif [ "$total_input" -gt 0 ] || [ "$total_output" -gt 0 ]; then
    total_cost=$(echo "scale=6; ($total_input * 3.00 + $total_output * 15.00) / 1000000" | bc -l 2>/dev/null || echo "0")
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
    # Strip ANSI codes to measure visible lengths
    visible_left=$(echo -e "$output" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\n' | wc -c)
    visible_right=$(echo -e "$git_right" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\n' | wc -c)
    term_width=$(tput cols 2>/dev/null || echo 120)
    padding=$((term_width - visible_left - visible_right - 1))
    [ $padding -lt 1 ] && padding=1
    printf -v spaces '%*s' "$padding" ''
    output="$output$spaces$git_right"
fi

echo "$output"
