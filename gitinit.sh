#!/usr/bin/env bash

# terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ecosystem paths
GITINIT_DIR="$HOME/.gitinit"
CONFIG_FILE="$GITINIT_DIR/config.env"
IGNORE_DIR="$GITINIT_DIR/gitignores"
LICENSE_DIR="$GITINIT_DIR/licenses"
GITHUB_DIR="$GITINIT_DIR/github_bundles"

# display ascii header
show_header() {
    echo -e "${CYAN}"
    cat << "EOF"
   ____ _ __  _       _ __ 
  / __ `/(_) /_(_)___  (_) /_
 / /_/ // / __/ / __ \/ / __/
 \__, // / /_/ / / / / / /_  
/____//_/\__/_/_/ /_/_/\__/  
                             
EOF
    echo -e "${NC}"
    echo -e "${BLUE}=== GitInit: Project Bootstrapper & Automator ===${NC}\n"
}

# get system details
get_git_user() { git config --global user.name 2>/dev/null || echo ""; }
get_pc_user() { whoami 2>/dev/null || echo "user"; }

# initialize configuration structure
init_ecosystem() {
    mkdir -p "$IGNORE_DIR"
    mkdir -p "$LICENSE_DIR"
    mkdir -p "$GITHUB_DIR"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat <<EOF > "$CONFIG_FILE"
PREF_BRANCH=""
PREF_GITATTR=""
SAVED_DIRS=()
SAVED_OWNERS=()
CUSTOM_LIC_LABELS=()
CUSTOM_LIC_FILES=()
CUSTOM_IGN_LABELS=()
CUSTOM_IGN_FILES=()
CUSTOM_GH_LABELS=()
CUSTOM_GH_DIRS=()
EOF
    fi
}

# serialize bash array to config
write_array() {
    local name=$1
    eval "local arr=(\"\${${name}[@]}\")"
    echo "$name=(" >> "$CONFIG_FILE"
    for item in "${arr[@]}"; do
        echo "  \"${item//\"/\\\"}\"" >> "$CONFIG_FILE"
    done
    echo ")" >> "$CONFIG_FILE"
}

# persist state to config
save_config() {
    [[ $USE_CONFIG -eq 1 ]] || return 0
    init_ecosystem
    
    cat <<EOF > "$CONFIG_FILE"
PREF_BRANCH="$PREF_BRANCH"
PREF_GITATTR="$PREF_GITATTR"
EOF
    write_array SAVED_DIRS
    write_array SAVED_OWNERS
    write_array CUSTOM_LIC_LABELS
    write_array CUSTOM_LIC_FILES
    write_array CUSTOM_IGN_LABELS
    write_array CUSTOM_IGN_FILES
    write_array CUSTOM_GH_LABELS
    write_array CUSTOM_GH_DIRS
}

# cross-platform template string replacer
apply_placeholders() {
    local file=$1
    sed -e "s|{{YEAR}}|$CURRENT_YEAR|g" \
        -e "s|{{OWNER}}|$REPO_OWNER|g" \
        -e "s|{{REPO_NAME}}|$REPO_NAME|g" \
        -e "s|{{REPO_DESC}}|$REPO_DESC|g" "$file" > "${file}.tmp"
    mv "${file}.tmp" "$file"
}

# argument routing
USE_CONFIG=1
case "$1" in
    --reset|reset)
        echo -e "${YELLOW}[*] Resetting gitinit ecosystem...${NC}"
        rm -rf "$GITINIT_DIR"
        echo -e "${GREEN}[+] Ecosystem cleared. Clean slate ready.${NC}"
        exit 0
        ;;
    --no-config)
        echo -e "${YELLOW}[i] Running in no-config mode. Persistent memory disabled.${NC}"
        USE_CONFIG=0
        PREF_BRANCH="main"
        PREF_GITATTR=""
        declare -a SAVED_DIRS=()
        declare -a SAVED_OWNERS=()
        declare -a CUSTOM_LIC_LABELS=()
        declare -a CUSTOM_LIC_FILES=()
        declare -a CUSTOM_IGN_LABELS=()
        declare -a CUSTOM_IGN_FILES=()
        declare -a CUSTOM_GH_LABELS=()
        declare -a CUSTOM_GH_DIRS=()
        ;;
    --config|config)
        init_ecosystem
        [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
        show_header
        while true; do
            echo -e "\n${CYAN}=== gitinit Configuration Manager ===${NC}"
            echo -e "1) Manage saved directories (${#SAVED_DIRS[@]} saved)"
            echo -e "2) Manage saved license owners (${#SAVED_OWNERS[@]} saved)"
            echo -e "3) Change default branch name (Current: ${GREEN}${PREF_BRANCH:-"Ask every time"}${NC})"
            echo -e "4) Change .gitattributes behavior (Current: ${GREEN}${PREF_GITATTR:-"Ask every time"}${NC})"
            echo -e "5) Manage .gitignore templates (${#CUSTOM_IGN_LABELS[@]} saved)"
            echo -e "6) Manage custom LICENSE templates (${#CUSTOM_LIC_LABELS[@]} saved)"
            echo -e "7) Manage custom .github bundles (${#CUSTOM_GH_LABELS[@]} saved)"
            echo -e "8) Export configuration ecosystem (.tar.gz)"
            echo -e "9) Import configuration ecosystem (.tar.gz)"
            echo -e "0) Exit"
            read -p "> Select option (0-9): " M_OPT
            if ! [[ "$M_OPT" =~ ^[0-9]+$ ]]; then M_OPT=99; fi
            case "$M_OPT" in
                3) read -p "New branch name (Leave empty to clear): " PREF_BRANCH; save_config; echo -e "${GREEN}[+] Configuration updated.${NC}" ;;
                4) 
                   echo "1) Always generate, 2) Always skip, 3) Ask every time"
                   read -p "> Select preference: " GA_OPT
                   [[ $GA_OPT == 1 ]] && PREF_GITATTR="yes"
                   [[ $GA_OPT == 2 ]] && PREF_GITATTR="no"
                   [[ $GA_OPT == 3 ]] && PREF_GITATTR=""
                   save_config; echo -e "${GREEN}[+] Configuration updated.${NC}" ;;
                8)
                   read -p "Export destination path [$PWD/gitinit-backup.tar.gz]: " EXP_PATH
                   EXP_PATH=${EXP_PATH:-"$PWD/gitinit-backup.tar.gz"}
                   EXP_PATH="${EXP_PATH/#\~/$HOME}"
                   if tar -czf "$EXP_PATH" -C "$GITINIT_DIR" . 2>/dev/null; then
                       echo -e "${GREEN}[+] Ecosystem successfully exported to: $EXP_PATH${NC}"
                   else
                       echo -e "${RED}[-] Export failed. Check permissions and paths.${NC}"
                   fi
                   ;;
                9)
                   read -p "Enter path to backup archive (.tar.gz): " IMP_PATH
                   IMP_PATH="${IMP_PATH/#\~/$HOME}"
                   if [[ -f "$IMP_PATH" ]]; then
                       echo -e "${YELLOW}[!] WARNING: This will permanently overwrite your current configuration and templates.${NC}"
                       read -p "> Proceed with import? (y/N): " CONFIRM_IMP
                       if [[ "$CONFIRM_IMP" =~ ^[Yy]$ ]]; then
                           rm -rf "$GITINIT_DIR"/*
                           if tar -xzf "$IMP_PATH" -C "$GITINIT_DIR" 2>/dev/null; then
                               [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
                               echo -e "${GREEN}[+] Ecosystem successfully imported.${NC}"
                           else
                               echo -e "${RED}[-] Import failed. Ensure the file is a valid tar.gz archive.${NC}"
                           fi
                       else
                           echo -e "${BLUE}[i] Import cancelled.${NC}"
                       fi
                   else
                       echo -e "${RED}[-] File not found: $IMP_PATH${NC}"
                   fi
                   ;;
                0) exit 0 ;;
                *) echo -e "${YELLOW}[i] List management interface is minimized. Modify '${CONFIG_FILE}' directly for advanced edits.${NC}" ;;
            esac
        done
        exit 0
        ;;
esac

# main flow initialization
show_header

if [[ $USE_CONFIG -eq 1 ]]; then
    init_ecosystem
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
fi

# 1. target directory setup
echo -e "${CYAN}[?] Select the target directory for the project:${NC}"
echo "  1) Script default ($HOME/projects)"
DIR_IDX=2
for dir in "${SAVED_DIRS[@]}"; do
    echo "  $DIR_IDX) $dir (Saved)"
    ((DIR_IDX++))
done
NEW_DIR_IDX=$DIR_IDX
echo "  $NEW_DIR_IDX) + Enter a new directory path..."

read -p "> Select option (1-$NEW_DIR_IDX) [1]: " DIR_CHOICE
DIR_CHOICE=${DIR_CHOICE:-1}
if ! [[ "$DIR_CHOICE" =~ ^[0-9]+$ ]]; then DIR_CHOICE=1; fi

if [[ $DIR_CHOICE -eq 1 ]]; then
    TARGET_BASE="$HOME/projects"
elif [[ $DIR_CHOICE -eq $NEW_DIR_IDX ]]; then
    read -p "[?] Enter new directory path: " NEW_DIR
    NEW_DIR="${NEW_DIR/#\~/$HOME}"
    if [[ $USE_CONFIG -eq 1 ]]; then
        read -p "  > Save this directory as a default for future projects? (y/N): " SAVE_DIR
        if [[ "$SAVE_DIR" =~ ^[Yy]$ ]]; then
            SAVED_DIRS+=("$NEW_DIR")
            save_config
            echo -e "  ${GREEN}[+] Directory saved to configuration.${NC}"
        fi
    fi
    TARGET_BASE="$NEW_DIR"
else
    ARR_IDX=$((DIR_CHOICE - 2))
    TARGET_BASE="${SAVED_DIRS[$ARR_IDX]}"
fi
[[ "${TARGET_BASE}" != */ ]] && TARGET_BASE="${TARGET_BASE}/"

# 2. repository metadata
echo ""
read -p "[?] Repository name (e.g., my-awesome-app): " REPO_NAME
if [[ -z "$REPO_NAME" ]]; then
    echo -e "${RED}[-] Error: Repository name cannot be empty.${NC}"
    exit 1
fi
read -p "[?] Project description (optional): " REPO_DESC

# 3. license owner selection
echo -e "\n${CYAN}[?] Select the copyright owner for the license:${NC}"
GIT_U=$(get_git_user)
PC_U=$(get_pc_user)
echo "  1) Fetch from Git config (${GIT_U:-"Not found"})"
echo "  2) Current system user ($PC_U)"
OWN_IDX=3
for owner in "${SAVED_OWNERS[@]}"; do
    echo "  $OWN_IDX) $owner (Saved)"
    ((OWN_IDX++))
done
NEW_OWN_IDX=$OWN_IDX
echo "  $NEW_OWN_IDX) + Enter a new owner name..."

read -p "> Select option (1-$NEW_OWN_IDX) [1]: " OWN_CHOICE
OWN_CHOICE=${OWN_CHOICE:-1}
if ! [[ "$OWN_CHOICE" =~ ^[0-9]+$ ]]; then OWN_CHOICE=1; fi

if [[ $OWN_CHOICE -eq 1 ]]; then REPO_OWNER="${GIT_U:-$PC_U}"
elif [[ $OWN_CHOICE -eq 2 ]]; then REPO_OWNER="$PC_U"
elif [[ $OWN_CHOICE -eq $NEW_OWN_IDX ]]; then
    read -p "[?] Enter new owner name: " NEW_OWN
    if [[ $USE_CONFIG -eq 1 ]]; then
        read -p "  > Save this owner for future projects? (y/N): " SAVE_OWN
        if [[ "$SAVE_OWN" =~ ^[Yy]$ ]]; then
            SAVED_OWNERS+=("$NEW_OWN")
            save_config
            echo -e "  ${GREEN}[+] Owner saved to configuration.${NC}"
        fi
    fi
    REPO_OWNER="$NEW_OWN"
else
    ARR_IDX=$((OWN_CHOICE - 3))
    REPO_OWNER="${SAVED_OWNERS[$ARR_IDX]}"
fi
CURRENT_YEAR=$(date +"%Y")

# 4. license template selection
echo -e "\n${CYAN}[?] Select a LICENSE template for the project:${NC}"
echo "  0) None"
echo "  -- Built-in Templates --"
echo "  1) MIT License"
echo "  2) Apache License 2.0"
echo "  3) GNU GPLv3"
LIC_IDX=4
if [[ ${#CUSTOM_LIC_LABELS[@]} -gt 0 ]]; then
    echo "  -- Saved Templates --"
    for i in "${!CUSTOM_LIC_LABELS[@]}"; do
        echo "  $LIC_IDX) ${CUSTOM_LIC_LABELS[$i]}"
        ((LIC_IDX++))
    done
fi
echo "  --"
NEW_LIC_IDX=$LIC_IDX
echo "  $NEW_LIC_IDX) + Import a new custom LICENSE file..."

read -p "> Select option (0-$NEW_LIC_IDX) [1]: " LIC_CHOICE
LIC_CHOICE=${LIC_CHOICE:-1}
if ! [[ "$LIC_CHOICE" =~ ^[0-9]+$ ]]; then LIC_CHOICE=1; fi

CHOSEN_LICENSE="BUILTIN|$LIC_CHOICE"
if [[ $LIC_CHOICE -eq $NEW_LIC_IDX ]]; then
    echo -e "\n${BLUE}[i] Info: Placeholders {{YEAR}}, {{OWNER}}, {{REPO_NAME}}, {{REPO_DESC}} will be automatically populated.${NC}\n"
    read -p "[?] Enter the absolute path to your custom license file: " NEW_LIC_PATH
    NEW_LIC_PATH="${NEW_LIC_PATH/#\~/$HOME}"
    if [[ -f "$NEW_LIC_PATH" ]]; then
        if [[ $USE_CONFIG -eq 1 ]]; then
            read -p "  > Import and save this template into the ecosystem for future use? (y/N): " SAVE_LIC
            if [[ "$SAVE_LIC" =~ ^[Yy]$ ]]; then
                read -p "[?] Enter a display label for this template: " NEW_LIC_LBL
                NEW_FILENAME=$(basename "$NEW_LIC_PATH")
                cp "$NEW_LIC_PATH" "$LICENSE_DIR/$NEW_FILENAME"
                CUSTOM_LIC_LABELS+=("$NEW_LIC_LBL")
                CUSTOM_LIC_FILES+=("$NEW_FILENAME")
                save_config
                echo -e "  ${GREEN}[+] Template successfully imported and saved.${NC}"
                CHOSEN_LICENSE="CUSTOM|$NEW_FILENAME"
            else
                CHOSEN_LICENSE="ONETIME|$NEW_LIC_PATH"
            fi
        else
            CHOSEN_LICENSE="ONETIME|$NEW_LIC_PATH"
        fi
    else
        echo -e "${RED}[-] Error: File not found. Skipping license creation.${NC}"
        CHOSEN_LICENSE="BUILTIN|0"
    fi
elif [[ $LIC_CHOICE -ge 4 && $LIC_CHOICE -lt $NEW_LIC_IDX ]]; then
    ARR_IDX=$((LIC_CHOICE - 4))
    CHOSEN_LICENSE="CUSTOM|${CUSTOM_LIC_FILES[$ARR_IDX]}"
fi

# 5. gitignore template selection
echo -e "\n${CYAN}[?] Select a .gitignore template for the project:${NC}"
echo "  0) None"
echo "  -- Built-in Templates --"
echo "  1) Node.js"
echo "  2) Python"
echo "  3) Java"
echo "  4) Basic OS (Mac/Win/Linux)"
IGN_IDX=5
if [[ ${#CUSTOM_IGN_LABELS[@]} -gt 0 ]]; then
    echo "  -- Saved Templates --"
    for i in "${!CUSTOM_IGN_LABELS[@]}"; do
        echo "  $IGN_IDX) ${CUSTOM_IGN_LABELS[$i]}"
        ((IGN_IDX++))
    done
fi
echo "  --"
NEW_IGN_IDX=$IGN_IDX
echo "  $NEW_IGN_IDX) + Import a new custom .gitignore file..."

read -p "> Select option (0-$NEW_IGN_IDX) [1]: " IGN_CHOICE
IGN_CHOICE=${IGN_CHOICE:-1}
if ! [[ "$IGN_CHOICE" =~ ^[0-9]+$ ]]; then IGN_CHOICE=1; fi

CHOSEN_IGNORE="BUILTIN|$IGN_CHOICE"
if [[ $IGN_CHOICE -eq $NEW_IGN_IDX ]]; then
    read -p "[?] Enter the absolute path to your custom .gitignore file: " NEW_IGN_PATH
    NEW_IGN_PATH="${NEW_IGN_PATH/#\~/$HOME}"
    if [[ -f "$NEW_IGN_PATH" ]]; then
        if [[ $USE_CONFIG -eq 1 ]]; then
            read -p "  > Import and save this template into the ecosystem for future use? (y/N): " SAVE_IGN
            if [[ "$SAVE_IGN" =~ ^[Yy]$ ]]; then
                read -p "  [?] Enter a display label for this template: " NEW_IGN_LBL
                NEW_FILENAME=$(basename "$NEW_IGN_PATH")
                cp "$NEW_IGN_PATH" "$IGNORE_DIR/$NEW_FILENAME"
                CUSTOM_IGN_LABELS+=("$NEW_IGN_LBL")
                CUSTOM_IGN_FILES+=("$NEW_FILENAME")
                save_config
                echo -e "  ${GREEN}[+] Template successfully imported and saved.${NC}"
                CHOSEN_IGNORE="CUSTOM|$NEW_FILENAME"
            else
                CHOSEN_IGNORE="ONETIME|$NEW_IGN_PATH"
            fi
        else
            CHOSEN_IGNORE="ONETIME|$NEW_IGN_PATH"
        fi
    else
        echo -e "${RED}[-] Error: File not found. Skipping .gitignore creation.${NC}"
        CHOSEN_IGNORE="BUILTIN|0"
    fi
elif [[ $IGN_CHOICE -ge 5 && $IGN_CHOICE -lt $NEW_IGN_IDX ]]; then
    ARR_IDX=$((IGN_CHOICE - 5))
    CHOSEN_IGNORE="CUSTOM|${CUSTOM_IGN_FILES[$ARR_IDX]}"
fi

# 6. github folder bundle selection
echo -e "\n${CYAN}[?] Select a .github/ template bundle (workflows, issue templates, etc.):${NC}"
echo "  0) None"
GH_IDX=1
if [[ ${#CUSTOM_GH_LABELS[@]} -gt 0 ]]; then
    echo "  -- Saved Bundles --"
    for i in "${!CUSTOM_GH_LABELS[@]}"; do
        echo "  $GH_IDX) ${CUSTOM_GH_LABELS[$i]}"
        ((GH_IDX++))
    done
fi
echo "  --"
NEW_GH_IDX=$GH_IDX
echo "  $NEW_GH_IDX) + Import a new .github folder bundle..."

read -p "> Select option (0-$NEW_GH_IDX) [0]: " GH_CHOICE
GH_CHOICE=${GH_CHOICE:-0}
if ! [[ "$GH_CHOICE" =~ ^[0-9]+$ ]]; then GH_CHOICE=0; fi

CHOSEN_GH="NONE|0"
if [[ $GH_CHOICE -eq $NEW_GH_IDX ]]; then
    echo -e "\n${BLUE}[i] Info: Placeholders {{YEAR}}, {{OWNER}}, {{REPO_NAME}}, {{REPO_DESC}} inside your .github files will be populated.${NC}\n"
    read -p "[?] Enter the absolute path to the .github directory: " NEW_GH_PATH
    NEW_GH_PATH="${NEW_GH_PATH/#\~/$HOME}"
    if [[ -d "$NEW_GH_PATH" ]]; then
        if [[ $USE_CONFIG -eq 1 ]]; then
            read -p "  > Import and save this bundle into the ecosystem for future use? (y/N): " SAVE_GH
            if [[ "$SAVE_GH" =~ ^[Yy]$ ]]; then
                read -p "  [?] Enter a display label for this bundle: " NEW_GH_LBL
                NEW_DIRNAME="bundle_$(date +%s)"
                mkdir -p "$GITHUB_DIR/$NEW_DIRNAME"
                cp -a "$NEW_GH_PATH/." "$GITHUB_DIR/$NEW_DIRNAME/"
                CUSTOM_GH_LABELS+=("$NEW_GH_LBL")
                CUSTOM_GH_DIRS+=("$NEW_DIRNAME")
                save_config
                echo -e "  ${GREEN}[+] Bundle successfully imported and saved.${NC}"
                CHOSEN_GH="CUSTOM|$NEW_DIRNAME"
            else
                CHOSEN_GH="ONETIME|$NEW_GH_PATH"
            fi
        else
            CHOSEN_GH="ONETIME|$NEW_GH_PATH"
        fi
    else
        echo -e "${RED}[-] Error: Directory not found. Skipping .github bundle implementation.${NC}"
    fi
elif [[ $GH_CHOICE -ge 1 && $GH_CHOICE -lt $NEW_GH_IDX ]]; then
    ARR_IDX=$((GH_CHOICE - 1))
    CHOSEN_GH="CUSTOM|${CUSTOM_GH_DIRS[$ARR_IDX]}"
fi

# 7. gitattributes setup
DO_GITATTR=0
if [[ -z "$PREF_GITATTR" ]]; then
    echo -e "\n${CYAN}[?] Generate .gitattributes to enforce consistent line endings (CRLF/LF)?:${NC}"
    if [[ $USE_CONFIG -eq 1 ]]; then
        echo "  1) Yes, generate it"
        echo "  2) Yes, generate it (Save as default)"
        echo "  3) No, skip"
        echo "  4) No, skip (Save as default)"
        read -p "> Select option (1-4)[1]: " GA_CHOICE
        GA_CHOICE=${GA_CHOICE:-1}
        if ! [[ "$GA_CHOICE" =~ ^[1-4]$ ]]; then GA_CHOICE=1; fi
        
        case $GA_CHOICE in
            1) DO_GITATTR=1 ;;
            2) DO_GITATTR=1; PREF_GITATTR="yes"; save_config; echo -e "  ${GREEN}[+] Preference saved ('yes'). You will not be prompted again.${NC}" ;;
            3) DO_GITATTR=0 ;;
            4) DO_GITATTR=0; PREF_GITATTR="no"; save_config; echo -e "  ${GREEN}[+] Preference saved ('no'). You will not be prompted again.${NC}" ;;
        esac
    else
        echo "  1) Yes, generate it"
        echo "  2) No, skip"
        read -p "> Select option (1-2) [1]: " GA_CHOICE
        GA_CHOICE=${GA_CHOICE:-1}
        if ! [[ "$GA_CHOICE" =~ ^[1-2]$ ]]; then GA_CHOICE=1; fi
        
        case $GA_CHOICE in
            1) DO_GITATTR=1 ;;
            2) DO_GITATTR=0 ;;
        esac
    fi
else
    [[ "$PREF_GITATTR" == "yes" ]] && DO_GITATTR=1 || DO_GITATTR=0
fi

# 8. branch selection
if [[ -z "$PREF_BRANCH" ]]; then
    echo -e "\n${CYAN}[?] Specify the initial branch name:${NC}"
    if [[ $USE_CONFIG -eq 1 ]]; then
        echo "  1) main"
        echo "  2) main (Save as default)"
        echo "  3) Enter a custom branch name..."
        read -p "> Select option (1-3) [1]: " BR_CHOICE
        BR_CHOICE=${BR_CHOICE:-1}
        if ! [[ "$BR_CHOICE" =~ ^[1-3]$ ]]; then BR_CHOICE=1; fi
        
        if [[ $BR_CHOICE -eq 2 ]]; then
            REPO_BRANCH="main"
            PREF_BRANCH="main"
            save_config
            echo -e "  ${GREEN}[+] Preference saved. Future projects will default to 'main'.${NC}"
        elif [[ $BR_CHOICE -eq 3 ]]; then
            read -p "[?] Enter branch name: " REPO_BRANCH
        else
            REPO_BRANCH="main"
        fi
    else
        echo "  1) main"
        echo "  2) Enter a custom branch name..."
        read -p "> Select option (1-2) [1]: " BR_CHOICE
        BR_CHOICE=${BR_CHOICE:-1}
        if ! [[ "$BR_CHOICE" =~ ^[1-2]$ ]]; then BR_CHOICE=1; fi
        
        if [[ $BR_CHOICE -eq 2 ]]; then
            read -p "[?] Enter branch name: " REPO_BRANCH
        else
            REPO_BRANCH="main"
        fi
    fi
else
    REPO_BRANCH="$PREF_BRANCH"
fi

# 9. npm setup
echo ""
read -p "[?] Initialize NPM 'commit-and-tag-version' and configure package.json? (y/N) [y]: " SETUP_NPM
SETUP_NPM=${SETUP_NPM:-y}

# 10. remote repository setup
echo ""
read -p "[?] Enter Git remote URL (SSH/HTTPS)[Leave blank to use GitHub CLI]: " REMOTE_URL

USE_GH_CLI=0
GH_VISIBILITY="private"
if [[ -z "$REMOTE_URL" ]]; then
    if command -v gh >/dev/null 2>&1; then
        echo -e "${YELLOW}[i] No URL provided. GitHub CLI (gh) detected.${NC}"
        echo -e "${CYAN}[?] Create remote repository via GitHub CLI?:${NC}"
        echo "  1) Yes, create a public repository"
        echo "  2) Yes, create a private repository"
        echo "  0) No, skip remote creation"
        read -p "> Select option (0-2) [2]: " GH_CHOICE
        GH_CHOICE=${GH_CHOICE:-2}
        if ! [[ "$GH_CHOICE" =~ ^[0-9]+$ ]]; then GH_CHOICE=2; fi
        
        if [[ "$GH_CHOICE" == "1" ]]; then USE_GH_CLI=1; GH_VISIBILITY="public"; fi
        if [[ "$GH_CHOICE" == "2" ]]; then USE_GH_CLI=1; GH_VISIBILITY="private"; fi
    else
        echo -e "${YELLOW}[i] No URL provided and GitHub CLI not found. Skipping remote configuration.${NC}"
    fi
fi

# execution phase
TARGET_DIR="${TARGET_BASE}${REPO_NAME}"

echo -e "\n${YELLOW}[*] Starting execution sequence...${NC}"
echo -e "${YELLOW}[*] Initializing project at: ${TARGET_DIR}${NC}"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR" || exit

# generate readme
echo -e "${YELLOW}[*] Generating README.md...${NC}"
cat > README.md << EOF
# $REPO_NAME

$REPO_DESC
EOF

# generate license
IFS='|' read -r LIC_TYPE LIC_VAL <<< "$CHOSEN_LICENSE"
if [[ "$LIC_TYPE" == "BUILTIN" && "$LIC_VAL" != "0" ]]; then
    echo -e "${YELLOW}[*] Generating LICENSE (Built-in template)...${NC}"
    if [[ "$LIC_VAL" == "1" ]]; then echo -e "MIT License\n\nCopyright (c) $CURRENT_YEAR $REPO_OWNER" > LICENSE; fi
    if [[ "$LIC_VAL" == "2" ]]; then echo -e "Apache License, Version 2.0\nCopyright $CURRENT_YEAR $REPO_OWNER" > LICENSE; fi
    if [[ "$LIC_VAL" == "3" ]]; then echo -e "GNU GPLv3 License\nCopyright (C) $CURRENT_YEAR $REPO_OWNER" > LICENSE; fi
elif [[ "$LIC_TYPE" == "CUSTOM" || "$LIC_TYPE" == "ONETIME" ]]; then
    echo -e "${YELLOW}[*] Generating LICENSE (Custom template)...${NC}"
    SRC_FILE=""
    [[ "$LIC_TYPE" == "CUSTOM" ]] && SRC_FILE="$LICENSE_DIR/$LIC_VAL" || SRC_FILE="$LIC_VAL"
    cp "$SRC_FILE" LICENSE
    apply_placeholders "LICENSE"
fi

# generate gitignore
IFS='|' read -r IGN_TYPE IGN_VAL <<< "$CHOSEN_IGNORE"
if [[ "$IGN_TYPE" == "BUILTIN" && "$IGN_VAL" != "0" ]]; then
    echo -e "${YELLOW}[*] Generating .gitignore (Built-in template)...${NC}"
    C_IGN="# OS\n.DS_Store\nThumbs.db\n.idea/\n.vscode/\n"
    if [[ "$IGN_VAL" == "1" ]]; then echo -e "${C_IGN}\n# Node\nnode_modules/\n.env\ndist/\n" > .gitignore; fi
    if [[ "$IGN_VAL" == "2" ]]; then echo -e "${C_IGN}\n# Python\n__pycache__/\n*.pyc\nvenv/\n.env\n" > .gitignore; fi
    if [[ "$IGN_VAL" == "3" ]]; then echo -e "${C_IGN}\n# Java\n*.class\ntarget/\n" > .gitignore; fi
    if [[ "$IGN_VAL" == "4" ]]; then echo -e "${C_IGN}" > .gitignore; fi
elif [[ "$IGN_TYPE" == "CUSTOM" || "$IGN_TYPE" == "ONETIME" ]]; then
    echo -e "${YELLOW}[*] Generating .gitignore (Custom template)...${NC}"
    [[ "$IGN_TYPE" == "CUSTOM" ]] && cat "$IGNORE_DIR/$IGN_VAL" > .gitignore || cat "$IGN_VAL" > .gitignore
fi

# generate github bundle
IFS='|' read -r GH_TYPE GH_VAL <<< "$CHOSEN_GH"
if [[ "$GH_TYPE" == "CUSTOM" || "$GH_TYPE" == "ONETIME" ]]; then
    echo -e "${YELLOW}[*] Generating .github/ directory (Custom bundle)...${NC}"
    SRC_DIR=""
    [[ "$GH_TYPE" == "CUSTOM" ]] && SRC_DIR="$GITHUB_DIR/$GH_VAL" || SRC_DIR="$GH_VAL"
    mkdir -p .github
    cp -a "$SRC_DIR/." ".github/"
    
    find .github -type f | while read -r file; do
        apply_placeholders "$file"
    done
fi

# generate gitattributes
if [[ $DO_GITATTR -eq 1 ]]; then
    echo -e "${YELLOW}[*] Securing line endings (.gitattributes)...${NC}"
    echo "* text=auto eol=lf" > .gitattributes
fi

# initialize npm
if [[ "$SETUP_NPM" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}[*] Initializing NPM and installing dependencies...${NC}"
    if [[ -f .gitignore ]]; then
        grep -q "node_modules" .gitignore || echo -e "\n# NPM\nnode_modules/" >> .gitignore
    else
        echo -e "# NPM\nnode_modules/" > .gitignore
    fi
    
    npm init -y > /dev/null 2>&1
    npm install --save-dev commit-and-tag-version > /dev/null 2>&1
    node -e "
        const fs = require('fs');
        let pkg = JSON.parse(fs.readFileSync('package.json'));
        pkg.scripts = pkg.scripts || {};
        pkg.scripts.release = 'commit-and-tag-version';
        fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    "
    echo -e "${YELLOW}[*] Updating package.json configuration...${NC}"
fi

# initialize git repository
echo -e "${YELLOW}[*] Initializing Git repository...${NC}"
git init -q
git add . 2>/dev/null
echo -e "${YELLOW}[*] Creating initial commit...${NC}"
git commit -m "first commit" -q
git branch -M "$REPO_BRANCH"

# remote repository setup
FINAL_URL=""
if [[ -n "$REMOTE_URL" ]]; then
    echo -e "${YELLOW}[*] Pushing to remote repository...${NC}"
    git remote add origin "$REMOTE_URL"
    git push -u origin "$REPO_BRANCH" -q
    FINAL_URL="$REMOTE_URL"
elif [[ $USE_GH_CLI -eq 1 ]]; then
    echo -e "${YELLOW}[*] Creating and pushing repository via GitHub CLI...${NC}"
    gh repo create "$REPO_NAME" --description "$REPO_DESC" --$GH_VISIBILITY --source=. --remote=origin --push > /dev/null 2>&1
    FINAL_URL=$(gh repo view --json url -q .url 2>/dev/null)
fi

# final message
echo -e "\n${CYAN}=========================================================================${NC}"
if [[ -n "$FINAL_URL" ]]; then
    echo -e "${GREEN}[OK] Project '${REPO_NAME}' successfully initialized and pushed to remote.${NC}"
else
    echo -e "${GREEN}[OK] Project '${REPO_NAME}' successfully initialized (Local only).${NC}"
fi
echo -e "${BLUE}  Target Path: ${TARGET_DIR}${NC}"
if [[ -n "$FINAL_URL" ]]; then
    echo -e "${BLUE}  Remote Repo: ${FINAL_URL}${NC}"
fi
echo -e "${CYAN}=========================================================================${NC}\n"