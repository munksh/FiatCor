#
# Fiat Cor — a metronome for Sailfish OS
#
# This .spec is the source of truth; there is no .yaml.
#
# The version is written here and nowhere else. It reaches the About page
# through %%qmake5 APP_VERSION=... and the .pro. Tag the release commit with
# the same number: sfdk takes the package version from the nearest git tag.
#
# No Requires: for QtMultimedia or Nemo.Configuration — both ship with the OS.
#

Name:       harbour-fiatcor
Summary:    Metronome
Version:    1.2
Release:    1
License:    MIT
URL:        https://github.com/munksh/FiatCor
Source0:    %{name}-%{version}.tar.bz2

Requires:   sailfishsilica-qt5 >= 0.10.9

BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Multimedia)
BuildRequires:  desktop-file-utils

%description
Fiat Cor is a metronome with a heartbeat: a sample-accurate pulse, time
signature, subdivision, per-beat accents, tap tempo and saved tempos.
Part of the fiat family of small Sailfish OS apps.

%if 0%{?_chum}
Title: fiat cor
Type: desktop-application
DeveloperName: Munkstolen
Categories:
 - Audio
 - Utility
AIRating: V
AINote: Claude is my typist - I cross review with Mistral, and add the code once it looks good. Architecture, design, on-device testing, releases and maintenance by me; issues and input welcome.
PackageIcon: https://munkstolen.se/SFOS/harbour-fiatcor.png
Screenshots:
 - https://munkstolen.se/SFOS/fiatcor1.png
 - https://munkstolen.se/SFOS/fiatcor2.png
Custom:
  Repo: https://github.com/munksh/FiatCor
Links:
  Homepage: https://github.com/munksh/FiatCor
  Bugtracker: https://github.com/munksh/FiatCor/issues
%endif

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5 APP_VERSION=%{version}
%make_build

%install
%qmake5_install

desktop-file-install --delete-original \
  --dir %{buildroot}%{_datadir}/applications \
  %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png

%changelog
* Mon Nov 02 2026 Caesar Prometheus Ivarsson <caesar@munkstolen.se> - 1.2-1
- About lists the whole fiat family, Penus and Tessera included.
- Every sibling in the list links to munkstolen.se.

* Mon Nov 02 2026 Caesar Prometheus Ivarsson <caesar@munkstolen.se> - 1.1-1
- About shows the version of the installed package, not a fixed number.
- Packaging tidied for the Jolla Store.

* Mon Oct 05 2026 Caesar Prometheus Ivarsson <caesar@munkstolen.se> - 1.0-1
- First release.
