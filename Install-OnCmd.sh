#!/usr/bin/env bash
# ============================================================================
# ONCMD-⏻ CROSS-PLATFORM BOOTSTRAP INSTALLER
#
# macOS + Linux installer.
# Keeps the repository in one predictable directory and creates a small
# `oncmd` launcher without requiring administrator rights.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/30lnewcomb-byte/OnCmd/main/Install-OnCmd.sh | bash
# ============================================================================

set -euo pipefail

REPO_URL="https://github.com/30lnewcomb-byte/OnCmd.git"
INSTALL_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/OnCmd"
REPO_ROOT="$INSTALL_ROOT/repo"
BIN_ROOT="${XDG_BIN_HOME:-$HOME/.local/bin}"
LAUNCHER="$BIN_ROOT/oncmd"

cyan='\033[36m'
green='\033[32m'
yellow='\033[33m'
white='\033[37m'
red='\033[31m'
reset='\033[0m'

say() { printf '%b\n' "$1"; }

say "${cyan}"
say "  +===============================================================+"
say "  |             ONCMD-⏻ CROSS-PLATFORM INSTALLER                |"
say "  +===============================================================+"
say "${reset}"

if ! command -v git >/dev/null 2>&1; then
  say "${red}  [FAIL] Git was not found.${reset}"
  say "${yellow}         Install Git, then run this installer again.${reset}"
  exit 1
fi

mkdir -p "$INSTALL_ROOT" "$BIN_ROOT"

if [[ -d "$REPO_ROOT/.git" ]]; then
  say "${cyan}  [1/5] Existing OnCmd repository found.${reset}"
  git -C "$REPO_ROOT" pull --ff-only || {
    say "${yellow}  [WARN] Existing repository could not be fast-forwarded. No reset was performed.${reset}"
  }
else
  if [[ -e "$REPO_ROOT" ]]; then
    say "${red}  [FAIL] $REPO_ROOT exists but is not a Git repository.${reset}"
    exit 1
  fi
  say "${cyan}  [1/5] Downloading OnCmd from GitHub...${reset}"
  git clone "$REPO_URL" "$REPO_ROOT"
fi

say "${cyan}  [2/5] Verifying project...${reset}"
required=(README.md LICENSE src/OnCmd.Platform.ps1 src/OnCmd.Dates.ps1 src/OnCmd.Themes.ps1)
for file in "${required[@]}"; do
  if [[ ! -f "$REPO_ROOT/$file" ]]; then
    say "${red}  [FAIL] Missing required file: $file${reset}"
    exit 1
  fi
done
say "${green}        [ OK ] Repository structure verified.${reset}"

say "${cyan}  [3/5] Creating OnCmd launcher...${reset}"
cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash
set -euo pipefail
ONCMD_ROOT="$REPO_ROOT"

if command -v pwsh >/dev/null 2>&1 && [[ -f "\$ONCMD_ROOT/OnCmd.ps1" ]]; then
  exec pwsh -NoProfile -File "\$ONCMD_ROOT/OnCmd.ps1" "\$@"
fi

if [[ -x "\$ONCMD_ROOT/oncmd" ]]; then
  exec "\$ONCMD_ROOT/oncmd" "\$@"
fi

printf '%s\\n' 'OnCmd core entrypoint is not installed yet for this platform.' >&2
exit 2
EOF
chmod +x "$LAUNCHER"
say "${green}        [ OK ] Launcher created: $LAUNCHER${reset}"

say "${cyan}  [4/5] Checking command path...${reset}"
case ":${PATH}:" in
  *":$BIN_ROOT:"*)
    say "${green}        [ OK ] $BIN_ROOT is already on PATH.${reset}"
    ;;
  *)
    say "${yellow}        [NOTE] Add this to your shell profile if needed:${reset}"
    say "${white}               export PATH=\"$BIN_ROOT:\$PATH\"${reset}"
    ;;
esac

say "${cyan}  [5/5] Running platform checks...${reset}"
if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -Command ". '$REPO_ROOT/src/OnCmd.Platform.ps1'; Get-OnCmdPlatformInfo | Format-List"
elif [[ "$(uname -s)" == "Darwin" ]]; then
  say "${green}        [ OK ] macOS detected.${reset}"
  command -v pmset >/dev/null 2>&1 && say "${green}        [ OK ] Native sleep support detected.${reset}" || true
elif [[ "$(uname -s)" == "Linux" ]]; then
  say "${green}        [ OK ] Linux detected.${reset}"
  command -v systemctl >/dev/null 2>&1 && say "${green}        [ OK ] systemd power support detected.${reset}" || true
fi

say "${cyan}"
say "  +===============================================================+"
say "  |                 ONCMD-⏻ CROSS-PLATFORM READY                |"
say "  +===============================================================+"
say "${reset}"
say "  Repository: $REPO_ROOT"
say "  Launcher:   $LAUNCHER"
say ""
say "  Run: oncmd"
say ""
say "  Note: Windows keeps its existing PowerShell enforcement path."
say "        macOS/Linux use the shared platform abstraction for native"
say "        lock and sleep operations as their platform support lands."
