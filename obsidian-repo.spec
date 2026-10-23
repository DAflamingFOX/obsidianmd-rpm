Name:           obsidian-repo
Version:        1.0
Release:        1
Summary:        Obsidian RPM repository configuration
License:        MIT
URL:            https://github.com/DAflamingFOX/obsidianmd-rpm

Source0:        obsidian.repo
Source1:        RPM-GPG-KEY-obsidian

BuildArch:      noarch

%description
Repository configuration and public GPG key for Obsidian RPM packages.

%prep
# Nothing to prep

%build
# Nothing to build

%install
mkdir -p %{buildroot}%{_sysconfdir}/yum.repos.d
install -p -m 644 %{SOURCE0} %{buildroot}%{_sysconfdir}/yum.repos.d/obsidian.repo

mkdir -p %{buildroot}%{_sysconfdir}/pki/rpm-gpg
if [ -f %{SOURCE1} ]; then
    install -p -m 644 %{SOURCE1} %{buildroot}%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-obsidian
else
    touch %{buildroot}%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-obsidian
fi

%files
%config(noreplace) %{_sysconfdir}/yum.repos.d/obsidian.repo
%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-obsidian
