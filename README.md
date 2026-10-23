# Obsidian RPM Repository

[![Build and Publish Obsidian RPM](https://github.com/DAflamingFOX/obsidianmd-rpm/actions/workflows/build-rpm.yaml/badge.svg)](https://github.com/DAflamingFOX/obsidianmd-rpm/actions/workflows/build-rpm.yaml)

This repository provides an automated build pipeline that tracks new releases of [Obsidian.md](https://obsidian.md/), packages the official `.tar.gz` Linux release into an RPM, and hosts it as a standard package repository using GitHub Pages.

This allows Fedora, RHEL, CentOS, and openSUSE users to install and update Obsidian using their native package managers.

## Installation

### Method 1: Bootstrap RPM Package (Recommended)

Install the repository bootstrap package directly with `dnf`:

```bash
sudo dnf install https://daflamingfox.github.io/obsidianmd-rpm/obsidian-repo.rpm
sudo dnf install obsidian
```

This installs the repository definition into `/etc/yum.repos.d/obsidian.repo` and the GPG public key into `/etc/pki/rpm-gpg/RPM-GPG-KEY-obsidian`.

### Method 2: Manual Repository Configuration

Alternatively, download the `.repo` configuration file directly:

```bash
sudo curl -sLo /etc/yum.repos.d/obsidian.repo https://daflamingfox.github.io/obsidianmd-rpm/obsidian.repo
sudo dnf install obsidian
```

Or manually create `/etc/yum.repos.d/obsidian.repo` with the following configuration:

```ini
[obsidian]
name=Obsidian Repository
baseurl=https://daflamingfox.github.io/obsidianmd-rpm/x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://daflamingfox.github.io/obsidianmd-rpm/RPM-GPG-KEY-obsidian
```

Then install Obsidian:

```bash
sudo dnf install obsidian
```

Updates to Obsidian will be handled automatically whenever you run standard system updates (`sudo dnf upgrade`).

## Maintainer Setup: GPG Signing

Repository packages and metadata are signed using GPG. To configure automated signing in GitHub Actions:

1. Generate a GPG key pair (if not already created):
   ```bash
   gpg --quick-gen-key "Obsidian Packaging <packaging@example.com>" default default never
   ```
2. Export the ASCII-armored private key:
   ```bash
   gpg --armor --export-secret-keys <KEY_ID>
   ```
3. In GitHub, navigate to **Settings** &rarr; **Secrets and variables** &rarr; **Actions** and add the following repository secrets:
   - `GPG_PRIVATE_KEY`: The exported ASCII-armored private key.
   - `GPG_KEY_ID`: *(Optional)* The key ID or fingerprint. If omitted, the build pipeline automatically detects it from the imported key.
   - `GPG_PASSPHRASE`: *(Optional)* The passphrase for the private key (required if the key was created with a passphrase).

> [!NOTE]
> If `GPG_PRIVATE_KEY` is not set, the build pipeline gracefully falls back to generating unsigned metadata with `gpgcheck=0`, ensuring builds do not fail while GPG keys are being configured.

## License

The files in this repository are licensed under the **MIT License**.

> [!IMPORTANT]
> [Obsidian](https://obsidian.md/) is proprietary software.
> The resulting RPM packages contain proprietary binaries that are subject to the [Obsidian's EULA](https://obsidian.md/eula).
> This project is not affiliated with, funded by, or officially associated with Obsidian in any capacity.
