#!/usr/bin/env bash
# ONCMD-⏻ cross-platform bootstrap installer (macOS/Linux)
set -euo pipefail

REPO_URL="https://github.com/30lnewcomb-byte/OnCmd.git"
INSTALL_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/OnCmd"
REPO_ROOT="$INSTALL_ROOT/repo"
BIN_ROOT="${XDG_BIN_HOME:-$HOME/.local/bin}"
LAUNCHER="$BIN_ROOT/oncmd"

cyan='\033[36m'; green='\033[32m'; yellow='\033[33m'; red='\033[31m'; reset='\033[0m'
say() { printf '%b\n' "$1"; }

say "${cyan}  +===============================================================+${reset}"
say "${cyan}  |             ONCMD-⏻ CROSS-PLATFORM INSTALLER                |${reset}"
say "${cyan}  +===============================================================+${reset}"

command -v git >/dev/null 2>&1 || { say "${red}[FAIL] Git was not found.${reset}"; exit 1; }
mkdir -p "$INSTALL_ROOT" "$BIN_ROOT"

if [[ -d "$REPO_ROOT/.git" ]]; then
  say "${cyan}[1/5] Updating existing OnCmd repository...${reset}"
  git -C "$REPO_ROOT" pull --ff-only || say "${yellow}[WARN] Update could not be fast-forwarded; no reset was performed.${reset}"
elif [[ -e "$REPO_ROOT" ]]; then
  say "${red}[FAIL] $REPO_ROOT exists but is not a Git repository.${reset}"
  exit 1
else
  say "${cyan}[1/5] Downloading OnCmd from GitHub...${reset}"
  git clone "$REPO_URL" "$REPO_ROOT"
fi

say "${cyan}[2/5] Verifying project...${reset}"
required=(README.md LICENSE OnCmd.ps1 src/OnCmd.Platform.ps1 src/OnCmd.Dates.ps1 src/OnCmd.Themes.ps1)
for file in "${required[@]}"; do
  [[ -f "$REPO_ROOT/$file" ]] || { say "${red}[FAIL] Missing required file: $file${reset}"; exit 1; }
done
say "${green}[ OK ] Repository structure verified.${reset}"

say "${cyan}[3/5] Creating OnCmd launcher...${reset}"
cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash
set -euo pipefail
ONCMD_ROOT="$REPO_ROOT"
if ! command -v pwsh >/dev/null 2>&1; then
  printf '%s\\n' 'PowerShell 7 (pwsh) is required to run the current OnCmd core.' >&2
  exit 2
fi
exec pwsh -NoProfile -File "\$ONCMD_ROOT/OnCmd.ps1" "\$@"
EOF
chmod +x "$LAUNCHER"
say "${green}[ OK ] Launcher created: $LAUNCHER${reset}"

say "${cyan}[4/5] Checking command path...${reset}"
case ":${PATH}:" in
  *":$BIN_ROOT:"*) say "${green}[ OK ] $BIN_ROOT is already on PATH.${reset}" ;;
  *) say "${yellow}[NOTE] Add this to your shell profile: export PATH=\"$BIN_ROOT:\$PATH\"${reset}" ;;
esac

say "${cyan}[5/5] Running platform checks...${reset}"
if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -Command ". '$REPO_ROOT/src/OnCmd.Platform.ps1'; Get-OnCmdPlatformInfo | Format-List"
else
  say "${yellow}[NOTE] Install PowerShell 7 to run the OnCmd PowerShell core.${reset}"
fi

say "${green}  +===============================================================+${reset}"
say "${green}  |                 ONCMD-⏻ CROSS-PLATFORM READY                |${reset}"
say "${green}  +===============================================================+${reset}"
say "Run: oncmd status"
