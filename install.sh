#!/bin/bash
#######################################################################
# Script Name  : install.sh
# Description  : Interactive bootstrap for a fresh macOS machine.
#                Installs Xcode CLT, Homebrew, selected package groups,
#                Python CLI tools, shell plugins, and dotfiles.
# Author       : Oliver Fletcher
# Email        : engineering@oliverfletcher.io
#
# Usage:
#   ./install.sh                     interactive group picker
#   ./install.sh --yes               non-interactive, default groups
#   ./install.sh --only core,apps    only these groups
#   ./install.sh --skip aws,fonts    everything default except these
#   ./install.sh --dry-run           show what would happen, change nothing
#   ./install.sh --list              list the groups and exit
#
# Safe to re-run: every step checks before acting.
#######################################################################
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREW_DIR="$REPO_DIR/brew"
DOTFILES_DIR="$REPO_DIR/dotfiles"
LOG_FILE="${TMPDIR:-/tmp}/terminal-setup-$(date +%Y%m%d-%H%M%S).log"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
STATE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/terminal-setup.XXXXXX")"
trap 'rm -rf "$STATE_DIR"' EXIT

ASSUME_YES=0
DRY_RUN=0
ONLY=""
SKIP=""

#----------------------------------------------------------------------
# Presentation
#----------------------------------------------------------------------
if [ -t 1 ] && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    BOLD="$(tput bold)"; DIM="$(tput dim)"; RESET="$(tput sgr0)"
    RED="$(tput setaf 1)"; GREEN="$(tput setaf 2)"; YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"; CYAN="$(tput setaf 6)"
else
    BOLD=""; DIM=""; RESET=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""
fi
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    *[Uu][Tt][Ff]*) UNICODE=1 ;;
    *) UNICODE=0 ;;
esac
if [ "$UNICODE" -eq 1 ]; then
    TICK="${GREEN}\xe2\x9c\x94${RESET}"; CROSS="${RED}\xe2\x9c\x98${RESET}"
    BAR_FULL_CH=$'\xe2\x96\x88'; BAR_EMPTY_CH=$'\xe2\x96\x91'
    ON_CH=$'\xe2\x97\x89'; OFF_CH=$'\xe2\x97\xaf'; PTR_CH=$'\xe2\x9d\xaf'
    SPIN_FRAMES=($'\xe2\xa0\x8b' $'\xe2\xa0\x99' $'\xe2\xa0\xb9' $'\xe2\xa0\xb8' $'\xe2\xa0\xbc' \
                 $'\xe2\xa0\xb4' $'\xe2\xa0\xa6' $'\xe2\xa0\xa7' $'\xe2\xa0\x87' $'\xe2\xa0\x8f')
else
    TICK="${GREEN}OK${RESET}"; CROSS="${RED}XX${RESET}"
    BAR_FULL_CH="#"; BAR_EMPTY_CH="-"
    ON_CH="x"; OFF_CH=" "; PTR_CH=">"
    SPIN_FRAMES=(- \\ "|" /)
fi
TICK="$(printf "$TICK")"; CROSS="$(printf "$CROSS")"

STEP_NO=0
STEP_TOTAL=0
FAILURES=()
INSTALLED_COUNT=0
SKIPPED_COUNT=0

banner() {
    local rule
    if [ "$UNICODE" -eq 1 ]; then rule=$'\xe2\x94\x80'; else rule="-"; fi
    local line="" j=0
    while [ "$j" -lt 52 ]; do line="$line$rule"; j=$(( j + 1 )); done
    printf '\n%s%s%s\n' "$CYAN" "$line" "$RESET"
    printf '  %sterminal-setup%s  macOS bootstrap\n' "$BOLD" "$RESET"
    printf '%s%s%s\n' "$CYAN" "$line" "$RESET"
    printf '  %slog:%s %s\n\n' "$DIM" "$RESET" "$LOG_FILE"
}

