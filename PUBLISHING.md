# 🚀 Multi-Platform Publishing Guide

This guide explains how to use the automated publishing scripts for distributing `minimal-timer` across multiple package managers.

## 📁 Files Created

### 1. **package-managers.json**
Configuration file containing:
- Version number
- Package metadata
- List of all package managers
- Platform support info
- Publishing status

### 2. **publish-all.sh**
Automated publishing script that:
- ✅ Publishes to PyPI
- ✅ Updates Homebrew formula
- ✅ Publishes to Snap Store
- ✅ Publishes to AUR (Arch)
- ✅ Creates Winget manifest
- ✅ Publishes to Chocolatey
- 📝 Provides instructions for manual platforms

### 3. **update-all.sh**
Version update script that:
- 🔄 Updates version in all config files
- 📝 Updates setup.py, PKGBUILD, snapcraft.yaml, etc.
- 🏷️ Creates git tag
- 📊 Shows summary of changes

### 4. **setup.py**
PyPI package configuration for `pip install minimal-timer`

---

## 🎯 Quick Start

### Update Version
```bash
./update-all.sh
# Enter new version when prompted (e.g., 1.0.1)
# Review changes
git push && git push --tags
```

### Publish to All Platforms
```bash
./publish-all.sh
# Confirm when prompted
# Script will publish to all enabled platforms
```

---

## 📦 Supported Package Managers

| Platform | Package Manager | Status | Install Command |
|----------|----------------|--------|-----------------|
| 🍎 macOS/Linux | **Homebrew** | ✅ Published | `brew install dandaniel5/timer/timer` |
| 🐍 Universal | **PyPI** | 🔜 Ready | `pip install minimal-timer` |
| 🐧 Linux | **Snap** | 🔜 Ready | `snap install minimal-timer` |
| 🏛️ Arch Linux | **AUR** | 🔜 Ready | `yay -S minimal-timer` |
| 🪟 Windows | **Winget** | 🔜 Ready | `winget install DanilKodolov.MinimalTimer` |
| 🍫 Windows | **Chocolatey** | 🔜 Ready | `choco install minimal-timer` |
| 🪣 Windows | **Scoop** | 🔜 Ready | `scoop install minimal-timer` |
| 📦 Linux | **Flatpak** | 🔜 Ready | `flatpak install minimal-timer` |
| 📦 Debian/Ubuntu | **APT** | 🔜 Ready | `apt install minimal-timer` |
| 📦 Fedora/RHEL | **RPM** | 🔜 Ready | `dnf install minimal-timer` |
| ❄️ NixOS | **Nix** | 🔜 Ready | `nix-env -iA nixpkgs.minimal-timer` |
| 🐡 FreeBSD | **Ports** | 🔜 Ready | `pkg install minimal-timer` |

---

## 🔧 Setup Requirements

### Install Dependencies
```bash
# macOS
brew install jq python3

# Install Python packaging tools
pip3 install twine setuptools wheel
```

### Configure Credentials

Below are detailed setup instructions for each package manager with API keys and authentication.

---

#### 🐍 PyPI (Python Package Index)

**Priority: HIGH** - Most universal platform

1. **Create account**
   - Go to https://pypi.org/account/register/
   - Fill in username, email, password
   - Verify email

2. **Generate API Token**
   - Login to https://pypi.org
   - Go to Account Settings → API tokens
   - Click "Add API token"
   - Token name: `minimal-timer` (or any name)
   - Scope: Choose "Entire account" (or specific project after first upload)
   - Click "Add token"
   - **COPY THE TOKEN NOW** (starts with `pypi-...`) - you won't see it again!

3. **Configure credentials**
   ```bash
   cat > ~/.pypirc <<EOF
   [pypi]
   username = __token__
   password = pypi-YOUR-COPIED-TOKEN-HERE
   EOF
   
   chmod 600 ~/.pypirc
   ```

4. **Test**
   ```bash
   python3 -m twine check dist/*
   ```

**Documentation**: https://pypi.org/help/#apitoken

---

#### 🍺 Homebrew

**Already configured!** ✅ You have the Formula repository set up.

To update:
```bash
cd Formula
git add .
git commit -m "Update version"
git push
```

