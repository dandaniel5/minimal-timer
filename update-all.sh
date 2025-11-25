#!/bin/bash

# 🔄 Multi-Platform Update Script
# Updates version across all package managers

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/package-managers.json"

echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║  🔄 Multi-Platform Updater            ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
echo ""

# Get current version
CURRENT_VERSION=$(jq -r '.version' "$CONFIG_FILE")
echo -e "${BLUE}📌 Current version: $CURRENT_VERSION${NC}"
echo ""

# Ask for new version
read -p "Enter new version (e.g., 1.0.1): " NEW_VERSION

if [ -z "$NEW_VERSION" ]; then
    echo -e "${RED}❌ Version cannot be empty${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🔄 Updating from $CURRENT_VERSION to $NEW_VERSION${NC}"
echo ""

# Update config file
update_config() {
    echo -e "${BLUE}📝 Updating package-managers.json...${NC}"
    jq ".version = \"$NEW_VERSION\"" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo -e "${GREEN}✅ Config updated${NC}"
}

# Update setup.py
update_setup_py() {
    if [ -f "setup.py" ]; then
        echo -e "${BLUE}📝 Updating setup.py...${NC}"
        sed -i.bak "s/version=\"[^\"]*\"/version=\"$NEW_VERSION\"/" setup.py
        rm -f setup.py.bak
        echo -e "${GREEN}✅ setup.py updated${NC}"
    fi
}

# Update Homebrew formula
update_homebrew() {
    if [ -d "Formula" ]; then
        echo -e "${BLUE}📝 Updating Homebrew formula...${NC}"
        FORMULA_FILE=$(find Formula -name "*.rb" | head -n 1)
        if [ -f "$FORMULA_FILE" ]; then
            sed -i.bak "s/version \"[^\"]*\"/version \"$NEW_VERSION\"/" "$FORMULA_FILE"
            rm -f "$FORMULA_FILE.bak"
            echo -e "${GREEN}✅ Homebrew formula updated${NC}"
        fi
    fi
}

# Update snapcraft.yaml
update_snap() {
    if [ -f "snap/snapcraft.yaml" ]; then
        echo -e "${BLUE}📝 Updating snapcraft.yaml...${NC}"
        sed -i.bak "s/version: '[^']*'/version: '$NEW_VERSION'/" snap/snapcraft.yaml
        rm -f snap/snapcraft.yaml.bak
        echo -e "${GREEN}✅ snapcraft.yaml updated${NC}"
    fi
}

# Update PKGBUILD (AUR)
update_aur() {
    if [ -f "PKGBUILD" ]; then
        echo -e "${BLUE}📝 Updating PKGBUILD...${NC}"
        sed -i.bak "s/pkgver=[^ ]*/pkgver=$NEW_VERSION/" PKGBUILD
        rm -f PKGBUILD.bak
        echo -e "${GREEN}✅ PKGBUILD updated${NC}"
    fi
}

# Update package.json (if using npm)
update_npm() {
    if [ -f "package.json" ]; then
        echo -e "${BLUE}📝 Updating package.json...${NC}"
        jq ".version = \"$NEW_VERSION\"" package.json > package.json.tmp
        mv package.json.tmp package.json
        echo -e "${GREEN}✅ package.json updated${NC}"
    fi
}

# Update Chocolatey nuspec
update_chocolatey() {
    if [ -f "minimal-timer.nuspec" ]; then
        echo -e "${BLUE}📝 Updating .nuspec...${NC}"
        sed -i.bak "s/<version>[^<]*<\\/version>/<version>$NEW_VERSION<\\/version>/" minimal-timer.nuspec
        rm -f minimal-timer.nuspec.bak
        echo -e "${GREEN}✅ .nuspec updated${NC}"
    fi
}

# Update Debian control file
update_debian() {
    if [ -f "debian/control" ]; then
        echo -e "${BLUE}📝 Updating debian/control...${NC}"
        sed -i.bak "s/Version: [^ ]*/Version: $NEW_VERSION/" debian/control
        rm -f debian/control.bak
        echo -e "${GREEN}✅ debian/control updated${NC}"
    fi
}

# Update RPM spec file
update_rpm() {
    if [ -f "minimal-timer.spec" ]; then
        echo -e "${BLUE}📝 Updating .spec file...${NC}"
        sed -i.bak "s/Version: [^ ]*/Version: $NEW_VERSION/" minimal-timer.spec
        rm -f minimal-timer.spec.bak
        echo -e "${GREEN}✅ .spec file updated${NC}"
    fi
}

