# DisplayFit 설치 설명서

DisplayFit은 GitHub Releases와 repo Homebrew cask로 배포합니다.

## Homebrew

```sh
brew tap baserize/displayfit https://github.com/baserize/displayfit
brew install --cask displayfit
open -a DisplayFit
```

현재 빌드가 notarization을 거치지 않아 macOS가 첫 실행을 막는다면, 릴리즈 노트의 checksum을 확인한 뒤 설치된 앱의 quarantine flag를 제거할 수 있습니다.

```sh
xattr -dr com.apple.quarantine /Applications/DisplayFit.app
open -a DisplayFit
```

앱만 제거:

```sh
brew uninstall --cask displayfit
```

저장된 설정과 app group 데이터까지 제거:

```sh
brew uninstall --zap --cask displayfit
```

## DMG

최신 릴리즈에서 `DisplayFit-2026.05.13.001.dmg`를 내려받습니다.

https://github.com/baserize/displayfit/releases/latest

DMG를 열고 `DisplayFit.app`을 `Applications`로 드래그합니다.

## 다운로드 검증

릴리즈 노트에 있는 SHA-256 값과 내려받은 DMG checksum을 비교합니다.

```sh
shasum -a 256 ~/Downloads/DisplayFit-2026.05.13.001.dmg
```

## macOS 보안 안내

DisplayFit은 직접 배포를 위해 Developer ID로 서명되어 있습니다. 릴리즈가 아직 notarization을 거치지 않은 경우, macOS Gatekeeper가 첫 실행 때 추가 확인을 요구할 수 있습니다.

먼저 macOS 기본 경로로 여세요.

1. `DisplayFit.app`을 `Applications`로 옮깁니다.
2. `DisplayFit.app`을 Control-click합니다.
3. `열기`를 선택합니다.
4. 확인 대화상자를 승인합니다.

릴리즈 checksum을 확인한 뒤에도 macOS가 실행을 막는 경우에만 quarantine flag를 직접 제거할 수 있습니다.

```sh
xattr -dr com.apple.quarantine /Applications/DisplayFit.app
open -a DisplayFit
```

DisplayFit의 기본 밝기와 배치 기능은 Accessibility 또는 Screen Recording 권한을 요구하지 않습니다. 다만 앱을 교체한 뒤에는 macOS가 WidgetKit extension을 캐시할 수 있으므로, 제어 센터 컨트롤을 다시 추가해야 할 수 있습니다.
