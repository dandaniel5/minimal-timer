#!/bin/bash

# 🚀 Universal Release Script
# Automatically publishes OR updates based on current status

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/package-managers.json"

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  🚀 Universal Release Manager         ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check dependencies
check_dependencies() {
    local missing=()
    
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    command -v python3 >/dev/null 2>&1 || missing+=("python3")
    command -v git >/dev/null 2>&1 || missing+=("git")
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}❌ Missing dependencies: ${missing[*]}${NC}"
        echo -e "${YELLOW}Install with: brew install ${missing[*]}${NC}"
        exit 1
    fi
}

# Get current version from config
get_current_version() {
    jq -r '.version' "$CONFIG_FILE"
}

# Update version in config
update_version_in_config() {
    local new_version=$1
    jq ".version = \"$new_version\"" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
}

# Update version in all files
update_all_files() {
    local new_version=$1
    
    echo -e "${BLUE}📝 Updating version to $new_version in all files...${NC}"
    
    # setup.py
    if [ -f "setup.py" ]; then
        sed -i.bak "s/version=\"[^\"]*\"/version=\"$new_version\"/" setup.py
        rm -f setup.py.bak
        echo -e "  ✅ setup.py"
    fi
    
    # Homebrew formula
    if [ -d "Formula" ]; then
        FORMULA_FILE=$(find Formula -name "*.rb" | head -n 1)
        if [ -f "$FORMULA_FILE" ]; then
            sed -i.bak "s/version \"[^\"]*\"/version \"$new_version\"/" "$FORMULA_FILE"
            rm -f "$FORMULA_FILE.bak"
            echo -e "  ✅ Homebrew formula"
        fi
    fi
    
    # snapcraft.yaml
    if [ -f "snap/snapcraft.yaml" ]; then
        sed -i.bak "s/version: '[^']*'/version: '$new_version'/" snap/snapcraft.yaml
        rm -f snap/snapcraft.yaml.bak
        echo -e "  ✅ snapcraft.yaml"
    fi
    
    # PKGBUILD
    if [ -f "PKGBUILD" ]; then
        sed -i.bak "s/pkgver=[^ ]*/pkgver=$new_version/" PKGBUILD
        rm -f PKGBUILD.bak
        echo -e "  ✅ PKGBUILD"
    fi
    
    # package.json
    if [ -f "package.json" ]; then
        jq ".version = \"$new_version\"" package.json > package.json.tmp
        mv package.json.tmp package.json
        echo -e "  ✅ package.json"
    fi
    
    # .nuspec
    if [ -f "minimal-timer.nuspec" ]; then
        sed -i.bak "s/<version>[^<]*<\\/version>/<version>$new_version<\\/version>/" minimal-timer.nuspec
        rm -f minimal-timer.nuspec.bak
        echo -e "  ✅ .nuspec"
    fi
    
    echo -e "${GREEN}✅ All files updated${NC}"
}

# Git commit and tag
git_commit_and_tag() {
    local version=$1
    
    echo -e "${BLUE}📝 Creating git commit and tag...${NC}"
    
    git add .
    git commit -m "Release version $version" || echo -e "${YELLOW}⚠️  No changes to commit${NC}"
    
    # Delete tag if exists
    git tag -d "v$version" 2>/dev/null || true
    git push origin ":refs/tags/v$version" 2>/dev/null || true
    
    # Create new tag
    git tag -a "v$version" -m "Version $version"
    
    echo -e "${GREEN}✅ Git tag created${NC}"
}

