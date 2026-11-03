# RustDesk Personal Android

이 저장소는 공식 RustDesk 1.5.1 (`23e5bb471a040d62f0a6ad52591fb30784265b73`)에서 분기한 개인용 수정본이다.

## 수정 범위

- Android 숨겨진 입력란의 글자 수 비교 대신 실제 문자열 차이를 계산한다.
- 한글 조합 중인 부분은 보내지 않고 확정된 문자열만 보낸다. 내용은 같고 조합 범위만 해제된 이벤트도 controller listener로 받는다.
- Android 입력란 안의 키 이벤트는 `skipRemainingHandlers`로 차단하여 상위의 원격 물리 키 처리와 중복되지 않게 한다. Android 자체의 편집 처리는 허용한다.
- 확정된 한글은 문자열 전송 경로를 사용한다. 기존 iOS 및 소프트 키보드를 닫은 상태의 물리 키 경로는 유지한다.
- 앱 ID: `com.carriez.flutter_hbb.kykpersonal`, 표시 이름: `RustDesk Personal`. 공식 앱과 함께 설치할 수 있다.

한글 마지막 음절은 키보드가 조합을 확정할 때 PC에 나타난다. 필요하면 공백이나 Enter로 확정한다. 소프트 키보드가 열린 상태의 외부 물리 키보드 단축키는 별도 현장 검증 대상이다. 휴대폰은 연결하지 않았으며 실제 삼성 키보드에서의 개선 여부는 미확인이다.

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