step() {
    STEP_NO=$((STEP_NO + 1))
    printf '\n%s[%d/%d]%s %s%s%s\n' "$BLUE" "$STEP_NO" "$STEP_TOTAL" "$RESET" "$BOLD" "$1" "$RESET"
}

info()  { printf '      %s%s%s\n' "$DIM" "$1" "$RESET"; }
ok()    { printf '      %s %s\n' "$TICK" "$1"; }
warn()  { printf '      %s%s%s\n' "$YELLOW" "$1" "$RESET"; }
fail()  { printf '      %s %s\n' "$CROSS" "$1"; FAILURES+=("$1"); }

# progress_bar <current> <total> <label>
# Built with an explicit loop rather than `printf X%.0s $(seq 1 $n)`: BSD seq
# counts *down* for `seq 1 0`, and bash 3.2 substring slicing of multibyte
# characters depends on the locale. A loop is correct under both.
progress_bar() {
    [ -t 1 ] || return 0
    local cur=$1 total=$2 label=$3 width=26 filled pct bar="" j=0
    [ "$total" -eq 0 ] && return 0
    pct=$(( cur * 100 / total ))
    filled=$(( cur * width / total ))
    while [ "$j" -lt "$width" ]; do
        if [ "$j" -lt "$filled" ]; then bar="$bar$BAR_FULL_CH"; else bar="$bar$BAR_EMPTY_CH"; fi
        j=$(( j + 1 ))
    done
    printf '\r      %s%s%s %3d%% %s(%d/%d)%s %-26.26s' \
        "$CYAN" "$bar" "$RESET" "$pct" "$DIM" "$cur" "$total" "$RESET" "$label"
}

clear_line() { [ -t 1 ] || return 0; printf '\r%*s\r' 78 ''; }

