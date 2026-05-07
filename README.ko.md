# Full Brightness

[English README](README.md)

Full Brightness는 여러 디스플레이를 쓰는 macOS 환경을 위한 유틸리티입니다. 연결된 디스플레이를 나열하고, 해상도와 HiDPI 정보를 보여주며, 밝기 제어가 가능한 디스플레이를 구분하고, 사용자가 정한 Full 밝기 기준으로 즉시 또는 새 디스플레이 연결 시 자동으로 밝기를 맞춥니다.

## 만든 이유

그런 경험 없으신가요? 아카데미 데스크의 모니터들은 Mac에서 밝기 조절이 되어서, 처음 사용하는 자리에 앉으면 항상 밝기를 본인에게 맞췄던 경험이 있습니다. 저는 밝기를 MAX로 두고 쓰는 걸 좋아하는데요. 밝기 올리는 일이 큰일은 아니지만, 매번 신경 쓰고 싶지는 않아서 Full Brightness를 만들었습니다.

## 앱 설명

Full Brightness는 Mac에 연결된 밝기 조정 가능 모니터를 감지하고, 내가 정한 Full 밝기 기준으로 한 번에 맞춰 주는 macOS 메뉴 막대 유틸리티입니다. 새 모니터가 연결될 때 자동으로 Full 밝기를 적용할 수 있고, 제어 센터, 단축어, Siri, Spotlight에서도 실행할 수 있습니다.

