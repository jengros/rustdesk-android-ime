# RustDesk Personal Android

이 저장소는 공식 RustDesk 1.5.1 (`23e5bb471a040d62f0a6ad52591fb30784265b73`)에서 분기한 개인용 수정본이다.

## 수정 범위

- Android는 자체 빈 TextEditingController를 사용하며, 원본의 1 채움용 controller를 연결하지 않는다. 실제 문자열의 공통 부분과 바뀐 꼬리를 비교해 삭제·삽입을 전송한다.
- 한글 조합 중인 글자도 즉시 전송한다. `ㄱ → 가 → 가나다`처럼 같은 길이의 변경도 이전 글자를 지우고 새 글자로 갱신한다. 공백이나 Enter로 확정할 때까지 기다리지 않는다.
- Android 입력란의 raw Backspace/Enter는 직접 처리하고 handled로 종료한다. 빈 입력란의 Backspace도 PC에 이미 있던 글자를 삭제한다. 다른 키 이벤트는 skipRemainingHandlers로 원격 물리 키 처리와 격리하고 Android 자체 편집은 허용한다.
- 새 글자는 Unicode 문자열 경로로 보낸다. 새 입력 위젯은 Android에만 연결하며 기존 iOS 및 소프트 키보드를 닫은 상태의 물리 키 경로는 유지한다.
- 앱 ID: `com.carriez.flutter_hbb.kykpersonal`, 표시 이름: `RustDesk Personal`. 공식 앱과 함께 설치할 수 있다.

현재 버전은 `1.5.1-kyk.3`이다. Flutter의 실제 TextField에 IME 편집 값과 raw 키를 전달하는 위젯 테스트 3개로 즉시 한글 갱신, 초기 버퍼 없음, 기존 PC 문자 삭제, 로컬 문자 삭제, 반복 삭제, Enter, 숫자 1 입력을 검증했다. 소프트 키보드가 열린 상태의 외부 물리 키보드 단축키는 별도 현장 검증 대상이다. 휴대폰은 연결하지 않았으며 실제 삼성 키보드에서의 개선 여부는 미확인이다.

## 빌드 구성

Flutter/Dart UI와 Android Kotlin 앱은 수정 소스에서 release APK로 빌드한다. Rust 네이티브 코드는 변경하지 않았고 공식 1.5.1 arm64 APK의 `librustdesk.so`, `libc++_shared.so`를 재사용한다. 전체 Rust 소스를 재컴파일한 결과물이 아니다.

- 공식 APK: https://github.com/rustdesk/rustdesk/releases/download/1.5.1/rustdesk-1.5.1-aarch64-signed.apk
- APK SHA-256: `cfc44193ef96dd601d25c9a29f1aa5385effdbaae33d2abbb1d88495797f6b84`
- Flutter 3.24.5 / Dart 3.5.4 / JDK 17 / Android SDK 36.
- Dart 브리지: 공식 CI run `41441026686`, artifact `13139123274` (`bridge-artifact`). 생성 기준 `898f7552b2c98d9b44e905c837bdd4b21e9cb4b4`는 1.5.1 이후 2개 커밋이며, 비교 결과 Kotlin 클립보드 파일과 이탈리아어 번역만 변경되어 FFI 정의는 동일했다. 로컬 codegen은 실행하지 않았다.
- 인증서 검증 Maven 의존성은 Cargo.lock의 `rustls-platform-verifier-android` 0.1.1 crate를 사용한다. crate SHA-256: `f87165f0995f63a9fbeea62b64d10b4d9d8e78ec6d7d51fb2125fda7bb36788f`.
- `personalBuild` Gradle 속성으로 로컬 개발용 서명을 사용한다. 정식 앱 서명키를 사용하지 않는다. 업데이트할 때는 동일한 로컬 키를 유지해야 한다.
- 생성된 브리지·네이티브 라이브러리·SDK·키·빌드 캐시는 Git에 포함하지 않는다.

## 로컬 재빌드

