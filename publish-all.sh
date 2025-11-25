#!/bin/bash

# 🚀 Multi-Platform Publishing Script
# Publishes minimal-timer to all enabled package managers

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/package-managers.json"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  📦 Multi-Platform Publisher          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

# Read version from config
VERSION=$(jq -r '.version' "$CONFIG_FILE")
echo -e "${BLUE}📌 Version: $VERSION${NC}"
echo ""

# Function to publish to PyPI
publish_pypi() {
    echo -e "${YELLOW}📦 Publishing to PyPI...${NC}"
    
    # Check if setup.py exists
    if [ ! -f "setup.py" ]; then
        echo -e "${RED}❌ setup.py not found. Run setup first.${NC}"
        return 1
    fi
    
    # Clean old builds
    rm -rf dist/ build/ *.egg-info
    
    # Build
    python3 setup.py sdist bdist_wheel
    
    # Upload
    python3 -m twine upload dist/*
    
    echo -e "${GREEN}✅ Published to PyPI${NC}"
}

# Function to update Homebrew
# Function to update Homebrew
publish_homebrew() {
    echo -e "${YELLOW}🍺 Updating Homebrew formula...${NC}"
    
    # Clone homebrew-timer repo
    rm -rf temp_homebrew_publish
    git clone https://github.com/dandaniel5/homebrew-timer.git temp_homebrew_publish
    
    # Copy formula
    if [ -f "Formula/timer.rb" ]; then
        cp Formula/timer.rb temp_homebrew_publish/timer.rb
        
        cd temp_homebrew_publish
        git add timer.rb
        git commit -m "Update to version $VERSION" || echo "No changes to commit"
        git push
        cd ..
        rm -rf temp_homebrew_publish
        
        echo -e "${GREEN}✅ Homebrew formula updated${NC}"
    else
        echo -e "${RED}❌ Formula/timer.rb not found${NC}"
        return 1
    fi
}

# Function to publish to Snap
publish_snap() {
    echo -e "${YELLOW}📸 Publishing to Snap Store...${NC}"
    
    if [ ! -f "snap/snapcraft.yaml" ]; then
        echo -e "${RED}❌ snapcraft.yaml not found${NC}"
        return 1
    fi
    
    snapcraft
    snapcraft upload --release=stable *.snap
    
    echo -e "${GREEN}✅ Published to Snap Store${NC}"
}

# Function to publish to AUR
publish_aur() {
    echo -e "${YELLOW}🏛️  Publishing to AUR...${NC}"
    
    if [ ! -f "PKGBUILD" ]; then
        echo -e "${RED}❌ PKGBUILD not found${NC}"
        return 1
    fi
    
    # Update PKGBUILD and push to AUR
    makepkg --printsrcinfo > .SRCINFO
    git add PKGBUILD .SRCINFO
    git commit -m "Update to version $VERSION"
    git push
    
    echo -e "${GREEN}✅ Published to AUR${NC}"
}

# Function to publish to Winget
publish_winget() {
    echo -e "${YELLOW}🪟 Creating Winget manifest...${NC}"
    
    echo -e "${BLUE}ℹ️  Winget requires manual PR to microsoft/winget-pkgs${NC}"
    echo -e "${BLUE}   Manifest will be created in winget/ directory${NC}"
    
    # Create manifest (simplified)
    mkdir -p winget
    cat > winget/DanilKodolov.MinimalTimer.yaml <<EOF
PackageIdentifier: DanilKodolov.MinimalTimer
PackageVersion: $VERSION
PackageName: Minimal Timer
Publisher: Danil Kodolov
License: MIT
ShortDescription: A minimalist command-line timer
PackageUrl: https://github.com/dandaniel5/minimal-timer
Installers:
  - Architecture: x64
    InstallerType: portable
    InstallerUrl: https://github.com/dandaniel5/minimal-timer/releases/download/v$VERSION/timer.py
EOF
    
    echo -e "${GREEN}✅ Winget manifest created${NC}"
}

# Function to publish to Chocolatey
publish_chocolatey() {
    echo -e "${YELLOW}🍫 Publishing to Chocolatey...${NC}"
    
    if [ ! -f "minimal-timer.nuspec" ]; then
        echo -e "${RED}❌ .nuspec file not found${NC}"
        return 1
    fi
    
    choco pack
    choco push minimal-timer.*.nupkg --source https://push.chocolatey.org/
    
    echo -e "${GREEN}✅ Published to Chocolatey${NC}"
}

# Main publishing logic
publish_all() {
    local managers=$(jq -r '.managers | to_entries[] | select(.value.enabled == true) | .key' "$CONFIG_FILE")
    
    for manager in $managers; do
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
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
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✨ Publishing complete!${NC}"
}

# Check for required tools
check_dependencies() {
    local missing=()
    
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    command -v python3 >/dev/null 2>&1 || missing+=("python3")
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}❌ Missing dependencies: ${missing[*]}${NC}"
        echo -e "${YELLOW}Install with: brew install ${missing[*]}${NC}"
        exit 1
    fi
}

# Main execution
main() {
    check_dependencies
    
    echo -e "${YELLOW}⚠️  This will publish to ALL enabled package managers.${NC}"
    echo -e "${YELLOW}   Make sure you have proper credentials configured.${NC}"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Cancelled${NC}"
        exit 1
    fi
    
    publish_all
}

main "$@"
