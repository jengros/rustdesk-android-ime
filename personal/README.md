# RustDesk Personal Android

이 저장소는 공식 RustDesk 1.5.1 (`23e5bb471a040d62f0a6ad52591fb30784265b73`)에서 분기한 개인용 수정본이다.

## 수정 범위

- Android는 자체 빈 TextEditingController를 사용하며, 원본의 1 채움용 controller를 연결하지 않는다. 실제 문자열의 공통 부분과 바뀐 꼬리를 비교해 삭제·삽입을 전송한다.
- 한글 조합 중인 글자도 즉시 전송한다. `ㄱ → 가 → 가나다`처럼 같은 길이의 변경도 이전 글자를 지우고 새 글자로 갱신한다. 공백이나 Enter로 확정할 때까지 기다리지 않는다.
- Android 입력란의 raw Backspace는 직접 처리하고 handled로 종료한다. 빈 입력란의 Backspace도 PC에 이미 있던 글자를 삭제한다. Enter는 Android의 편집 결과에 실제 줄바꿈이 들어온 경우에만 전송한다. 다른 키 이벤트는 skipRemainingHandlers로 원격 물리 키 처리와 격리하고 Android 자체 편집은 허용한다.
- 새 글자는 Unicode 문자열 경로로 보낸다. 새 입력 위젯은 Android에만 연결하며 기존 iOS 및 소프트 키보드를 닫은 상태의 물리 키 경로는 유지한다.
- 앱 ID: `com.carriez.flutter_hbb.kykpersonal`, 표시 이름: `RustDesk Personal`. 공식 앱과 함께 설치할 수 있다.

현재 버전은 `1.5.1-kyk.7`이다. kyk.6은 원본 SVG 도형을 유지하고 파랑/청록 그라데이션만 주황색으로 바꾼 Android 런처 아이콘 업데이트이다. 원본 벡터는 `personal/icon-orange.svg`에 보관한다. Flutter의 실제 TextField에 IME 편집 값과 raw 키를 전달하는 입력 테스트 6개로 Enter와 IME 확정 이벤트가 겹치는 순서, 중복 확정 알림, 연속 줄바꿈, 즉시 한글 갱신, 초기 버퍼 없음, 기존 PC 문자 삭제, 로컬 문자 삭제, 반복 삭제, Enter, 숫자 1 입력을 검증했다. 소프트 키보드가 열린 상태의 외부 물리 키보드 단축키는 별도 현장 검증 대상이다. 휴대폰은 연결하지 않았으며, 사용자가 갤럭시 휴대폰과 삼성 키보드에서 직접 검증하여 개선을 확인했다.

## Android 입력 방식 선택 (kyk.7)

키보드를 열면 입력줄 왼쪽 아이콘을 누를 때마다 `실시간 입력`과 `텍스트 전송`을 전환한다. 팝업 메뉴가 Android IME 포커스를 가져가는 문제를 피하기 위해 포커스를 빼앗지 않는 전환 버튼을 사용한다. 마지막 선택은 앱의 `personal-android-input-mode` 로컬 옵션에 저장한다. 옵션이 없거나 알려지지 않은 값이면 기존 실시간 입력을 사용한다.

- 실시간 입력: 기존 한글 조합/삭제/엔터 전송을 유지한다.
- 텍스트 전송: 입력칸에서 작성·수정한 내용은 전송하지 않는다. 휴대폰 키보드의 전송(Enter) 동작에서 완성된 문자열을 한 번 전송하며 원격 Enter를 덧붙이지 않는다.
- 우측 Backspace/Enter 버튼: 입력칸 내용을 건드리지 않고 원격 키만 전송한다.
- 미전송 문구는 같은 세션에서 키보드를 숨기거나 모드를 전환해도 보존한다. 세션을 종료하면 폐기한다. 로컬 디스크에는 문구를 저장하지 않는다.
- 전송 중 중복 제출을 막고, FFI 전송 작업이 정상 완료된 경우에만 문구를 비운다. 이는 네이티브 전송 큐 등록 완료이며 PC 애플리케이션의 수신 확인은 아니다. 실패/권한 차단에서는 문구를 유지한다.
- 두 모드는 하나의 TextField/IME 연결을 유지한다. 입력줄은 원격 포인터 처리 영역 밖에 배치하여 입력줄 터치가 PC 클릭으로 전달되지 않도록 한다.

기존 6개와 신규 3개 테스트로 조합 중 미전송, 한 번 전송/원격 Enter 없음, 모드 전환 후 입력, 미전송 문구 보존, 우측 원격 키, 전송 미완료/차단, 좁은 화면의 레이아웃을 검증했다. Android API 30 x86_64 에뮬레이터에서 실제 InputConnection 조합 이벤트를 보내 VM 101의 Windows 메모장 결과를 비교한 20개 통합 확인도 통과했다. 한글 조합, 전송 전 미반영, 정확히 한 번 전송, 연속 전송, 원격 Backspace/Enter, 로컬 삭제, 모드 왕복과 초안 보존을 확인했다. 실제 실행에서 발견한 모드 전환 시 IME 포커스 손실은 전환 버튼의 ExcludeFocus와 입력줄 전체의 TextFieldTapRegion으로 수정했고, 수정 전 실패한 마우스 포인터 회귀 테스트가 수정 후 통과했다. 앱 재시작 후 선택 복원은 에뮬레이터에서 확인했다. 신규 모드의 실제 갤럭시 삼성 키보드 이벤트와 ARM64 실기기 동작은 휴대폰에서 확인해야 한다. 이전 한글 수정에 대한 사용자 검증과 신규 모드 검증을 구분한다.

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