# Publish to PyPI
publish_pypi() {
    echo -e "${YELLOW}📦 Publishing to PyPI...${NC}"
    
    if [ ! -f "setup.py" ]; then
        echo -e "${RED}❌ setup.py not found${NC}"
        return 1
    fi
    
    # Clean old builds
    rm -rf dist/ build/ *.egg-info
    
    # Build
    /opt/homebrew/bin/python3 setup.py sdist bdist_wheel
    
    # Check if package exists on PyPI
    PACKAGE_NAME=$(jq -r '.managers.pypi.package_name' "$CONFIG_FILE")
    if pip3 index versions "$PACKAGE_NAME" >/dev/null 2>&1; then
        echo -e "${BLUE}ℹ️  Package exists on PyPI, uploading update...${NC}"
    else
        echo -e "${BLUE}ℹ️  First time publishing to PyPI...${NC}"
    fi
    
    # Upload
    /opt/homebrew/bin/python3 -m twine upload dist/* --skip-existing
    
    echo -e "${GREEN}✅ Published to PyPI${NC}"
    
    # Update status in config
    jq '.managers.pypi.status = "published"' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
}

# Update Homebrew
publish_homebrew() {
    echo -e "${YELLOW}🍺 Updating Homebrew formula...${NC}"
    
    FORMULA_DIR="Formula"
    if [ ! -d "$FORMULA_DIR" ]; then
        echo -e "${YELLOW}⚠️  Formula directory not found, skipping${NC}"
        return 0
    fi
    
    cd "$FORMULA_DIR"
    git add .
    git commit -m "Update to version $(get_current_version)" || true
    git push || echo -e "${YELLOW}⚠️  Failed to push Homebrew formula${NC}"
    cd ..
    
    echo -e "${GREEN}✅ Homebrew formula updated${NC}"
}

# Publish to Snap
publish_snap() {
    echo -e "${YELLOW}📸 Publishing to Snap Store...${NC}"
    
    if [ ! -f "snap/snapcraft.yaml" ]; then
        echo -e "${YELLOW}⚠️  snapcraft.yaml not found, skipping${NC}"
        return 0
    fi
    
    if ! command -v snapcraft >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  snapcraft not installed, skipping${NC}"
        return 0
    fi
    
    snapcraft
    snapcraft upload --release=stable *.snap
    
    echo -e "${GREEN}✅ Published to Snap Store${NC}"
    
    jq '.managers.snap.status = "published"' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
}

# Publish to AUR
publish_aur() {
    echo -e "${YELLOW}🏛️  Publishing to AUR...${NC}"
    
    if [ ! -f "PKGBUILD" ]; then
        echo -e "${YELLOW}⚠️  PKGBUILD not found, skipping${NC}"
        return 0
    fi
    
    if ! command -v makepkg >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  makepkg not installed, skipping${NC}"
        return 0
    fi
    
    makepkg --printsrcinfo > .SRCINFO
    
    echo -e "${BLUE}ℹ️  AUR requires manual git push to AUR repository${NC}"
    echo -e "${GREEN}✅ PKGBUILD and .SRCINFO updated${NC}"
}

# Create Winget manifest
publish_winget() {
    echo -e "${YELLOW}🪟 Creating Winget manifest...${NC}"
    
    VERSION=$(get_current_version)
    mkdir -p winget
    
    cat > winget/DanilKodolov.MinimalTimer.yaml <<EOF
PackageIdentifier: DanilKodolov.MinimalTimer
PackageVersion: $VERSION
PackageName: Minimal Timer
Publisher: Danil Kodolov
License: MIT
ShortDescription: A minimalist command-line timer with smart time parsing
PackageUrl: https://github.com/dandaniel5/minimal-timer
Installers:
  - Architecture: x64
    InstallerType: portable
    InstallerUrl: https://github.com/dandaniel5/minimal-timer/releases/download/v$VERSION/timer.py
ManifestType: singleton
ManifestVersion: 1.0.0
EOF
    
    echo -e "${BLUE}ℹ️  Winget manifest created in winget/ directory${NC}"
    echo -e "${BLUE}ℹ️  Submit PR to https://github.com/microsoft/winget-pkgs${NC}"
    echo -e "${GREEN}✅ Winget manifest ready${NC}"
}

# Publish to Chocolatey
publish_chocolatey() {
    echo -e "${YELLOW}🍫 Publishing to Chocolatey...${NC}"
    
    if [ ! -f "minimal-timer.nuspec" ]; then
        echo -e "${YELLOW}⚠️  .nuspec file not found, skipping${NC}"
        return 0
    fi
    
    if ! command -v choco >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  choco not installed, skipping${NC}"
        return 0
    fi
    
    choco pack
    choco push minimal-timer.*.nupkg --source https://push.chocolatey.org/
    
    echo -e "${GREEN}✅ Published to Chocolatey${NC}"
    
    jq '.managers.chocolatey.status = "published"' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
}

# Main publishing logic
publish_all() {
    local managers=$(jq -r '.managers | to_entries[] | select(.value.enabled == true) | .key' "$CONFIG_FILE")
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Publishing to all enabled platforms${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    for manager in $managers; do
        echo ""
        case $manager in
            pypi)
                publish_pypi || echo -e "${RED}❌ Failed to publish to PyPI${NC}"
                ;;
            homebrew)
                publish_homebrew || echo -e "${RED}❌ Failed to update Homebrew${NC}"
                ;;
            snap)
                publish_snap || echo -e "${RED}❌ Failed to publish to Snap${NC}"
                ;;
            aur)
                publish_aur || echo -e "${RED}❌ Failed to publish to AUR${NC}"
                ;;
            winget)
                publish_winget || echo -e "${RED}❌ Failed to create Winget manifest${NC}"
                ;;
            chocolatey)
                publish_chocolatey || echo -e "${RED}❌ Failed to publish to Chocolatey${NC}"
                ;;
            *)
                echo -e "${YELLOW}⚠️  $manager: Manual publishing required${NC}"
                ;;
        esac
    done
}

# Show summary
show_summary() {
    local version=$1
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✨ Release Complete!${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  📌 Version: ${GREEN}$version${NC}"
    echo ""
    echo -e "${YELLOW}📋 Next steps:${NC}"
    echo -e "  1. Push to GitHub: ${BLUE}git push && git push --tags${NC}"
    echo -e "  2. Create GitHub release at: ${BLUE}https://github.com/dandaniel5/minimal-timer/releases${NC}"
    echo -e "  3. Test installation: ${BLUE}pip install minimal-timer --upgrade${NC}"
    echo ""
    echo -e "${GREEN}Users can now install via:${NC}"
    echo -e "  ${BLUE}pip install minimal-timer${NC}"
    echo -e "  ${BLUE}brew upgrade timer${NC}"
    echo ""
}

# Main execution
main() {
    check_dependencies
    
    CURRENT_VERSION=$(get_current_version)
    
    echo -e "${BLUE}📌 Current version: $CURRENT_VERSION${NC}"
    echo ""
    echo -e "${YELLOW}What would you like to do?${NC}"
    echo -e "  ${GREEN}1${NC} - Publish current version ($CURRENT_VERSION)"
    echo -e "  ${GREEN}2${NC} - Update to new version and publish"
    echo -e "  ${GREEN}3${NC} - Cancel"
    echo ""
    read -p "Choose [1-3]: " -n 1 -r choice
    echo ""
    echo ""
    
    case $choice in
        1)
            echo -e "${BLUE}📦 Publishing version $CURRENT_VERSION...${NC}"
            echo ""
            
            git_commit_and_tag "$CURRENT_VERSION"
            publish_all
            show_summary "$CURRENT_VERSION"
            ;;
        2)
            echo -e "${YELLOW}Enter new version (current: $CURRENT_VERSION):${NC}"
            read -p "> " NEW_VERSION
            
            if [ -z "$NEW_VERSION" ]; then
                echo -e "${RED}❌ Version cannot be empty${NC}"
                exit 1
            fi
            
            echo ""
            echo -e "${BLUE}🔄 Updating to version $NEW_VERSION...${NC}"
            echo ""
            
            update_version_in_config "$NEW_VERSION"
            update_all_files "$NEW_VERSION"
            git_commit_and_tag "$NEW_VERSION"
            publish_all
            show_summary "$NEW_VERSION"
            ;;
        3)
            echo -e "${RED}❌ Cancelled${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid choice${NC}"
            exit 1
            ;;
    esac
}

main "$@"
