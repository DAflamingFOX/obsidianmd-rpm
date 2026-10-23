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

## License

The files in this repository are licensed under the **MIT License**.

> [!IMPORTANT]
> [Obsidian](https://obsidian.md/) is proprietary software.
> The resulting RPM packages contain proprietary binaries that are subject to the [Obsidian's EULA](https://obsidian.md/eula).
> This project is not affiliated with, funded by, or officially associated with Obsidian in any capacity.
