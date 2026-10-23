#!/usr/bin/env bash
set -euo pipefail

# Parameters
TARGET_DIR="${1:-public/x86_64}"
RPM_DIR="${2:-output/x86_64}"
PUBKEY_DEST="${3:-public/RPM-GPG-KEY-obsidian}"

PUB_ROOT="$(dirname "$PUBKEY_DEST")"
mkdir -p "$TARGET_DIR"
mkdir -p "$PUB_ROOT"

# Fallback defaults for repository metadata
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-DAflamingFOX/obsidianmd-rpm}"
if [ -z "${VERSION:-}" ] && [ -d "$RPM_DIR" ]; then
    VERSION=$(ls "$RPM_DIR"/obsidian-*.rpm 2>/dev/null | grep -oP 'obsidian-\K[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)
fi
VERSION="${VERSION:-1.7.7}"

# Check for GPG private key
if [ -n "${GPG_PRIVATE_KEY:-}" ]; then
    echo "=== GPG Signing Enabled ==="

    # Configure gpg and gpg-agent for headless, non-interactive signing
    GNUPG_DIR="${GNUPGHOME:-$HOME/.gnupg}"
    mkdir -p "$GNUPG_DIR"
    chmod 700 "$GNUPG_DIR"

    cat << 'EOF' > "$GNUPG_DIR/gpg-agent.conf"
allow-loopback-pinentry
allow-preset-passphrase
default-cache-ttl 34560000
max-cache-ttl 34560000
EOF
    chmod 600 "$GNUPG_DIR/gpg-agent.conf"

    cat << 'EOF' > "$GNUPG_DIR/gpg.conf"
use-agent
pinentry-mode loopback
batch
yes
EOF
    chmod 600 "$GNUPG_DIR/gpg.conf"

    # Reload agent configuration
    gpg-connect-agent reloadagent /bye >/dev/null 2>&1 || true

    echo "Importing GPG private key into keyring..."
    if [ -n "${GPG_PASSPHRASE:-}" ]; then
        echo "$GPG_PRIVATE_KEY" | gpg --batch --pinentry-mode loopback --passphrase "$GPG_PASSPHRASE" --import
    else
        echo "$GPG_PRIVATE_KEY" | gpg --batch --pinentry-mode loopback --import
    fi

    # Determine GPG key ID
    if [ -z "${GPG_KEY_ID:-}" ]; then
        GPG_KEY_ID=$(gpg --list-secret-keys --with-colons | grep '^sec:' | head -n 1 | cut -d: -f5)
    fi
    echo "Using GPG key ID: ${GPG_KEY_ID}"

    # Preset passphrase in gpg-agent if gpg-preset-passphrase is available
    PRESET_BIN="$(find /usr -name gpg-preset-passphrase 2>/dev/null | head -n 1 || true)"
    if [ -n "$PRESET_BIN" ] && [ -x "$PRESET_BIN" ]; then
        KEYGRIPS=$(gpg --with-colons --with-keygrip --list-secret-keys "${GPG_KEY_ID}" | grep "^grp:" | cut -d: -f10 || true)
        for grip in $KEYGRIPS; do
            "$PRESET_BIN" --preset -P "${GPG_PASSPHRASE:-}" "$grip" 2>/dev/null || true
        done
    fi

    # Verify key can sign data non-interactively
    TEST_SIGN_ARGS="--batch --yes --detach-sign --armor --pinentry-mode loopback --local-user ${GPG_KEY_ID}"
    if [ -n "${GPG_PASSPHRASE:-}" ]; then
        TEST_SIGN_ARGS="$TEST_SIGN_ARGS --passphrase ${GPG_PASSPHRASE}"
    fi
    if ! echo "gpg test" | gpg $TEST_SIGN_ARGS -o /dev/null 2>/dev/null; then
        echo "ERROR: Unable to sign test payload with GPG key ${GPG_KEY_ID}." >&2
        echo "If the key is protected by a passphrase, ensure GPG_PASSPHRASE is set in GitHub Secrets." >&2
        exit 1
    fi
    echo "GPG key ${GPG_KEY_ID} verified for headless signing."

    # Build rpmsign extra args
    RPM_GPG_EXTRA="--batch --yes --pinentry-mode loopback"
    if [ -n "${GPG_PASSPHRASE:-}" ]; then
        RPM_GPG_EXTRA="$RPM_GPG_EXTRA --passphrase \"${GPG_PASSPHRASE}\""
    fi

    # Export public key
    echo "Exporting public key to ${PUBKEY_DEST}..."
    gpg --batch --yes --armor --export "${GPG_KEY_ID}" > "$PUBKEY_DEST"
    cp -f "$PUBKEY_DEST" ./RPM-GPG-KEY-obsidian 2>/dev/null || true

    # Sign all RPMs in RPM_DIR
    if [ -d "$RPM_DIR" ]; then
        for rpm_file in "$RPM_DIR"/*.rpm; do
            if [ -f "$rpm_file" ]; then
                echo "Signing ${rpm_file}..."
                rpmsign --addsign \
                    --define "_gpg_name ${GPG_KEY_ID}" \
                    --define "_gpg_digest_algo sha256" \
                    --define "_gpg_sign_cmd_extra_args ${RPM_GPG_EXTRA}" \
                    "$rpm_file"
            fi
        done
    fi

    # Create signed .repo file in public root
    cat << EOF > "$PUB_ROOT/obsidian.repo"
[obsidian]
name=Obsidian Repository
baseurl=https://daflamingfox.github.io/obsidianmd-rpm/x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://daflamingfox.github.io/obsidianmd-rpm/RPM-GPG-KEY-obsidian
EOF
else
    echo "=== GPG Signing Disabled (Contingency Fallback) ===" >&2
    echo "WARNING: GPG_PRIVATE_KEY environment variable is not set." >&2
    echo "RPM packages and repository metadata will not be signed." >&2
    echo "To enable GPG signing, add GPG_PRIVATE_KEY (and optional GPG_KEY_ID) to repository secrets." >&2

    # Provide empty or existing public key placeholder
    if [ ! -f "$PUBKEY_DEST" ]; then
        touch "$PUBKEY_DEST"
    fi

    # Create fallback .repo file with gpgcheck=0
    cat << EOF > "$PUB_ROOT/obsidian.repo"
[obsidian]
name=Obsidian Repository
baseurl=https://daflamingfox.github.io/obsidianmd-rpm/x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
EOF
fi

# Build and package repository bootstrap RPM (obsidian-repo)
if [ -f obsidian-repo.spec ]; then
    echo "Building repository bootstrap package (obsidian-repo)..."
    REPO_TMP_DIR=$(mktemp -d)
    rpmbuild -bb obsidian-repo.spec --define "_sourcedir $PWD" --define "_topdir $REPO_TMP_DIR"
    BUILT_REPO_RPM=$(ls "$REPO_TMP_DIR"/RPMS/noarch/obsidian-repo-*.rpm 2>/dev/null | head -n 1 || true)
    if [ -n "$BUILT_REPO_RPM" ] && [ -f "$BUILT_REPO_RPM" ]; then
        if [ -n "${GPG_PRIVATE_KEY:-}" ]; then
            echo "Signing ${BUILT_REPO_RPM}..."
            rpmsign --addsign \
                --define "_gpg_name ${GPG_KEY_ID}" \
                --define "_gpg_digest_algo sha256" \
                --define "_gpg_sign_cmd_extra_args ${RPM_GPG_EXTRA}" \
                "$BUILT_REPO_RPM"
        fi
        cp -f "$BUILT_REPO_RPM" "$PUB_ROOT/obsidian-repo.rpm"
        cp -f "$BUILT_REPO_RPM" "$PUB_ROOT/$(basename "$BUILT_REPO_RPM")"
        echo "Bootstrap RPM published to $PUB_ROOT/obsidian-repo.rpm"
    fi
    rm -rf "$REPO_TMP_DIR"
fi

# Stage RPMs in TARGET_DIR for createrepo_c indexing
if [ -d "$RPM_DIR" ] && [ "$RPM_DIR" != "$TARGET_DIR" ]; then
    for rpm_file in "$RPM_DIR"/*.rpm; do
        if [ -f "$rpm_file" ]; then
            cp -f "$rpm_file" "$TARGET_DIR/"
        fi
    done
fi

# Generate repository metadata
echo "Running createrepo_c on ${TARGET_DIR}..."
createrepo_c --baseurl="https://github.com/${GITHUB_REPOSITORY}/releases/download/v${VERSION}/" "$TARGET_DIR"

# Clean up large RPMs from TARGET_DIR so they are not pushed to GitHub Pages
if [ -d "$RPM_DIR" ] && [ "$RPM_DIR" != "$TARGET_DIR" ]; then
    rm -f "$TARGET_DIR"/*.rpm
fi

# Detach-sign repomd.xml if GPG is active
if [ -n "${GPG_PRIVATE_KEY:-}" ]; then
    echo "Detach-signing ${TARGET_DIR}/repodata/repomd.xml..."
    DETACH_ARGS="--batch --yes --detach-sign --armor --pinentry-mode loopback --local-user ${GPG_KEY_ID}"
    if [ -n "${GPG_PASSPHRASE:-}" ]; then
        DETACH_ARGS="$DETACH_ARGS --passphrase ${GPG_PASSPHRASE}"
    fi
    gpg $DETACH_ARGS --output "${TARGET_DIR}/repodata/repomd.xml.asc" "${TARGET_DIR}/repodata/repomd.xml"
    echo "Signature generated: ${TARGET_DIR}/repodata/repomd.xml.asc"
fi

# Prevent GitHub Pages Jekyll processing
touch "$PUB_ROOT/.nojekyll"

# Generate static HTML index files
cat << 'EOF' > "$PUB_ROOT/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Obsidian RPM Repository</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; max-width: 800px; margin: 40px auto; padding: 0 20px; color: #24292e; }
        pre { background: #f6f8fa; padding: 16px; border-radius: 6px; overflow-x: auto; }
        code { font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, monospace; font-size: 0.9em; }
        a { color: #0969da; text-decoration: none; }
        a:hover { text-decoration: underline; }
        hr { border: 0; border-top: 1px solid #d0d7de; margin: 30px 0; }
        .card { border: 1px solid #d0d7de; border-radius: 6px; padding: 16px; margin: 20px 0; background: #ffffff; }
    </style>
</head>
<body>
    <h1>Obsidian RPM Repository</h1>
    <p>Automated DNF/RPM repository for <a href="https://obsidian.md/" target="_blank" rel="noopener">Obsidian</a> on Fedora, RHEL, CentOS, and compatible Linux distributions.</p>

    <div class="card">
        <h2>Quick Installation</h2>
        <p>1. Install the repository configuration package:</p>
        <pre><code>sudo dnf install https://daflamingfox.github.io/obsidianmd-rpm/obsidian-repo.rpm</code></pre>

        <p>2. Install Obsidian:</p>
        <pre><code>sudo dnf install obsidian</code></pre>
    </div>

    <div class="card">
        <h2>Manual Configuration</h2>
        <p>Alternatively, add the repository configuration file directly:</p>
        <pre><code>sudo curl -sLo /etc/yum.repos.d/obsidian.repo https://daflamingfox.github.io/obsidianmd-rpm/obsidian.repo
sudo dnf install obsidian</code></pre>
    </div>

    <hr>
    <h3>Repository Resources</h3>
    <ul>
        <li><a href="x86_64/">x86_64 Packages &amp; Metadata</a></li>
        <li><a href="RPM-GPG-KEY-obsidian">GPG Public Key (RPM-GPG-KEY-obsidian)</a></li>
        <li><a href="obsidian.repo">Repository Definition (obsidian.repo)</a></li>
        <li><a href="obsidian-repo.rpm">Bootstrap RPM Package (obsidian-repo.rpm)</a></li>
    </ul>

    <hr>
    <p><small>This repository is an unofficial packaging project. Obsidian is a trademark of Dynalist Inc.</small></p>
</body>
</html>
EOF

cat << 'EOF' > "$TARGET_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Obsidian RPM Repository - x86_64</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; max-width: 800px; margin: 40px auto; padding: 0 20px; color: #24292e; }
        a { color: #0969da; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>Obsidian RPM Repository &mdash; x86_64</h1>
    <p><a href="../">&larr; Back to Repository Root</a></p>
    <ul>
        <li><a href="repodata/">repodata/</a></li>
    </ul>
</body>
</html>
EOF

echo "=== Sign and index completed successfully ==="