**Documentation**: https://docs.brew.sh/How-To-Open-a-Homebrew-Pull-Request

---

#### 📸 Snap Store (Ubuntu/Linux)

**Priority: MEDIUM** - Great for Linux users

1. **Create Ubuntu One account**
   - Go to https://login.ubuntu.com/
   - Click "I don't have an Ubuntu One account"
   - Fill in details and verify email

2. **Register as Snap developer**
   - Go to https://snapcraft.io/account
   - Login with Ubuntu One account
   - Accept developer agreement

3. **Login via CLI**
   ```bash
   # Install snapcraft (on macOS)
   brew install snapcraft
   
   # Login
   snapcraft login
   # Enter your Ubuntu One email and password
   ```

4. **Register snap name**
   ```bash
   snapcraft register minimal-timer
   ```

5. **Export credentials (optional, for CI/CD)**
   ```bash
   snapcraft export-login --snaps=minimal-timer --channels=stable credentials.txt
   ```

**Documentation**: https://snapcraft.io/docs/snapcraft-authentication

---

#### 🏛️ AUR (Arch User Repository)

**Priority: MEDIUM** - Popular among Arch users

1. **Create AUR account**
   - Go to https://aur.archlinux.org/register
   - Fill in username, email, password
   - Verify email

2. **Setup SSH key**
   ```bash
   # Generate SSH key if you don't have one
   ssh-keygen -t ed25519 -C "dan.daniels110@gmail.com"
   
   # Copy public key
   cat ~/.ssh/id_ed25519.pub
   ```

3. **Add SSH key to AUR**
   - Login to https://aur.archlinux.org
   - Go to "My Account"
   - Paste SSH public key in "SSH Public Key" section
   - Click "Update"

4. **Clone AUR repository**
   ```bash
   git clone ssh://aur@aur.archlinux.org/minimal-timer.git
   cd minimal-timer
   # Create PKGBUILD file
   git add PKGBUILD
   makepkg --printsrcinfo > .SRCINFO
   git add .SRCINFO
   git commit -m "Initial commit"
   git push
   ```

**Documentation**: https://wiki.archlinux.org/title/AUR_submission_guidelines

---

#### 🪟 Winget (Windows Package Manager)

**Priority: HIGH** - Official Windows package manager

**No API key needed** - uses GitHub Pull Requests

1. **Fork winget-pkgs repository**
   - Go to https://github.com/microsoft/winget-pkgs
   - Click "Fork"

2. **Create manifest**
   ```bash
   # Script creates manifest in winget/ directory
   ./release.sh
   ```

3. **Submit via PR**
   - Clone your fork
   - Copy manifest to `manifests/d/DanilKodolov/MinimalTimer/<version>/`
   - Commit and push
   - Create Pull Request to microsoft/winget-pkgs

4. **Automated validation**
   - Microsoft's bot will validate your manifest
   - Fix any issues if needed
   - Once approved, package is published

**Documentation**: https://github.com/microsoft/winget-pkgs/blob/master/CONTRIBUTING.md

---

#### 🍫 Chocolatey (Windows)

**Priority: MEDIUM** - Popular Windows package manager

1. **Create account**
   - Go to https://community.chocolatey.org/account/Register
   - Fill in details and verify email

2. **Get API Key**
   - Login to https://community.chocolatey.org
   - Go to "My Account" → "API Keys"
   - Copy your API key

3. **Configure API key**
   ```bash
   choco apikey --key YOUR-API-KEY-HERE --source https://push.chocolatey.org/
   ```

4. **Create package**
   ```bash
   # Create .nuspec file
   choco pack
   choco push minimal-timer.1.0.0.nupkg --source https://push.chocolatey.org/
   ```

**Documentation**: https://docs.chocolatey.org/en-us/create/create-packages

---

#### 🪣 Scoop (Windows)

**Priority: LOW** - Alternative Windows package manager

**No API key needed** - uses GitHub repository

1. **Create Scoop bucket repository**
   - Create new GitHub repo: `scoop-bucket`
   - Add JSON manifest file