현재 GitHub 릴리즈: [`2026.05.08.001`](https://github.com/baserize/full-brightness/releases/tag/2026.05.08.001)

## 요구 사항

- macOS 26 이상
- Apple Silicon 또는 Intel Mac
- 소스에서 빌드할 경우 Xcode 26 이상
- 기본 Direct 빌드: macOS `DisplayServices`로 노출되는 Apple 네이티브 디스플레이 또는 공개 IOKit 밝기 파라미터로 쓰기 가능한 밝기 경로를 노출하는 디스플레이
- Store-safe 빌드: 공개 IOKit 밝기 파라미터로 쓰기 가능한 밝기 경로를 노출하는 디스플레이

일부 모니터, 독, 케이블, KVM, DisplayLink 계열 어댑터는 밝기 제어를 막을 수 있습니다. Full Brightness는 이런 디스플레이도 목록에는 표시하지만, 무리하게 제어하지 않고 지원 안 함으로 표시합니다.

## 주요 기능

- **밝기 제어 가능 디스플레이 감지**  
  연결된 디스플레이를 나열하고 밝기 읽기/쓰기 가능 여부를 표시합니다.

- **사용자 지정 Full 밝기 기준**  
  Settings에서 내 환경의 Full 기준을 1%부터 100%까지 정할 수 있습니다.

- **한 번에 Full 밝기 적용**  
  메인 윈도우, 메뉴 막대, 제어 센터, 단축어, Siri, Spotlight에서 밝기 조정 가능한 모든 디스플레이를 Full 기준으로 맞춥니다.

- **연결 시 자동 Full 밝기**  
  자동 모드를 켜면 새로 연결된 밝기 조정 가능 디스플레이를 Full 기준으로 자동 설정합니다.

- **실시간 밝기 갱신**  
  macOS 디스플레이 제어나 하드웨어 키로 밝기가 바뀌어도 디스플레이 목록이 최신 상태로 갱신됩니다.

- **제어 센터 컨트롤**  
  macOS 제어 센터에 추가할 수 있는 두 개의 WidgetKit 컨트롤을 제공합니다:
  - `모니터 Full`: 지원되는 디스플레이를 즉시 Full 기준으로 설정합니다.
  - `연결 시 Full`: 새 디스플레이 연결 시 자동 Full 밝기 모드를 전환합니다.

- **메뉴 막대 유틸리티**  
  새로고침, 한 번에 Full 밝기 적용, 자동 모드, 디스플레이 상태, 앱 열기, 설정, 종료를 제공하는 간단한 메뉴 막대 뷰를 포함합니다.

- **네이티브 Settings와 로그인 시 실행**  
  표준 macOS Settings 창에서 Full 밝기 기준, 키보드 단축키, 로그인 시 실행을 설정합니다.

- **사용자 지정 키보드 단축키**  
  모니터 Full 적용과 디스플레이 목록 새로고침 단축키를 직접 입력할 수 있습니다. 중복되거나 표준 앱 명령과 겹치는 조합은 저장 전에 막습니다.

- **App Shortcuts 연동**  
  단축어, Siri, Spotlight에서 사용할 수 있는 App Intents 기반 단축어를 제공합니다:
  - `모니터 Full`
  - `자동 Full 켜기`
  - `자동 Full 끄기`

- **해상도와 HiDPI 정보**  
  macOS가 제공하는 경우 논리 해상도, HiDPI 배율, 실제 픽셀 해상도, 주사율을 보여줍니다.

- **영어와 한국어 지원**  
  시스템 또는 앱 언어 설정에 따라 영어와 한국어 UI를 지원합니다.

## 설치

### GitHub Release

[최신 릴리즈 페이지](https://github.com/baserize/full-brightness/releases/latest)에서 notarize된 ZIP을 내려받아 압축을 풀고, `Full Brightness.app`을 `/Applications`로 옮깁니다.

직접 다운로드:

```sh
curl -L -o Full-Brightness-2026.05.08.001.zip \
  https://github.com/baserize/full-brightness/releases/download/2026.05.08.001/Full-Brightness-2026.05.08.001.zip
unzip Full-Brightness-2026.05.08.001.zip
mv "Full Brightness.app" /Applications/
```

릴리즈 ZIP은 Mac App Store 밖에서 배포하기 위해 Developer ID로 서명되어 있고 Apple notarization을 통과한 빌드입니다.

### Homebrew

repo cask tap으로 설치:

```sh
brew tap baserize/full-brightness https://github.com/baserize/full-brightness
brew install --cask full-brightness
```

cask URL로 바로 설치:

```sh
brew install --cask https://raw.githubusercontent.com/baserize/full-brightness/main/Casks/full-brightness.rb
```

앱 제거:

```sh
brew uninstall --cask full-brightness
```

앱 데이터까지 제거:

```sh
brew uninstall --zap --cask full-brightness
```

## 사용 방법

1. Full Brightness를 엽니다.
2. 디스플레이 목록과 지원 상태를 확인합니다.
3. 100%가 내 환경의 기준이 아니라면 Settings에서 Full 밝기 기준을 정합니다.
4. `연결된 모니터 Full`을 눌러 지원되는 모든 디스플레이를 해당 기준으로 맞춥니다.
5. 새로 연결되는 지원 디스플레이도 항상 Full 기준으로 맞추려면 `연결 시 자동 Full`을 켭니다.
6. 로그인 시 실행은 툴바 또는 메뉴 막대의 Settings에서 설정합니다.

## 제어 센터

앱을 설치하거나 실행한 뒤 macOS 제어 센터 사용자화 화면에서 Full Brightness를 검색하고 두 컨트롤을 추가합니다. 번들 식별자나 컨트롤 종류가 빌드 사이에 바뀐 경우 기존 컨트롤을 제거한 뒤 다시 추가해야 할 수 있습니다.

## App Shortcuts

단축어 앱 또는 Spotlight에서 Full Brightness를 검색합니다. 앱은 디스플레이를 Full 기준으로 맞추고 자동 모드를 켜거나 끄는 로컬라이즈된 App Intents 기반 단축어를 제공합니다.

## 디스플레이 지원 방식

기본 빌드는 **Direct 배포용**입니다. Mac App Store 밖에서 Apple 내장 디스플레이와 Apple 네이티브 밝기 경로를 제어하기 위해 private `DisplayServices` 엔트리 포인트를 런타임 심볼 로딩으로 사용합니다.

Direct 빌드는 특정 디스플레이에서 `DisplayServices`를 사용할 수 없을 때 공개 IOKit `kIODisplayBrightnessKey` 경로로 fallback합니다.

Direct 빌드의 메인 앱은 App Sandbox가 없는 `Sources/App/FullBrightnessDirect.entitlements`를 사용하고, 제어 센터 확장은 sandbox와 app group entitlement를 유지합니다.

DDC/CI로만 밝기를 제어할 수 있는 일반 외장 모니터는 여전히 지원 안 함으로 표시될 수 있습니다. 이 경우 별도 DDC backend가 필요하며, 현재 Apple 네이티브 밝기 경로와는 별개의 향후 Direct 배포 확장 범위입니다.

지원되지 않는 디스플레이는 보통 디스플레이, 독, 케이블, 어댑터, 드라이버가 macOS에 쓰기 가능한 밝기 채널을 노출하지 않기 때문에 실패합니다.

## 빌드

```sh
./script/build_and_run.sh --verify
```

기본적으로 빌드 스크립트는 private `DisplayServices` backend가 포함된 `Direct Debug` 구성을 사용합니다.

설치나 실행 없이 Direct Release 빌드만 하려면:

```sh
./script/build_and_run.sh --release --build-only
```

Store-safe public API 빌드를 만들려면:

```sh
./script/build_and_run.sh --store --release --build-only
```

이 스크립트는 `project.yml`에서 `FullBrightness.xcodeproj`를 다시 생성하고, Xcode로 앱을 빌드하며, macOS가 제어 센터 확장을 찾을 수 있도록 `/Applications/Full Brightness.app`에 설치할 수 있습니다.

## 릴리즈

공개 GitHub 릴리즈 태그는 날짜 기반 버전 `2026.05.08.001`을 사용합니다.

Apple 번들 버전 필드는 App Store 호환 숫자 형식을 사용합니다:

- `CFBundleShortVersionString`: `2026.5.8`
- `CFBundleVersion`: `20260508001`

### Direct 배포 패키지

private API 빌드는 Developer ID 배포를 사용합니다:

```sh
./script/package_direct.sh
```

이 스크립트는 public 직접 배포를 위해 `Developer ID Application` 인증서를 요구합니다. `Direct Release`를 archive하고, `packaging/ExportOptions-DeveloperID.plist`로 export한 뒤, 앱을 `Full Brightness.app`으로 staging하고 ZIP을 만들며 SHA-256과 서명 검증 결과를 출력합니다. `NOTARYTOOL_PROFILE`을 지정하면 `xcrun notarytool`로 ZIP을 제출하고 앱에 notarization ticket을 staple한 뒤 최종 ZIP을 다시 만듭니다.

Developer ID 인증서 없이 로컬 ZIP만 확인하려면:

```sh
./script/package_direct.sh --local
```

추천 배포 순서는 다음입니다:

1. GitHub Releases notarized ZIP
2. `Casks/full-brightness.rb`의 Homebrew cask
3. 온보딩이나 브랜딩이 필요해질 때 DMG 추가
4. 자동 업데이트가 필요해질 때 Sparkle 추가

Apple의 Developer ID 흐름은 Mac App Store 밖에서 배포하는 앱을 Developer ID로 서명하고 notarize하는 것을 전제로 합니다. Homebrew Cask는 version, SHA-256, URL, 메타데이터, `app` artifact를 담은 cask 파일을 사용합니다.

## App Store 상태

기본 Direct 빌드는 private display service를 사용하므로 **Mac App Store 또는 TestFlight 안전 빌드가 아닙니다**. Store-safe `Debug`와 `Release` 구성은 public API 전용 빌드로 남겨두었지만, macOS가 해당 디스플레이에 공개 쓰기 가능 IOKit 밝기 채널을 노출하지 않는 한 Apple Silicon 내장 밝기는 제어하지 못합니다.