`personal/build-android.ps1`은 이 PC에 준비한 도구 폴더를 사용한다. 의존성 확인, 3개 회귀 테스트, 변경 파일 분석, arm64 release APK 생성을 순서대로 수행한다.

```powershell
pwsh -File personal/build-android.ps1
```

이 PC는 개발자 모드가 꺼져 있어 Desktop 플러그인용 symlink 생성이 실패한다. 스크립트는 이 새 checkout의 Windows/Linux 타깃 디렉터리만 빌드 중 임시 이동하고 finally에서 복구한다. PC 전역 개발자 모드나 기존 설정은 변경하지 않는다.

APK 출력: `flutter/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.

## 휴대폰 확인

1. APK를 휴대폰에 옮기고 `RustDesk Personal`을 설치한다. 공식 앱은 그대로 유지한다.
2. 개인 앱에 기존과 같은 서버 설정이 필요하면 직접 입력한 뒤 PC에 접속한다.
3. 삼성 키보드로 `abc 가나다`, `안녕하세요`, 받침 수정, 삭제, 한/영 전환을 확인한다.
4. 키보드를 연 직후 Backspace를 누른 다음 입력해 `1` 반복이 재발하는지 확인한다.

참고 수정안: https://github.com/rustdesk/rustdesk/pull/15429 및 https://github.com/rustdesk/rustdesk/pull/14495 . 두 PR을 그대로 병합한 것이 아니라 개인용 Android 경로에 한정해 구현했다.

AGPL-3.0 및 원본 저작권 고지는 원본 저장소의 LICENCE를 따른다.

## 개인용 두 번째 빌드: 불필요한 접근성 기능 제거

`1.5.1-kyk.2`에서는 AndroidManifest의 InputService 접근성 서비스 등록을 제거했다. Android가 앱을 접근성 서비스로 인식하거나 해당 기능을 켤 수 없게 되므로, 다른 기기에서 이 휴대폰에 키보드·터치 입력을 보내는 기능은 사용할 수 없다. 휴대폰에서 PC를 조작하는 연결과 앞서 수정한 삼성 키보드 입력 경로는 이 서비스를 사용하지 않는다.

첫 빌드는 Google Play 프로텍트에서 민감한 정보 접근 권한을 이유로 설치 차단되었다. Google 공식 개발자 안내상 인터넷에서 받은 APK의 접근성 서비스 선언은 설치 차단 대상이 될 수 있다. 이 수정은 사용하지 않는 기능을 실제 제거하는 권한 축소이며, 보호 기능이나 검사를 끄지 않는다. 서비스 등록이 없는지는 완성 APK의 병합된 manifest에서 확인한다. Google이 새 파일의 설치를 허용하는지는 실제 휴대폰에서 확인해야 한다.

버전 이름은 `1.5.1-kyk.2`, 기본 build number는 71이며 ARM64 split APK의 실제 versionCode는 2071이다. 공식 앱과 분리된 기존 개인용 앱 ID 및 같은 로컬 서명키를 유지한다.

참고: https://developers.google.com/android/play-protect/warning-dev-guidance

## 개인용 세 번째 빌드: 현장 입력 문제 보완

사용자가 kyk.2에서 1 반복 유출, 공백을 누를 때까지 한글이 보이지 않음, Backspace 실패를 보고했다. 앞선 테스트는 계산 헬퍼와 키 격리를 따로 검증했으며 실제 입력 위젯의 초기값·삭제 경로를 충분히 검증하지 못했다. kyk.3에서는 Android 입력 위젯이 빈 buffer를 직접 소유하도록 분리하고, 조합 중인 전체 문자열을 즉시 비교하며, raw 삭제·Enter를 처리하는 방식으로 바꿨다. 앞선 접근성 서비스 제거는 유지한다.

기본 build number 72, ARM64 split APK versionCode 2072, 앱 ID와 서명키는 기존 개인용 빌드와 같다. 과거 kyk.1/kyk.2의 조합 확정 대기 방식은 현재 버전에 적용되지 않는다.