`personal/build-android.ps1`은 이 PC에 준비한 도구 폴더를 사용한다. 의존성 확인, 9개 회귀 테스트, 변경 파일 분석, arm64 release APK 생성을 순서대로 수행한다.

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

## 개인용 네 번째 빌드: Enter 문장 중복 전송 수정

사용자가 한 문장을 입력한 뒤 Enter를 누르면 동일한 문장이 두 줄 나타나는 현상을 보고했다. kyk.3은 raw Enter에서 Enter를 즉시 전송한 뒤 controller와 비교 기준을 비웠고, IME 편집에서도 줄바꿈 후 기준을 비웠다. 이후 IME가 전체 문장 값을 전달하면 이미 보낸 문장도 새 입력으로 다시 전송될 수 있었다.

kyk.4는 Enter 전송을 IME 편집 경로 하나로 통일하고, 줄바꿈 후에도 전체 비교 기준을 유지한다. raw Enter는 Android의 정상 편집 경로로 전달한다. Android에서 Enter가 실제 편집 값으로 돌아와야 전송되므로 삼성 실기기의 이벤트 전달 여부는 후속 확인 대상이다. 키보드를 닫았다 열면 위젯의 빈 buffer로 다시 시작한다.

보내주신 `abc 가나다 동해물과 백두산이` 문장으로 raw Enter/IME 확정의 두 순서, 반복 확정 통지, 의도한 두 번째 Enter, 그 이후 문자와 Backspace를 위젯 테스트로 검증했다. 기존 조합·숫자 1·삭제 테스트도 통과했다. 테스트는 실제 Android IME나 PC까지 연결한 검증이 아니다.

분석 중 줄바꿈 문자열 자체가 잘못되었다고 설명했으나, 바이트 재확인 결과 원래 코드도 실제 LF를 뜻하는 정상적인 Dart escape였다. 해당 설명은 정정하며, 수정 대상은 중복 처리와 기준 문장 초기화이다.

기본 build number 73, ARM64 split APK versionCode 2073, 버전 이름 `1.5.1-kyk.4`. 접근성 서비스 제거와 기존 개인용 앱 ID·서명키를 유지한다.

## 개인용 다섯 번째 빌드: 빠른 입력의 전송 순서 보장

사용자는 빠른 한글 입력에서 중간 글자가 빠지고, 공식 앱과 달리 수정 앱의 글자 반영만 느리다고 보고했다. 영상 전체의 지연이라고 보고한 것은 아니다.

기존 콜백은 삭제와 Unicode 입력의 Future를 기다리지 않았다. 생성된 Flutter/Rust bridge는 FfiCallMode::Normal과 DefaultHandler를 사용하며, flutter_rust_bridge 1.80.1의 기본 handler는 thread pool에서 각 호출을 처리한다. 따라서 `삭제 → 대체 글자`의 enqueue 순서를 명시적으로 보장해야 한다.

kyk.5는 Android 소프트 키보드의 문자·Backspace·Enter를 세션별 큐에 넣고, 앞 FFI 호출이 반환한 뒤 다음 호출을 실행한다. 이 완료는 PC 화면에 표시됐다는 응답이 아니라 Rust 세션의 전송 채널에 enqueue한 시점이다. 키 입력 당시의 세션 ID와 modifier 상태를 캡처한다. 원격 화면을 닫으면 남은 큐를 취소하고, 전송 오류 후에는 자동 재시도 없이 후속 입력을 중단하고 재연결 안내를 표시한다.

삭제 처리에 더 긴 비동기 지연을 넣어 완료 순서를 뒤집을 수 있는 조건에서도 빠른 한글 대체가 순서대로 처리되는지 검증했다. 동시에 실행되는 전송은 최대 1개였고 최종 문자열이 일치했다. 실패·닫힌 큐의 후속 전송 차단과 기존 4개 입력 위젯 테스트를 포함해 6개가 통과했다. 실제 삼성 키보드의 누락과 체감 지연이 해결됐는지는 휴대폰 후속 확인 대상이다. 영상·해상도·프레임 설정은 변경하지 않았다.

기본 build number 74, ARM64 split APK versionCode 2074, 버전 이름 `1.5.1-kyk.5`. 같은 앱 ID·서명과 접근성 서비스 제거를 유지한다.

브리지 처리 근거: https://github.com/fzyzcjy/flutter_rust_bridge/blob/v1.80.1/frb_rust/src/handler.rs
