%global debug_package %{nil}

Name:           obsidian
Version:        1.7.7
Release:        1%{?dist}
Summary:        The free and flexible app for your private thoughts.
License:        Commercial
URL:            https://obsidian.md/
Vendor:         DAflamingFOX
Packager:       DAflamingFOX's Obsidian.md Repository

Source0:        obsidian-%{version}.tar.gz
Source1:        md.obsidian.Obsidian.desktop

ExclusiveArch:  x86_64
AutoReqProv:    no
Requires:       gtk3, nss, alsa-lib, zlib, at-spi2-atk, libdrm, mesa-libgbm, libxkbcommon

%description
The free and flexible app for your private thoughts.

%prep
%setup -q -n obsidian-%{version}

%install
# Create the installation directory and copy the app
mkdir -p %{buildroot}/opt/Obsidian
cp -r * %{buildroot}/opt/Obsidian/
chmod +x %{buildroot}/opt/Obsidian/obsidian

# Create symlink in /usr/bin
mkdir -p %{buildroot}%{_bindir}
ln -s /opt/Obsidian/obsidian %{buildroot}%{_bindir}/obsidian

# Install the desktop shortcut
mkdir -p %{buildroot}%{_datadir}/applications
cp %{SOURCE1} %{buildroot}%{_datadir}/applications/

# Install the icon in standard hicolor directory
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/512x512/apps
cp resources/icon.png %{buildroot}%{_datadir}/icons/hicolor/512x512/apps/obsidian.png

# Install the icon in pixmaps directory for compatibility
mkdir -p %{buildroot}%{_datadir}/pixmaps
cp resources/icon.png %{buildroot}%{_datadir}/pixmaps/obsidian.png

%files
/opt/Obsidian/
%{_bindir}/obsidian
%{_datadir}/applications/md.obsidian.Obsidian.desktop
%{_datadir}/icons/hicolor/512x512/apps/obsidian.png
%{_datadir}/pixmaps/obsidian.png