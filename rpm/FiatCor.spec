#
# Fiat Cor — a metronome for Sailfish OS
#
# There is deliberately no rpm/FiatCor.yaml. This .spec is the source of
# truth and is safe to edit directly.
#
# NO Requires line for QtMultimedia, QtFeedback or Nemo.Configuration:
# all three QML modules ship with the OS. Check on the device with
#   ls /usr/lib64/qt5/qml/QtMultimedia/
#   ls /usr/lib64/qt5/qml/QtFeedback/
#   ls /usr/lib64/qt5/qml/Nemo/Configuration/
# before adding anything — a package that does not exist fails the
# install with "Paketet hittades ej", exactly as
# nemo-qml-plugin-configuration did in Fiat Lux.
#
# Note that QT += multimedia is NOT in the .pro either. The QML module is
# loaded at runtime by the import, so the -devel package is not needed in
# the build target.
#

Name:       FiatCor
Summary:    Metronome
Version:    0.1.0
Release:    1
License:    MIT
URL:        https://github.com/munksh/FiatCor
Source0:    %{name}-%{version}.tar.bz2

Requires:   sailfishsilica-qt5 >= 0.10.9

BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils

%description
Fiat Cor is a metronome with a heartbeat: a drift-free pulse, time
signature, subdivision, per-beat accents, tap tempo and saved tempos.
Part of the Fiat family alongside Fiat Lux and Fiat Vox.

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5
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
