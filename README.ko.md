# DisplayFit

[English README](README.md)

DisplayFit은 연결된 Mac 디스플레이를 내가 정한 밝기와 책상 배치로 되돌려 주는 macOS 메뉴 막대 유틸리티입니다. 메인 윈도우, 메뉴 막대, 제어 센터, 단축어, Siri, Spotlight에서 실행할 수 있습니다.

현재 릴리즈: [`2026.05.13.001`](https://github.com/baserize/displayfit/releases/tag/2026.05.13.001)

## 만든 이유

DisplayFit은 공용 데스크처럼 모니터 밝기와 배치가 매번 다른 상태로 남아 있는 환경을 위해 만들었습니다. 제가 다니는 Apple Developer Academy의 데스크 모니터들은 Mac에서 바로 밝기를 조절할 수 있는데, 자리를 옮길 때마다 밝기와 배치를 다시 맞춰야 했습니다. 이 반복 작업을 없애고 싶었습니다.

## 주요 기능

- **내 기준의 Full 밝기 설정**
  1%부터 100%까지 내 환경에서 Full로 취급할 밝기 기준을 정할 수 있습니다.

- **연결된 디스플레이 한 번에 설정**
  macOS가 제어를 허용하는 모든 연결 디스플레이를 Full 기준으로 맞춥니다.

- **연결 시 자동 Full**
  자동 모드를 켜면 새로 연결된 지원 디스플레이를 Full 기준으로 자동 설정합니다.

- **모니터 배치 Fit 저장**
  현재 모니터 조합과 위치를 저장하고 나중에 다시 적용할 수 있습니다.

- **연결 시 자동 Fit**
  같은 모니터 조합이 연결되면 해당 배치를 자동 적용할 수 있습니다.

- **새 모니터 감지 팝업**
  처음 보는 모니터가 나타나면 현재 배치를 저장하거나, 저장된 Fit을 적용하거나, 주 모니터의 왼쪽/오른쪽/위/아래에 배치할 수 있습니다.

- **아직 연결하지 않은 모니터 기본 위치**
  다음에 연결될 새 모니터의 기본 위치를 미리 정할 수 있습니다. 더 정확한 책상 배치가 필요하면 가로/세로 보정값으로 세부 조정할 수 있습니다.

- **저장된 배치와 다른 상태 경고**
  앱이 켜진 상태에서 사용자가 직접 모니터 배치를 바꾸면 즉시 되돌리지 않고, 현재 배치가 저장된 Fit과 다르다는 경고만 보여 줍니다. 자동 Fit은 모니터 연결 이벤트 때 실행됩니다.

- **디스플레이 지원 상태 표시**
  어떤 디스플레이가 밝기 조절 가능한지, 어떤 디스플레이가 읽기 전용이거나 지원되지 않는지 확인할 수 있습니다.

- **해상도와 HiDPI 정보**
  macOS가 제공하는 경우 논리 해상도, 실제 픽셀 해상도, HiDPI 배율, 주사율을 표시합니다.

- **실시간 밝기 갱신**
  macOS 디스플레이 제어나 하드웨어 키로 밝기가 바뀌어도 목록을 최신 상태로 갱신합니다.

- **제어 센터 컨트롤**
  WidgetKit 기반 컨트롤 두 개를 제공합니다:
  - `모니터 Full`: 지금 바로 Full 기준을 적용합니다.
  - `연결 시 Full`: 새 디스플레이 연결 시 자동 Full 모드를 전환합니다.

- **메뉴 막대 유틸리티**
  메뉴 막대에서 새로고침, 즉시 Full 적용, 저장된 배치 적용, 자동 모드, 디스플레이 상태, 설정, 앱 열기, 종료를 사용할 수 있습니다.

- **App Shortcuts**
  단축어, Siri, Spotlight에서 사용할 수 있는 로컬라이즈된 액션을 제공합니다:
  - `모니터 Full`
  - `자동 Full 켜기`
  - `자동 Full 끄기`

- **사용자 지정 키보드 단축키**
  모니터 Full 적용과 디스플레이 목록 새로고침 단축키를 직접 입력할 수 있습니다. 중복되거나 표준 앱 명령과 겹치는 단축키는 저장 전에 막습니다.

- **영어와 한국어 지원**
  영어와 한국어 UI 문자열 및 문서를 제공합니다.

## 요구 사항

- macOS 26 이상
- Apple Silicon 또는 Intel Mac
- 소스에서 빌드할 경우 Xcode 26 이상

## 설치

### DMG, 권장

[최신 릴리즈 페이지](https://github.com/baserize/displayfit/releases/latest)에서 DMG를 내려받아 열고, 앱을 `Applications`로 드래그합니다.

직접 다운로드:

```sh
curl -L -o DisplayFit-2026.05.13.001.dmg \
  https://github.com/baserize/displayfit/releases/download/2026.05.13.001/DisplayFit-2026.05.13.001.dmg
open DisplayFit-2026.05.13.001.dmg
```

기본 설치 경로는 DMG입니다. Homebrew, DMG 검증, macOS Gatekeeper 안내는 [INSTALL.ko.md](INSTALL.ko.md)를 확인하세요. ZIP asset도 자동화와 문제 해결용으로 함께 발행합니다.

### Homebrew

repo cask tap으로 설치:

```sh
brew tap baserize/displayfit https://github.com/baserize/displayfit
brew install --cask displayfit
```

notarization이 없는 빌드라 Gatekeeper가 첫 실행을 막는다면 quarantine을 직접 제거하기 전에 [INSTALL.ko.md](INSTALL.ko.md)를 확인하세요.

cask URL로 바로 설치:

```sh
brew install --cask https://raw.githubusercontent.com/baserize/displayfit/main/Casks/displayfit.rb
```

앱 제거:

```sh
brew uninstall --cask displayfit
```

앱 데이터까지 제거:

```sh
brew uninstall --zap --cask displayfit
```

## 직접 배포하는 이유

DisplayFit은 App Store 배포를 목표로 하지 않습니다. Apple 내장 디스플레이를 macOS 기본 밝기 조절에 가깝게 제어하려면 공개 API만으로는 한계가 있어서, 직접 배포 빌드는 런타임 로딩 기반 private `DisplayServices` 밝기 경로와 공개 IOKit fallback을 함께 사용합니다.

이 private display 경로는 App Store 심사 기준에 맞지 않을 수 있으므로, DisplayFit은 GitHub Releases와 Homebrew를 통한 직접 배포 방식으로 제공합니다.

## 사용 방법

1. DisplayFit을 엽니다.
2. 디스플레이 목록과 지원 상태를 확인합니다.
3. 100%가 내 기준이 아니라면 Settings에서 Full 밝기 기준을 정합니다.
4. `연결된 모니터 Full`을 눌러 지원되는 모든 디스플레이에 해당 기준을 적용합니다.
5. 새로 연결되는 지원 디스플레이도 자동으로 맞추려면 `연결 시 자동 Full`을 켭니다.
6. 배치 화면에서 `현재 배치 저장`을 눌러 현재 모니터 위치를 저장합니다.
7. 저장된 모니터 배치를 자동으로 적용하려면 `연결 시 자동 Fit`을 켭니다.
8. 재시동 후에도 바로 쓰고 싶다면 Settings에서 로그인 시 실행을 켭니다.

## 제어 센터

앱을 설치하거나 실행한 뒤 macOS 제어 센터 사용자화 화면에서 DisplayFit을 검색합니다. 앱을 열지 않고도 밝기를 제어하고 싶다면 컨트롤을 추가합니다.

로컬 빌드 후 macOS가 예전 컨트롤을 계속 보여 준다면 기존 컨트롤을 제거하고, `/Applications/DisplayFit.app`에서 앱을 실행한 뒤 다시 추가합니다.

## 디스플레이 지원

DisplayFit은 macOS가 쓰기 가능한 밝기 경로를 노출하는 디스플레이의 밝기를 제어할 수 있습니다. 현재 Direct 빌드는 다음 경로를 대상으로 합니다:

- macOS `DisplayServices`로 노출되는 Apple 내장 디스플레이와 Apple 네이티브 밝기 경로
- 공개 IOKit `kIODisplayBrightnessKey`로 쓰기 가능한 밝기를 노출하는 디스플레이

일부 디스플레이는 계속 지원 안 함으로 표시될 수 있습니다. 흔한 원인은 다음과 같습니다:

- 모니터가 DDC/CI 밝기 제어만 지원함
- 독, KVM, 케이블, 어댑터, DisplayLink 계열 드라이버가 밝기 채널을 숨김
- macOS가 디스플레이는 인식하지만 쓰기 가능한 밝기 제어를 노출하지 않음

지원되지 않는 디스플레이도 목록에는 표시해서 macOS가 해당 디스플레이를 인식하는지 확인할 수 있게 합니다. 실제 쓰기 가능한 제어 경로가 없는 디스플레이에 대해서는 밝기를 추측하거나 화면 밝기 효과를 흉내 내지 않습니다.

## 모니터 배치

DisplayFit은 Core Graphics로 연결된 각 디스플레이의 bounds를 읽고, 디스플레이 fingerprint 기준으로 위치를 저장합니다. Fingerprint는 vendor ID, product ID, 가능한 경우 serial number, 디스플레이 이름, 논리 해상도를 조합해 저장된 배치를 나중에 다시 찾습니다.

저장된 배치는 Core Graphics display configuration transaction으로 적용합니다. 기본 적용 범위는 현재 로그인 세션이므로, 사용자의 macOS 디스플레이 배치를 영구적으로 덮어쓰지 않고도 복구할 수 있습니다.

현재 배치를 저장하면 연결된 기기 이름과 fingerprint 조합을 기준으로 기기별 Fit이 만들어집니다. 같은 모니터 조합이 다시 연결되면 DisplayFit이 해당 프로필을 자동으로 선택하고, `연결 시 자동 Fit`이 켜져 있으면 모니터 연결 이벤트 때 그 기기 조합에 맞는 저장 배치를 적용합니다.

아직 연결하지 않은 다음 새 모니터도 기본 위치를 미리 정할 수 있습니다. 설정의 `새 모니터 기본 배치`에서 주 모니터의 왼쪽, 오른쪽, 위, 아래 중 하나를 고르면 새 모니터가 감지될 때 팝업 없이 먼저 맞춥니다. 더 정확한 책상 배치가 필요하면 접혀 있는 `세부 위치 조정`에서 가로/세로 보정값을 추가할 수 있습니다.

처음 보는 외장 모니터는 새 모니터 감지 팝업에서 위치를 고를 수 있습니다. `이 기기 위치 기억`을 켠 채 위치를 고르면, 전체 배치를 따로 저장하지 않아도 다음 연결 때 같은 위치 규칙을 다시 사용합니다.

앱이 켜진 상태에서 사용자가 직접 모니터 배치를 바꾸면 DisplayFit은 즉시 저장된 배치로 되돌리지 않습니다. 대신 현재 배치가 저장된 Fit과 다르다는 경고를 보여 주고, 다음 모니터 연결 이벤트나 사용자의 `저장된 Fit 적용` 명령을 기다립니다.

일부 환경은 여전히 모호할 수 있습니다:

- 같은 모델의 모니터 여러 대가 serial number를 보고하지 않는 경우
- 독, KVM, 어댑터, DisplayLink 계열 드라이버가 디스플레이 identity를 바꾸는 경우
- macOS가 겹침이나 빈 공간을 없애기 위해 요청한 위치를 조정하는 경우

## 소스에서 빌드

```sh
./script/build_and_run.sh --verify
```

스크립트는 `project.yml`에서 `DisplayFit.xcodeproj`를 다시 생성하고, Xcode로 앱을 빌드하며, 기본적으로 `/Applications/DisplayFit.app`에 설치한 뒤 실행 검증까지 수행합니다.

설치나 실행 없이 빌드만 하려면:

```sh
./script/build_and_run.sh --build-only --no-install
```

Release 빌드:

```sh
./script/build_and_run.sh --release --build-only --no-install
```

Debug와 Release 모두 `DIRECT_DISTRIBUTION`과 런타임 로딩 기반 `DisplayServices` 밝기 backend를 포함합니다. 메인 앱은 `Sources/App/DisplayFitDirect.entitlements`를 사용하고, 제어 센터 확장은 sandbox와 app group entitlement를 유지합니다.

## 패키징

Notarization이 적용된 Developer ID 릴리즈 패키지 생성:

```sh
./script/package_direct.sh
```

Developer ID 인증서 없이 로컬 패키지 확인:

```sh
./script/package_direct.sh --local
```

Artifact는 `.build/dist/direct/`에 생성됩니다. 공개 릴리즈 패키징은 기본적으로 `displayfit-notary` notarytool profile을 요구합니다. 패키징 스크립트는 `DisplayFit.app`을 staging하고, DMG와 ZIP artifact를 만들고, 앱과 DMG를 Apple notarization에 제출하고, ticket을 staple하고, SHA-256 값을 출력하고, export된 서명과 Gatekeeper 승인을 검증합니다.

## 버전

현재 릴리즈는 다음 버전을 사용합니다:

- GitHub 릴리즈 태그: `2026.05.13.001`
- `CFBundleShortVersionString`: `2026.5.13`
- `CFBundleVersion`: `20260513001`