# spin <message> -- <command...>   run a long command with a spinner
spin() {
    local msg="$1"; shift
    [ "$1" = "--" ] && shift
    if [ "$DRY_RUN" -eq 1 ]; then
        info "would run: $*"
        return 0
    fi
    "$@" >>"$LOG_FILE" 2>&1 &
    local pid=$! i=0
    if [ -t 1 ]; then
        while kill -0 "$pid" 2>/dev/null; do
            i=$(( (i + 1) % ${#SPIN_FRAMES[@]} ))
            printf '\r      %s%s%s %s' "$CYAN" "${SPIN_FRAMES[$i]}" "$RESET" "$msg"
            sleep 0.1
        done
        clear_line
    fi
    wait "$pid"
}

#----------------------------------------------------------------------
# Package groups
# bash 3.2 on macOS has no associative arrays, so these are parallel arrays.
#----------------------------------------------------------------------
GROUP_KEYS=(core dev kubernetes cloud aws security apps fonts python plugins dotfiles)
GROUP_DESC=(
    "Shell, search, git, everyday CLI"
    "Languages, build tools, linters"
    "kubectl, helm, k9s, argo, flux"
    "Terraform, Azure, GCP, Ansible"
    "AWS CLI, CDK, SAM, CloudFormation"
    "gpg, sops, age, trivy, nmap"
    "GUI apps (casks) - may need your password"
    "Nerd Fonts for the terminal prompt"
    "Python CLI tools via uv"
    "tmux tpm, vim lightline, fzf keys"
    "Copy dotfiles/ into \$HOME"
)
GROUP_DEFAULT=(1 1 1 1 0 1 1 1 1 1 1)
GROUP_ON=()

group_index() {
    local i=0
    for k in "${GROUP_KEYS[@]}"; do
        [ "$k" = "$1" ] && { echo "$i"; return 0; }
        i=$((i + 1))
    done
    return 1
}

is_on() {
    local idx
    idx="$(group_index "$1")" || return 1
    [ "${GROUP_ON[$idx]}" -eq 1 ]
}

#----------------------------------------------------------------------
# Interactive checklist
#----------------------------------------------------------------------
checklist() {
    local cursor=0 n=${#GROUP_KEYS[@]} key rest first=1

    printf '%sSelect what to install%s\n' "$BOLD" "$RESET"
    printf '%s  up/down or j/k move | space toggles | a all | n none | enter confirm | q quit%s\n\n' \
        "$DIM" "$RESET"

    while true; do
        if [ "$first" -eq 0 ]; then
            printf '\033[%dA' "$n"
        fi
        first=0
        local i=0
        while [ "$i" -lt "$n" ]; do
            local mark pointer colour
            if [ "${GROUP_ON[$i]}" -eq 1 ]; then mark="${GREEN}${ON_CH}${RESET}"; else mark="${DIM}${OFF_CH}${RESET}"; fi
            if [ "$i" -eq "$cursor" ]; then pointer="${CYAN}${PTR_CH}${RESET}"; colour="$BOLD"; else pointer=" "; colour=""; fi
            printf '\r\033[K %s %s %s%-12s%s %s%s%s\n' \
                "$pointer" "$mark" "$colour" "${GROUP_KEYS[$i]}" "$RESET" \
                "$DIM" "${GROUP_DESC[$i]}" "$RESET"
            i=$((i + 1))
        done

        # bash 3.2 (what macOS ships) rejects fractional `read -t`, so the
        # rest of an escape sequence is read without a timeout. Arrow keys
        # always deliver all three bytes, so this does not stall in practice.
        IFS= read -rsn1 key || { key=""; }
        if [ "$key" = $'\033' ]; then
            IFS= read -rsn2 rest || rest=""
            key="$key$rest"
        fi
        case "$key" in
            $'\033[A'|$'\033OA'|k) cursor=$(( (cursor - 1 + n) % n )) ;;
            $'\033[B'|$'\033OB'|j) cursor=$(( (cursor + 1) % n )) ;;
            ' ')  if [ "${GROUP_ON[$cursor]}" -eq 1 ]; then GROUP_ON[$cursor]=0; else GROUP_ON[$cursor]=1; fi ;;
            a|A)  local j=0; while [ "$j" -lt "$n" ]; do GROUP_ON[$j]=1; j=$((j + 1)); done ;;
            n|N)  local j=0; while [ "$j" -lt "$n" ]; do GROUP_ON[$j]=0; j=$((j + 1)); done ;;
            q|Q)  printf '\nAborted.\n'; exit 0 ;;
            '')   break ;;
        esac
    done
    printf '\n'
}

#----------------------------------------------------------------------
# Brewfile handling
#----------------------------------------------------------------------
refresh_installed_cache() {
    brew list --formula -1 2>/dev/null > "$STATE_DIR/formulae" || : > "$STATE_DIR/formulae"
    brew list --cask -1    2>/dev/null > "$STATE_DIR/casks"    || : > "$STATE_DIR/casks"
}

already_installed() {
    local kind="$1" name="${2##*/}"
    if [ "$kind" = brew ]; then
        grep -qxF "$name" "$STATE_DIR/formulae"
    else
        grep -qxF "$name" "$STATE_DIR/casks"
    fi
}

# Strip comments and pull out `tap "x"` / `brew "x"` / `cask "x"` entries.
parse_brewfile() {
    sed 's/[[:space:]]*#.*$//' "$1" \
        | grep -E '^(tap|brew|cask) "' \
        | sed -E 's/^(tap|brew|cask) "([^"]+)".*/\1 \2/'
}

