#!/bin/bash

# 🔄 Multi-Platform Update Script
# Updates version across all package managers

set -e



SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/package-managers.json"

echo "╔════════════════════════════════════════╗"
echo "║  🔄 Multi-Platform Updater            ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Get current version
CURRENT_VERSION=$(jq -r '.version' "$CONFIG_FILE")
echo "📌 Current version: $CURRENT_VERSION"
echo ""

# Ask for new version
read -p "Enter new version (e.g., 1.0.1): " NEW_VERSION

if [ -z "$NEW_VERSION" ]; then
    echo "❌ Version cannot be empty"
    exit 1
fi

echo ""
echo "🔄 Updating from $CURRENT_VERSION to $NEW_VERSION"
echo ""

# Update config file
update_config() {
    echo "📝 Updating package-managers.json..."
    jq ".version = \"$NEW_VERSION\"" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo "✅ Config updated"
}

# Update setup.py
update_setup_py() {
    if [ -f "setup.py" ]; then
        echo "📝 Updating setup.py..."
        sed -i.bak "s/version=\"[^\"]*\"/version=\"$NEW_VERSION\"/" setup.py
        rm -f setup.py.bak
        echo "✅ setup.py updated"
    fi
}

# Update Homebrew formula
update_homebrew() {
    if [ -d "Formula" ]; then
        echo "📝 Updating Homebrew formula..."
        FORMULA_FILE=$(find Formula -name "*.rb" | head -n 1)
        if [ -f "$FORMULA_FILE" ]; then
            sed -i.bak "s|url \".*\"|url \"https://github.com/dandaniel5/minimal-timer/archive/refs/tags/v$NEW_VERSION.tar.gz\"|" "$FORMULA_FILE"
            # Note: SHA256 update requires downloading the file, which is complex here.
            # Ideally release.sh should handle this or we calculate it here.
            # For now, we'll just update the URL and let the user/release script handle SHA256?
            # Actually, let's try to calculate it if possible, or just leave it for manual update?
            # The current script structure makes it hard. Let's just update URL and warn.
            echo "⚠️  Homebrew formula URL updated. SHA256 must be updated manually or via release script."
            rm -f "$FORMULA_FILE.bak"
            echo "✅ Homebrew formula updated"
        fi
    fi
}

# Update snapcraft.yaml
update_snap() {
    if [ -f "snap/snapcraft.yaml" ]; then
        echo "📝 Updating snapcraft.yaml..."
        sed -i.bak "s/version: '[^']*'/version: '$NEW_VERSION'/" snap/snapcraft.yaml
        rm -f snap/snapcraft.yaml.bak
        echo "✅ snapcraft.yaml updated"
    fi
}

# Update PKGBUILD (AUR)
update_aur() {
    if [ -f "PKGBUILD" ]; then
        echo "📝 Updating PKGBUILD..."
        sed -i.bak "s/pkgver=[^ ]*/pkgver=$NEW_VERSION/" PKGBUILD
        rm -f PKGBUILD.bak
        echo "✅ PKGBUILD updated"
    fi
}

# Update package.json (if using npm)
update_npm() {
    if [ -f "package.json" ]; then
        echo "📝 Updating package.json..."
        jq ".version = \"$NEW_VERSION\"" package.json > package.json.tmp
        mv package.json.tmp package.json
        echo "✅ package.json updated"
    fi
}

# Update Chocolatey nuspec
update_chocolatey() {
    if [ -f "minimal-timer.nuspec" ]; then
        echo "📝 Updating .nuspec..."
        sed -i.bak "s/<version>[^<]*<\\/version>/<version>$NEW_VERSION<\\/version>/" minimal-timer.nuspec
        rm -f minimal-timer.nuspec.bak
        echo "✅ .nuspec updated"
    fi
}

# Update Debian control file
update_debian() {
    if [ -f "debian/control" ]; then
        echo "📝 Updating debian/control..."
        sed -i.bak "s/Version: [^ ]*/Version: $NEW_VERSION/" debian/control
        rm -f debian/control.bak
        echo "✅ debian/control updated"
    fi
}

# Update RPM spec file
update_rpm() {
    if [ -f "minimal-timer.spec" ]; then
        echo "📝 Updating .spec file..."
        sed -i.bak "s/Version: [^ ]*/Version: $NEW_VERSION/" minimal-timer.spec
        rm -f minimal-timer.spec.bak
        echo "✅ .spec file updated"
    fi
}

# Update timer.py
update_timer_py() {
    if [ -f "timer.py" ]; then
        echo "📝 Updating timer.py..."
        sed -i.bak "s/__version__ = \"[^\"]*\"/__version__ = \"$NEW_VERSION\"/" timer.py
        rm -f timer.py.bak
        echo "✅ timer.py updated"
    fi
}

# Update minimal-timer.html
update_html() {
    if [ -f "minimal-timer.html" ]; then
        echo "📝 Updating minimal-timer.html..."
        sed -i.bak "s/v[0-9]\+\.[0-9]\+\.[0-9]\+/v$NEW_VERSION/" minimal-timer.html
        rm -f minimal-timer.html.bak
        echo "✅ minimal-timer.html updated"
    fi
}

# Update documentation
update_docs() {
    echo "📝 Updating documentation..."
    
    # Update PUBLISHING.md (carefully)
    if [ -f "PUBLISHING.md" ]; then
        # Update JSON examples
        sed -i.bak "s/\"version\": \"[0-9]\+\.[0-9]\+\.[0-9]\+\"/\"version\": \"$NEW_VERSION\"/" PUBLISHING.md
        # Update URL examples
        sed -i.bak "s/v[0-9]\+\.[0-9]\+\.[0-9]\+\/timer/v$NEW_VERSION\/timer/" PUBLISHING.md
        rm -f PUBLISHING.md.bak
    fi
    
    echo "✅ Documentation updated"
}

# Git tag and commit
git_update() {
    echo "📝 Creating git commit and tag..."
    
    git add .
    git commit -m "Bump version to $NEW_VERSION" || echo "⚠️  No changes to commit"
    git tag -a "v$NEW_VERSION" -m "Version $NEW_VERSION"
    
    echo "✅ Git tag created"
    echo "💡 Don't forget to: git push && git push --tags"
}

# Summary of updates
show_summary() {
    echo ""
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✨ Version Update Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Old version: $CURRENT_VERSION"
    echo "  New version: $NEW_VERSION"
    echo ""
    echo "📦 Updated files:"
    
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
    echo ""
    echo "📋 Next steps:"
    echo "  1. Review changes: git diff"
    echo "  2. Push to git: git push && git push --tags"
    echo "  3. Publish: ./publish-all.sh"
    echo ""
}

# Main execution
main() {
    echo "⚠️  This will update version in ALL package manager files."
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled"
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
