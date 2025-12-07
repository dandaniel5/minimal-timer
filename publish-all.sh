#!/bin/bash

# 🚀 Multi-Platform Publishing Script
# Publishes minimal-timer to all enabled package managers

set -e  # Exit on error



SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/package-managers.json"

echo "╔════════════════════════════════════════╗"
echo "║  📦 Multi-Platform Publisher          ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

# Read version from config
VERSION=$(jq -r '.version' "$CONFIG_FILE")
echo "📌 Version: $VERSION"
echo ""

# Function to publish to PyPI
publish_pypi() {
    echo "📦 Publishing to PyPI..."
    
    # Check if setup.py exists
    if [ ! -f "setup.py" ]; then
        echo "❌ setup.py not found. Run setup first."
        return 1
    fi
    
    # Clean old builds
    rm -rf dist/ build/ *.egg-info
    
    # Build
    python3 setup.py sdist bdist_wheel
    
    # Upload
    python3 -m twine upload dist/*
    
    echo "✅ Published to PyPI"
}

# Function to update Homebrew
# Function to update Homebrew
publish_homebrew() {
    echo "🍺 Updating Homebrew formula..."
    
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
        
        echo "✅ Homebrew formula updated"
    else
        echo "❌ Formula/timer.rb not found"
        return 1
    fi
}

# Function to publish to Snap
publish_snap() {
    echo "📸 Publishing to Snap Store..."
    
    if [ ! -f "snap/snapcraft.yaml" ]; then
        echo "❌ snapcraft.yaml not found"
        return 1
    fi
    
    snapcraft
    snapcraft upload --release=stable *.snap
    
    echo "✅ Published to Snap Store"
}

# Function to publish to AUR
publish_aur() {
    echo "🏛️  Publishing to AUR..."
    
    if [ ! -f "PKGBUILD" ]; then
        echo "❌ PKGBUILD not found"
        return 1
    fi
    
    # Update PKGBUILD and push to AUR
    makepkg --printsrcinfo > .SRCINFO
    git add PKGBUILD .SRCINFO
    git commit -m "Update to version $VERSION"
    git push
    
    echo "✅ Published to AUR"
}

# Function to publish to Winget
publish_winget() {
    echo "🪟 Creating Winget manifest..."
    
    echo "ℹ️  Winget requires manual PR to microsoft/winget-pkgs"
    echo "   Manifest will be created in winget/ directory"
    
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
    
    echo "✅ Winget manifest created"
}

# Function to publish to Chocolatey
publish_chocolatey() {
    echo "🍫 Publishing to Chocolatey..."
    
    if [ ! -f "minimal-timer.nuspec" ]; then
        echo "❌ .nuspec file not found"
        return 1
    fi
    
    choco pack
    choco push minimal-timer.*.nupkg --source https://push.chocolatey.org/
    
    echo "✅ Published to Chocolatey"
}

# Main publishing logic
publish_all() {
    local managers=$(jq -r '.managers | to_entries[] | select(.value.enabled == true) | .key' "$CONFIG_FILE")
    
    for manager in $managers; do
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        case $manager in
            pypi)
                publish_pypi || echo "❌ Failed to publish to PyPI"
                ;;
            homebrew)
                publish_homebrew || echo "❌ Failed to update Homebrew"
                ;;
            snap)
                publish_snap || echo "❌ Failed to publish to Snap"
                ;;
            aur)
                publish_aur || echo "❌ Failed to publish to AUR"
                ;;
            winget)
                publish_winget || echo "❌ Failed to create Winget manifest"
                ;;
            chocolatey)
                publish_chocolatey || echo "❌ Failed to publish to Chocolatey"
                ;;
            *)
                echo "⚠️  $manager: Manual publishing required"
                ;;
        esac
    done
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✨ Publishing complete!"
}

# Check for required tools
check_dependencies() {
    local missing=()
    
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    command -v python3 >/dev/null 2>&1 || missing+=("python3")
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo "❌ Missing dependencies: ${missing[*]}"
        echo "Install with: brew install ${missing[*]}"
        exit 1
    fi
}

# Main execution
main() {
    check_dependencies
    
    echo "⚠️  This will publish to ALL enabled package managers."
    echo "   Make sure you have proper credentials configured."
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled"
        exit 1
    fi
    
    publish_all
}

main "$@"