install_group() {
    # Separate lines on purpose: bash expands every word of a `local`
    # statement before assigning any of them, so `local a=$1 b=$a` leaves b
    # referring to the *global* a (an unbound-variable error under `set -u`).
    local group="$1"
    local file="$BREW_DIR/Brewfile.$group"
    [ -f "$file" ] || { warn "no Brewfile for group '$group', skipping"; return 0; }

    local taps=() kinds=() names=()
    while read -r kind name; do
        [ -z "${name:-}" ] && continue
        if [ "$kind" = tap ]; then
            taps+=("$name")
        else
            kinds+=("$kind"); names+=("$name")
        fi
    done < <(parse_brewfile "$file")

    # Taps first, and trust them - Homebrew 6 refuses to load formulae from
    # untrusted third-party taps, which is what silently broke vault/packer.
    local t
    for t in "${taps[@]:-}"; do
        [ -z "$t" ] && continue
        if brew tap 2>/dev/null | grep -qxF "$t"; then
            :
        elif [ "$DRY_RUN" -eq 1 ]; then
            info "would tap $t"
        else
            spin "tapping $t" -- brew tap "$t" || warn "tap failed: $t (see log)"
        fi
        if [ "$DRY_RUN" -eq 0 ] && brew trust --help >/dev/null 2>&1; then
            brew trust --tap "$t" >>"$LOG_FILE" 2>&1 || :
        fi
    done

    local total=${#names[@]} i=0 done_n=0 failed_n=0 skipped_n=0
    [ "$total" -eq 0 ] && { info "nothing to install"; return 0; }

    while [ "$i" -lt "$total" ]; do
        local kind="${kinds[$i]}" name="${names[$i]}" short="${names[$i]##*/}"
        i=$((i + 1))
        progress_bar "$i" "$total" "$short"

        if already_installed "$kind" "$name"; then
            skipped_n=$((skipped_n + 1))
            continue
        fi
        if [ "$DRY_RUN" -eq 1 ]; then
            done_n=$((done_n + 1))
            continue
        fi

        # Installed one at a time on purpose: `brew install a b c` aborts the
        # whole batch if any single name fails to resolve.
        local rc=0
        if [ "$kind" = cask ]; then
            brew install --cask "$name" >>"$LOG_FILE" 2>&1 || rc=$?
        else
            brew install --formula "$name" >>"$LOG_FILE" 2>&1 || rc=$?
        fi
        if [ "$rc" -eq 0 ]; then
            done_n=$((done_n + 1))
        else
            failed_n=$((failed_n + 1))
            FAILURES+=("$group: $name")
        fi
    done

    clear_line
    INSTALLED_COUNT=$((INSTALLED_COUNT + done_n))
    SKIPPED_COUNT=$((SKIPPED_COUNT + skipped_n))
    local summary="$done_n installed, $skipped_n already present"
    [ "$failed_n" -gt 0 ] && summary="$summary, ${RED}$failed_n failed${RESET}"
    ok "$summary"
    [ "$failed_n" -gt 0 ] && warn "failures are listed at the end; details in the log"
    return 0
}

#----------------------------------------------------------------------
# Steps
#----------------------------------------------------------------------
ensure_xcode_clt() {
    step "Xcode Command Line Tools"
    # `command -v xcode-select` is always true - /usr/bin/xcode-select ships
    # with macOS even when the tools are absent. The receipt path is the real
    # test.
    if xcode-select -p >/dev/null 2>&1; then
        ok "already installed ($(xcode-select -p))"
        return 0
    fi
    if [ "$DRY_RUN" -eq 1 ]; then info "would run xcode-select --install"; return 0; fi
    info "opening the installer - accept the dialog to continue"
    xcode-select --install >>"$LOG_FILE" 2>&1 || :
    local waited=0
    while ! xcode-select -p >/dev/null 2>&1; do
        printf '\r      %swaiting for the Xcode CLT installer... %ds%s' "$DIM" "$waited" "$RESET"
        sleep 5
        waited=$((waited + 5))
        if [ "$waited" -ge 1800 ]; then
            clear_line; fail "timed out waiting for Xcode CLT"; return 1
        fi
    done
    clear_line
    ok "installed"
}

ensure_homebrew() {
    step "Homebrew"
    if ! command -v brew >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then info "would install Homebrew"; return 0; fi
        info "installing (this may ask for your password)"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
            >>"$LOG_FILE" 2>&1 || { fail "Homebrew install failed"; return 1; }
    fi
    # The installer does NOT put brew on PATH for the current shell. Without
    # this, every `brew install` below fails on a fresh Apple Silicon Mac.
    if ! command -v brew >/dev/null 2>&1; then
        if   [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x /usr/local/bin/brew ];    then eval "$(/usr/local/bin/brew shellenv)"
        else fail "brew not found after install"; return 1
        fi
    fi
    export HOMEBREW_NO_ENV_HINTS=1
    ok "$(brew --version | head -1) at $(brew --prefix)"
    spin "updating Homebrew" -- brew update || warn "brew update failed, continuing"
    refresh_installed_cache
}

install_python_tools() {
    step "Python CLI tools"
    local list="$REPO_DIR/python-tools.txt"
    [ -f "$list" ] || { warn "python-tools.txt not found, skipping"; return 0; }
    if ! command -v uv >/dev/null 2>&1; then
        warn "uv not installed (it is in the 'dev' group) - skipping"
        return 0
    fi
    local tools=()
    while read -r line; do
        line="${line%%#*}"; line="$(echo "$line" | tr -d '[:space:]')"
        [ -n "$line" ] && tools+=("$line")
    done < "$list"
    local total=${#tools[@]} i=0 done_n=0 failed_n=0
    [ "$total" -eq 0 ] && { info "nothing listed"; return 0; }
    for tool in "${tools[@]}"; do
        i=$((i + 1))
        progress_bar "$i" "$total" "$tool"
        [ "$DRY_RUN" -eq 1 ] && { done_n=$((done_n + 1)); continue; }
        if uv tool install --quiet "$tool" >>"$LOG_FILE" 2>&1; then
            done_n=$((done_n + 1))
        else
            failed_n=$((failed_n + 1)); FAILURES+=("python: $tool")
        fi
    done
    clear_line
    ok "$done_n ready$( [ "$failed_n" -gt 0 ] && echo ", $failed_n failed" )"
}

install_plugins() {
    step "Shell & editor plugins"

    # tmux plugin manager - .tmux.conf ends with `run '~/.tmux/plugins/tpm/tpm'`
    # and does nothing at all without this.
    local tpm="$HOME/.tmux/plugins/tpm"
    if [ -d "$tpm" ]; then
        ok "tpm already present"
    elif [ "$DRY_RUN" -eq 1 ]; then
        info "would clone tpm"
    else
        if spin "cloning tmux plugin manager" -- \
                git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm"; then
            ok "tpm installed (press prefix + I inside tmux to fetch plugins)"
        else
            fail "tpm clone failed"
        fi
    fi

    # vim lightline
    local ll="$HOME/.vim/pack/plugins/start/lightline"
    if [ -d "$ll" ]; then
        ok "lightline.vim already present"
    elif [ "$DRY_RUN" -eq 1 ]; then
        info "would clone lightline.vim"
    else
        mkdir -p "$(dirname "$ll")"
        if spin "cloning lightline.vim" -- \
                git clone --depth=1 https://github.com/itchyny/lightline.vim "$ll"; then
            ok "lightline.vim installed"
        else
            fail "lightline clone failed"
        fi
    fi

    # fzf key bindings + completion
    if command -v fzf >/dev/null 2>&1; then
        local fzf_install
        fzf_install="$(brew --prefix 2>/dev/null)/opt/fzf/install"
        if [ -x "$fzf_install" ] && [ "$DRY_RUN" -eq 0 ]; then
            spin "wiring up fzf key bindings" -- \
                "$fzf_install" --key-bindings --completion --no-update-rc --no-bash --no-fish
            ok "fzf key bindings installed (ctrl-r, ctrl-t, alt-c)"
        else
            info "fzf present; key bindings script not found"
        fi
    fi

    # kubectl completion cache - regenerating this on every shell start cost
    # ~200ms per prompt in the old .zshrc.
    if command -v kubectl >/dev/null 2>&1 && [ "$DRY_RUN" -eq 0 ]; then
        mkdir -p "$HOME/.zsh/completions"
        if kubectl completion zsh > "$HOME/.zsh/completions/_kubectl" 2>>"$LOG_FILE"; then
            ok "cached kubectl completions"
        else
            warn "could not cache kubectl completions"
        fi
    fi
}

apply_dotfiles() {
    step "Dotfiles"
    if [ ! -d "$DOTFILES_DIR" ]; then
        warn "$DOTFILES_DIR not found, skipping"
        return 0
    fi
    # Walks nested paths too, so dotfiles/.config/starship.toml lands at
    # ~/.config/starship.toml. The old flat glob silently dropped those.
    local files=() src
    while IFS= read -r src; do files+=("$src"); done < <(find "$DOTFILES_DIR" -type f | sort)

    local total=${#files[@]} i=0 applied=0 unchanged=0 backed_up=0
    for src in "${files[@]}"; do
        i=$((i + 1))
        local rel="${src#"$DOTFILES_DIR"/}"
        local dest="$HOME/$rel"
        progress_bar "$i" "$total" "$rel"
        if [ -e "$dest" ] && cmp -s "$src" "$dest"; then
            unchanged=$((unchanged + 1))
            continue
        fi
        [ "$DRY_RUN" -eq 1 ] && { applied=$((applied + 1)); continue; }
        if [ -e "$dest" ]; then
            cp "$dest" "$dest.bak.$TIMESTAMP"
            backed_up=$((backed_up + 1))
        fi
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        applied=$((applied + 1))
    done
    clear_line
    ok "$applied applied, $unchanged unchanged, $backed_up backed up (*.bak.$TIMESTAMP)"
}

summary() {
    local rule line="" j=0
    if [ "$UNICODE" -eq 1 ]; then rule=$'\xe2\x94\x80'; else rule="-"; fi
    while [ "$j" -lt 52 ]; do line="$line$rule"; j=$(( j + 1 )); done
    printf '\n%s%s%s\n' "$DIM" "$line" "$RESET"
    if [ "${#FAILURES[@]}" -eq 0 ]; then
        printf '%s%s Done.%s %d packages installed, %d already present.\n' \
            "$BOLD" "$TICK" "$RESET" "$INSTALLED_COUNT" "$SKIPPED_COUNT"
    else
        printf '%s%s Finished with %d failure(s):%s\n' "$BOLD" "$CROSS" "${#FAILURES[@]}" "$RESET"
        local f
        for f in "${FAILURES[@]}"; do printf '    %s- %s%s\n' "$RED" "$f" "$RESET"; done
        printf '  %sFull output: %s%s\n' "$DIM" "$LOG_FILE" "$RESET"
    fi
    printf '\n  %sNext steps%s\n' "$BOLD" "$RESET"
    printf '    1. Restart your terminal, or run: %sexec zsh%s\n' "$CYAN" "$RESET"
    printf '    2. Set your terminal font to %sMesloLGS Nerd Font%s for the prompt glyphs\n' "$CYAN" "$RESET"
    printf '    3. In tmux, press %sprefix + I%s to fetch plugins\n' "$CYAN" "$RESET"
    printf '    4. Sign in: %sgh auth login%s, %sgcloud auth login%s, %saz login%s\n\n' \
        "$CYAN" "$RESET" "$CYAN" "$RESET" "$CYAN" "$RESET"
}

usage() {
    # Print the Usage block from the header comment, without the # markers.
    sed -n '/^# Usage:/,/^# Safe to re-run/p' "$0" | sed 's/^#\{1,\} \{0,1\}//'
    printf '\n  Groups: run --list to see them.\n'
    exit 0
}

#----------------------------------------------------------------------
# Main
#----------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)   ASSUME_YES=1 ;;
        --dry-run)  DRY_RUN=1; ASSUME_YES=1 ;;
        --only)     ONLY="${2:-}"; shift ;;
        --only=*)   ONLY="${1#*=}" ;;
        --skip)     SKIP="${2:-}"; shift ;;
        --skip=*)   SKIP="${1#*=}" ;;
        --list)
            printf '%-12s %-8s %s\n' GROUP DEFAULT DESCRIPTION
            idx=0
            for k in "${GROUP_KEYS[@]}"; do
                if [ "${GROUP_DEFAULT[$idx]}" -eq 1 ]; then d=on; else d=off; fi
                printf '%-12s %-8s %s\n' "$k" "$d" "${GROUP_DESC[$idx]}"
                idx=$((idx + 1))
            done
            exit 0 ;;
        -h|--help)  usage ;;
        *) printf 'Unknown option: %s (try --help)\n' "$1" >&2; exit 2 ;;
    esac
    shift
