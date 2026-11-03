param(
    [switch]$SkipChecks,
    [string]$ToolRoot = 'E:\workspace\doc\chatgpt\codex\.tmp\rustdesk-tools'
)
$ErrorActionPreference = 'Stop'
$toolRoot = [IO.Path]::GetFullPath($ToolRoot)
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$env:JAVA_HOME = "$toolRoot\jdk17\jdk-17.0.17+10"
$env:ANDROID_HOME = "$toolRoot\android-sdk"
$env:ANDROID_USER_HOME = "$toolRoot\android-user"
$env:PUB_CACHE = "$toolRoot\pub-cache"
$env:GRADLE_USER_HOME = "$toolRoot\gradle-cache"
New-Item -ItemType Directory -Force -Path $env:GRADLE_USER_HOME | Out-Null
@'
org.gradle.jvmargs=-Xmx4096M -Dfile.encoding=UTF-8
org.gradle.workers.max=2
kotlin.daemon.jvmargs=-Xmx1024M
'@ | Set-Content -LiteralPath "$env:GRADLE_USER_HOME\gradle.properties" -Encoding utf8
$env:ORG_GRADLE_PROJECT_personalBuild = 'true'
$env:ORG_GRADLE_PROJECT_rustlsAndroidMavenDir = "$toolRoot\rustls-platform-verifier-android-0.1.1\maven"
$env:PATH = "$toolRoot\flutter\bin;$env:JAVA_HOME\bin;$env:PATH"
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:DART_SUPPRESS_ANALYTICS = 'true'
$relocated = @()
function Run-Step($name, [scriptblock]$command) {
    Set-Content -LiteralPath "$toolRoot\build-status.txt" -Value $name
    & $command *> "$toolRoot\$name.log"
    if ($LASTEXITCODE -ne 0) {
        Get-Content -LiteralPath "$toolRoot\$name.log" -Tail 55
        throw "$name failed (exit $LASTEXITCODE)"
    }
    Get-Content -LiteralPath "$toolRoot\$name.log" -Tail 8
}
try {
    # These desktop folders trigger symlink creation on Windows, which needs
    # Developer Mode. Temporarily hide only our new checkout's desktop targets.
    foreach ($platform in @('windows', 'linux')) {
        $sourcePath = [IO.Path]::GetFullPath("$repoRoot\flutter\$platform")
        $tempPath = [IO.Path]::GetFullPath("$repoRoot\flutter\$platform.personal-build-disabled")
        if (!$sourcePath.StartsWith("$repoRoot\flutter\") -or
            !$tempPath.StartsWith("$repoRoot\flutter\") -or
            (Test-Path -LiteralPath $tempPath)) { throw 'Unexpected desktop target path' }
        if (Test-Path -LiteralPath $sourcePath) {
            Move-Item -LiteralPath $sourcePath -Destination $tempPath
            $relocated += @{ Source=$sourcePath; Temp=$tempPath }
        }
    }
    Set-Location -LiteralPath "$repoRoot\flutter"
    if (!$SkipChecks) {
        Run-Step 'pub-get' { & "$toolRoot\flutter\bin\flutter.bat" pub get }
        Run-Step 'regression-tests' { & "$toolRoot\flutter\bin\flutter.bat" test --no-pub test/android_soft_keyboard_test.dart }
        Run-Step 'analyze-personal' { & "$toolRoot\flutter\bin\flutter.bat" analyze --no-pub --no-fatal-infos --no-fatal-warnings lib/mobile/android_soft_keyboard.dart lib/mobile/pages/remote_page.dart test/android_soft_keyboard_test.dart }
    }
    Run-Step 'build-apk' { & "$toolRoot\flutter\bin\flutter.bat" build apk --no-pub --release --target-platform android-arm64 --split-per-abi --build-name 1.5.1-kyk.4 --build-number 73 -P 'personalBuild=true' -P "rustlsAndroidMavenDir=$env:ORG_GRADLE_PROJECT_rustlsAndroidMavenDir" }
    Set-Content -LiteralPath "$toolRoot\build-status.txt" -Value 'APK built'
} finally {
    Set-Location -LiteralPath $repoRoot
    foreach ($entry in $relocated) {
        if (Test-Path -LiteralPath $entry.Temp) {
            Move-Item -LiteralPath $entry.Temp -Destination $entry.Source
        }
    }
}
