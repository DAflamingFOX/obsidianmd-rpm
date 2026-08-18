# Obsidian RPM Repository

This repository provides an automated build pipeline that tracks new releases of [Obsidian.md](https://obsidian.md/), packages the official `.tar.gz` Linux release into an RPM, and hosts it as a standard package repository using GitHub Pages.

This allows Fedora, RHEL, CentOS, and openSUSE users to install and update Obsidian using their native package managers.

## How to Install Obsidian

1. Add the repository to your system

    Run the following command to create the repository file.

    ```bash
    echo -e "[obsidian]\nname=DAflamingFOX's Obsidian.md Repository\nbaseurl=https://daflamingfox.github.io/obsidianmd-rpm/x86_64/\nenabled=1\ngpgcheck=0" | sudo tee /etc/yum.repos.d/obsidian.repo
    ```

2. Install Obisidian

    Depending on your distribution's package manager, run the following commands:

    - **`dnf`** package manager

        ```bash
        sudo dnf update
        sudo dnf install obsidian
        ```
    - **`yum`** package manager


        ```bash
        sudo yum update
        sudo yum install obsidian
        ```

Updates to Obsidian will now be handled automatically whenever you run your standard system updates.

## License

The files in this repository are licensed under the **MIT License**.

> [!IMPORTANT]
> [Obsidian](https://obsidian.md/) is proprietary software.
> The resulting RPM packages contain proprietary binaries that are subject to the [Obsidian's EULA](https://obsidian.md/eula).
> This project is not affiliated with, funded by, or officially associated with Obsidian in any capacity.
