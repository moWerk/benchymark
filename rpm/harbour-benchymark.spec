Name:       harbour-benchymark
Summary:    Benchymark, a rendering benchmark
Version:    1.0.0
Release:    1
License:    GPLv3+
URL:        https://github.com/moWerk/benchymark
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   libkeepalive
Requires:   qt5-qtgraphicaleffects
Requires:   nemo-qml-plugin-configuration-qt5
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils
BuildRequires:  qt5-qttools-linguist

%description
Benchymark runs rendering stages, a rotating 3DBenchy wireframe, shader
fields, text and fill rate tests, and shows frames per second for each
in a table to share. Ported from AsteroidOS.

%if 0%{?_chum}
Title: Benchymark
Type: desktop-application
DeveloperName: moWerk
Categories:
 - System
 - Monitor
Custom:
  Repo: https://github.com/moWerk/benchymark
PackageIcon: https://raw.githubusercontent.com/moWerk/benchymark/sailfishos/icons/172x172/harbour-benchymark.png
AIRating: V
AINote: The SailfishOS version was written by an LLM (Claude), directed and tested by the author on a Jolla C2; he chose the stages, loads, layout and icon. Every commit carries an LLMGD disclosure line (see the README).
Screenshots:
 - https://raw.githubusercontent.com/moWerk/benchymark/sailfishos/screenshots/benchymark-start.png
 - https://raw.githubusercontent.com/moWerk/benchymark/sailfishos/screenshots/benchymark-benchy-heavy.png
 - https://raw.githubusercontent.com/moWerk/benchymark/sailfishos/screenshots/benchymark-cpu-prime.png
 - https://raw.githubusercontent.com/moWerk/benchymark/sailfishos/screenshots/benchymark-results.png
 - https://raw.githubusercontent.com/moWerk/benchymark/sailfishos/screenshots/benchymark-about.png
Links:
  Homepage: https://github.com/moWerk/benchymark/tree/sailfishos
  Bugtracker: https://github.com/moWerk/benchymark/issues
%endif

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5 VERSION=%{version}
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