done

# Seed selection from defaults, then apply --only / --skip.
GROUP_ON=("${GROUP_DEFAULT[@]}")
if [ -n "$ONLY" ]; then
    idx=0; for k in "${GROUP_KEYS[@]}"; do GROUP_ON[$idx]=0; idx=$((idx + 1)); done
    IFS=','; for g in $ONLY; do
        if idx="$(group_index "$g")"; then GROUP_ON[$idx]=1
        else printf 'Unknown group: %s (try --list)\n' "$g" >&2; exit 2; fi
    done; unset IFS
fi
if [ -n "$SKIP" ]; then
    IFS=','; for g in $SKIP; do
        if idx="$(group_index "$g")"; then GROUP_ON[$idx]=0
        else printf 'Unknown group: %s (try --list)\n' "$g" >&2; exit 2; fi
    done; unset IFS
fi

banner
[ "$DRY_RUN" -eq 1 ] && printf '  %sDRY RUN - nothing will be installed or copied%s\n\n' "$YELLOW" "$RESET"

if [ "$ASSUME_YES" -eq 0 ] && [ -t 0 ] && [ -t 1 ] && [ -z "$ONLY" ] && [ -z "$SKIP" ]; then
    checklist
fi

selected=()
idx=0
for k in "${GROUP_KEYS[@]}"; do
    [ "${GROUP_ON[$idx]}" -eq 1 ] && selected+=("$k")
    idx=$((idx + 1))