# Update timer.py
update_timer_py() {
    if [ -f "timer.py" ]; then
        echo -e "${BLUE}📝 Updating timer.py...${NC}"
        sed -i.bak "s/__version__ = \"[^\"]*\"/__version__ = \"$NEW_VERSION\"/" timer.py
        rm -f timer.py.bak
        echo -e "${GREEN}✅ timer.py updated${NC}"
    fi
}

# Update minimal-timer.html
update_html() {
    if [ -f "minimal-timer.html" ]; then
        echo -e "${BLUE}📝 Updating minimal-timer.html...${NC}"
        sed -i.bak "s/v[0-9]\+\.[0-9]\+\.[0-9]\+/v$NEW_VERSION/" minimal-timer.html
        rm -f minimal-timer.html.bak
        echo -e "${GREEN}✅ minimal-timer.html updated${NC}"
    fi
}

# Update documentation
update_docs() {
    echo -e "${BLUE}📝 Updating documentation...${NC}"
    
    # Update PUBLISHING.md (carefully)
    if [ -f "PUBLISHING.md" ]; then
        # Update JSON examples
        sed -i.bak "s/\"version\": \"[0-9]\+\.[0-9]\+\.[0-9]\+\"/\"version\": \"$NEW_VERSION\"/" PUBLISHING.md
        # Update URL examples
        sed -i.bak "s/v[0-9]\+\.[0-9]\+\.[0-9]\+\/timer/v$NEW_VERSION\/timer/" PUBLISHING.md
        rm -f PUBLISHING.md.bak
    fi
    
    echo -e "${GREEN}✅ Documentation updated${NC}"
}

# Git tag and commit
git_update() {
    echo -e "${BLUE}📝 Creating git commit and tag...${NC}"
    
    git add .
    git commit -m "Bump version to $NEW_VERSION" || echo -e "${YELLOW}⚠️  No changes to commit${NC}"
    git tag -a "v$NEW_VERSION" -m "Version $NEW_VERSION"
    
    echo -e "${GREEN}✅ Git tag created${NC}"
    echo -e "${YELLOW}💡 Don't forget to: git push && git push --tags${NC}"
}

# Summary of updates
show_summary() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✨ Version Update Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Old version: ${RED}$CURRENT_VERSION${NC}"
    echo -e "  New version: ${GREEN}$NEW_VERSION${NC}"
    echo ""
    echo -e "${YELLOW}📦 Updated files:${NC}"
    
    [ -f "$CONFIG_FILE" ] && echo -e "  ✅ package-managers.json"
    [ -f "setup.py" ] && echo -e "  ✅ setup.py"
    [ -d "Formula" ] && echo -e "  ✅ Homebrew formula"
    [ -f "snap/snapcraft.yaml" ] && echo -e "  ✅ snapcraft.yaml"
    [ -f "PKGBUILD" ] && echo -e "  ✅ PKGBUILD"
    [ -f "package.json" ] && echo -e "  ✅ package.json"
    [ -f "minimal-timer.nuspec" ] && echo -e "  ✅ .nuspec"
    [ -f "debian/control" ] && echo -e "  ✅ debian/control"
    [ -f "minimal-timer.spec" ] && echo -e "  ✅ .spec"
    [ -f "timer.py" ] && echo -e "  ✅ timer.py"
    [ -f "minimal-timer.html" ] && echo -e "  ✅ minimal-timer.html"
    
    echo ""
    echo -e "${YELLOW}📋 Next steps:${NC}"
    echo -e "  1. Review changes: ${BLUE}git diff${NC}"
    echo -e "  2. Push to git: ${BLUE}git push && git push --tags${NC}"
    echo -e "  3. Publish: ${BLUE}./publish-all.sh${NC}"
    echo ""
}

# Main execution
main() {
    echo -e "${YELLOW}⚠️  This will update version in ALL package manager files.${NC}"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Cancelled${NC}"
        exit 1
    fi
    
    echo ""
    
    # Update all files
    update_config
    update_setup_py
    update_homebrew
    update_snap
    update_aur
    update_npm
    update_chocolatey
    update_debian
    update_rpm
    update_timer_py
    update_html
    update_docs
    git_update
    
    show_summary
}

main "$@"