2. **Create manifest**
   ```json
   {
     "version": "1.0.0",
     "description": "Minimal command-line timer",
     "homepage": "https://github.com/dandaniel5/minimal-timer",
     "license": "MIT",
     "url": "https://github.com/dandaniel5/minimal-timer/releases/download/v1.0.0/timer",
     "bin": "timer"
   }
   ```

3. **Users install via**
   ```bash
   scoop bucket add dandaniel5 https://github.com/dandaniel5/scoop-bucket
   scoop install minimal-timer
   ```

**Documentation**: https://github.com/ScoopInstaller/Scoop/wiki/Buckets

---

#### 📦 Flatpak (Linux Universal)

**Priority: MEDIUM** - Works on all Linux distros

1. **Create Flathub account**
   - Go to https://github.com/flathub/flathub
   - Fork the repository

2. **Create app manifest**
   ```yaml
   # io.github.dandaniel5.MinimalTimer.yml
   app-id: io.github.dandaniel5.MinimalTimer
   runtime: org.freedesktop.Platform
   runtime-version: '23.08'
   sdk: org.freedesktop.Sdk
   command: timer
   ```

3. **Submit to Flathub**
   - Create PR to https://github.com/flathub/flathub
   - Flathub team reviews and publishes

**Documentation**: https://docs.flathub.org/docs/for-app-authors/submission

---

#### 📦 APT (Debian/Ubuntu)

**Priority: LOW** - Requires PPA or official inclusion

**Option 1: Personal Package Archive (PPA)**

1. **Create Launchpad account**
   - Go to https://launchpad.net/
   - Create account

2. **Create PPA**
   - Go to https://launchpad.net/~/+activate-ppa
   - Name: `minimal-timer`

3. **Upload package**
   ```bash
   # Build .deb package
   dpkg-deb --build minimal-timer
   
   # Upload to PPA
   dput ppa:yourusername/minimal-timer minimal-timer_1.0.0_source.changes
   ```

**Option 2: Submit to Debian/Ubuntu**
- More complex, requires Debian Developer status
- See: https://wiki.debian.org/DebianMentorsFaq

---

#### 📦 RPM (Fedora/RHEL)

**Priority: LOW** - Requires Fedora account

1. **Create Fedora account**
   - Go to https://accounts.fedoraproject.org/
   - Create account

2. **Join packagers group**
   - Apply at https://fedoraproject.org/wiki/Join_the_package_collection_maintainers

3. **Create spec file**
   ```bash
   # minimal-timer.spec
   rpmbuild -ba minimal-timer.spec
   ```

**Documentation**: https://docs.fedoraproject.org/en-US/package-maintainers/

---

#### ❄️ Nix/NixOS

**Priority: LOW** - Growing community

**No API key needed** - uses GitHub PR

1. **Fork nixpkgs**
   - Go to https://github.com/NixOS/nixpkgs
   - Click "Fork"

2. **Create package**
   ```nix
   # pkgs/tools/misc/minimal-timer/default.nix
   { lib, python3Packages }:
   python3Packages.buildPythonApplication {
     pname = "minimal-timer";
     version = "1.0.0";
     # ... package definition
   }
   ```

3. **Submit PR**
   - Commit and push to your fork
   - Create PR to nixpkgs

**Documentation**: https://nixos.org/manual/nixpkgs/stable/#chap-quick-start

---

#### 🐡 FreeBSD Ports

**Priority: LOW** - BSD users

1. **Create FreeBSD account**
   - Go to https://bugs.freebsd.org/
   - Create account

2. **Submit port**
   - Create Makefile and pkg-descr
   - Submit via https://bugs.freebsd.org/

**Documentation**: https://docs.freebsd.org/en/books/porters-handbook/

---

#### 📦 npm (Optional - Node.js wrapper)

**Priority: LOW** - Only if you want Node.js users

1. **Create npm account**
   - Go to https://www.npmjs.com/signup
   - Verify email

2. **Login via CLI**
   ```bash
   npm login
   ```

3. **Publish**
   ```bash
   npm publish
   ```

**Documentation**: https://docs.npmjs.com/creating-and-publishing-scoped-public-packages

---

## 📝 Detailed Usage

### Publishing to PyPI (Recommended First)