done

if [ "${#selected[@]}" -eq 0 ]; then
    printf 'Nothing selected. Exiting.\n'
    exit 0
fi

printf '  %sSelected:%s %s\n' "$BOLD" "$RESET" "${selected[*]}"
if is_on apps; then
    printf '  %sSome casks need admin rights - you may be prompted for your password.%s\n' \
        "$YELLOW" "$RESET"
fi

# Xcode CLT + Homebrew always run; the rest depends on the selection.
STEP_TOTAL=2
for g in "${selected[@]}"; do
    case "$g" in
        python|plugins|dotfiles) STEP_TOTAL=$((STEP_TOTAL + 1)) ;;
        *) [ -f "$BREW_DIR/Brewfile.$g" ] && STEP_TOTAL=$((STEP_TOTAL + 1)) ;;
    esac
done

ensure_xcode_clt
ensure_homebrew || { summary; exit 1; }

for g in "${selected[@]}"; do
    case "$g" in
        python|plugins|dotfiles) continue ;;
    esac
    [ -f "$BREW_DIR/Brewfile.$g" ] || continue
    step "Packages: $g"
    install_group "$g"
done

is_on python   && install_python_tools
is_on plugins  && install_plugins
is_on dotfiles && apply_dotfiles

summary
[ "${#FAILURES[@]}" -eq 0 ]
