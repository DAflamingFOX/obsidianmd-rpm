Name:           obsidian
Version:        %{_version}
Release:        1%{?dist}
Summary:        The free and flexible app for your private thoughts.
License:        Commercial
URL:            https://obsidian.md/
Source0:        obsidian-%{version}.tar.gz
Source1:        obsidian.desktop

BuildArch:      x86_64
Requires:       zlib, nss, alsa-lib, gtk3

%description
The free and flexible app for your private thoughts.

%prep
%setup -q -n obsidian-%{version}

%install
# Create the installation directory and copy the app
mkdir -p %{buildroot}/opt/Obsidian
cp -r * %{buildroot}/opt/Obsidian/
chmod +x %{buildroot}/opt/Obsidian/obsidian

# Install the desktop shortcut
mkdir -p %{buildroot}/usr/share/applications
cp %{SOURCE1} %{buildroot}/usr/share/applications/

# Install the icon from the resources folder
mkdir -p %{buildroot}/usr/share/pixmaps
cp resources/icon.png %{buildroot}/usr/share/pixmaps/obsidian.png

%files
/opt/Obsidian/
/usr/share/applications/obsidian.desktop
/usr/share/pixmaps/obsidian.png