1. **Setup PyPI account**
   - Register at https://pypi.org
   - Generate API token
   - Add to `~/.pypirc`

2. **Test locally**
   ```bash
   python3 setup.py sdist bdist_wheel
   python3 -m twine check dist/*
   ```

3. **Publish**
   ```bash
   ./publish-all.sh
   # Or manually:
   python3 -m twine upload dist/*
   ```

4. **Install and test**
   ```bash
   pip install minimal-timer
   timer 5m
   ```

### Publishing to Snap Store

1. **Create snapcraft.yaml**
   ```bash
   mkdir -p snap
   # Create snap/snapcraft.yaml (see template below)
   ```

2. **Build and publish**
   ```bash
   snapcraft
   snapcraft login
   snapcraft upload --release=stable *.snap
   ```

### Publishing to AUR (Arch Linux)

1. **Create PKGBUILD**
   ```bash
   # See AUR documentation
   # Template provided in aur/ directory
   ```

2. **Publish**
   ```bash
   makepkg --printsrcinfo > .SRCINFO
   git add PKGBUILD .SRCINFO
   git commit -m "Initial commit"
   git push
   ```

### Publishing to Winget (Windows)

1. **Create manifest**
   ```bash
   ./publish-all.sh  # Creates winget/ directory
   ```

2. **Submit PR**
   - Fork https://github.com/microsoft/winget-pkgs
   - Add manifest to `manifests/d/DanilKodolov/MinimalTimer/`
   - Create pull request

---

## 🔄 Version Update Workflow

```bash
# 1. Update version everywhere
./update-all.sh
# Enter: 1.0.1

# 2. Review changes
git diff

# 3. Push to GitHub
git push && git push --tags

# 4. Publish to all platforms
./publish-all.sh

# 5. Verify installations
pip install minimal-timer --upgrade
brew upgrade timer
```

---

## 🎨 Customization

### Enable/Disable Package Managers

Edit `package-managers.json`:
```json
{
  "managers": {
    "npm": {
      "enabled": false,  // Change to true to enable
      ...
    }
  }
}
```

### Add New Package Manager

1. Add to `package-managers.json`:
```json
"new_manager": {
  "enabled": true,
  "priority": 14,
  "package_name": "minimal-timer",
  "platforms": ["Linux"],
  "status": "not_published"
}
```

2. Add function to `publish-all.sh`:
```bash
publish_new_manager() {
    echo -e "${YELLOW}📦 Publishing to New Manager...${NC}"
    # Your publishing logic here
    echo -e "${GREEN}✅ Published${NC}"
}
```

---

## 🐛 Troubleshooting

### PyPI Upload Fails
```bash
# Check credentials
cat ~/.pypirc

# Test with TestPyPI first
python3 -m twine upload --repository testpypi dist/*
```

### Snap Build Fails
```bash
# Clean and rebuild
snapcraft clean
snapcraft
```

### Permission Denied
```bash
# Make scripts executable
chmod +x publish-all.sh update-all.sh
```

---

## 📊 Publishing Checklist

- [ ] Update version with `./update-all.sh`
- [ ] Review and test changes locally
- [ ] Push to GitHub with tags
- [ ] Run `./publish-all.sh`
- [ ] Verify PyPI: `pip install minimal-timer --upgrade`
- [ ] Verify Homebrew: `brew upgrade timer`
- [ ] Update README with new version
- [ ] Create GitHub release
- [ ] Announce on social media

---

## 🔗 Useful Links

- **PyPI**: https://pypi.org/project/minimal-timer/
- **Homebrew**: https://github.com/dandaniel5/homebrew-timer
- **GitHub**: https://github.com/dandaniel5/minimal-timer
- **Snap Store**: https://snapcraft.io/minimal-timer
- **AUR**: https://aur.archlinux.org/packages/minimal-timer

---

## 💡 Tips

1. **Always test locally first** before publishing
2. **Use semantic versioning**: MAJOR.MINOR.PATCH
3. **Keep changelog updated** in README.md
4. **Test on multiple platforms** if possible
5. **Monitor package manager dashboards** for issues

---

**Created by**: Danil Kodolov  
**License**: GPL-3.0
