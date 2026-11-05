# MiPayRegionDetectBypass

**English** | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md)

An LSPosed module that removes the region check on the "double-press power button to open Mi Pay" shortcut in newer non-China HyperOS 3 builds.

## Background

On recent global and other non-China HyperOS 3 ROMs, the system framework checks the device region before it lets the power button double-press open the Mi Pay card page (`mi_pay`). If the check fails, two things happen:

1. When you double-press the power button, the framework logs `Region restriction: mi_pay` and does nothing.
2. At boot, the framework decides `mi_pay` is unavailable and clears `double_click_power_key`, so the shortcut you set keeps getting reset.

The module makes the framework pass this check in both places.

## Requirements

- A Xiaomi / Redmi / POCO device on non-China HyperOS 3
- Android 11 (API 30) or later
- Root with [LSPosed](https://github.com/LSPosed/LSPosed) (or a compatible fork) installed

## Installation

1. Download the latest APK from [Releases](https://github.com/DuolaD/MiPayRegionDetectBypass/releases).
2. Install it and enable the module in LSPosed.
3. Check that the scope includes **System Framework** (`android`). It should be selected by default.
4. Reboot.
5. In Settings, set the power button double-press shortcut to Mi Pay. On most builds it is under Additional settings → Gesture shortcuts.

The module has no UI or settings of its own. To confirm it loaded, search the LSPosed log for `MiPayRegionDetectBypass`. You should see `hooked isCnRegionWithCardSupport` and `hooked isInternationalRegionWithCardSupport`.

## How it works

Both checks above live in `miui-services.jar`:

- `ShortCutActionsUtils.triggerFunction()`, which runs when you double-press
- `ShortcutFunctionManager`, called at boot through `MiuiSingleKeyObserver.setDefaultFunction`

Both use the same condition:

```java
isCnRegionWithCardSupport() || isInternationalRegionWithCardSupport()
```

Both methods belong to `miui.hardware.input.shortcut.MiInputShortcutFeature`, and nothing else in the framework calls them. The module hooks them to return `true`, which keeps the change as narrow as possible.

The first method is very small, and ART may inline it into its callers, in which case its hook never fires. Hooking the second method as well covers that case.

This only lifts the region check. Whether Mi Pay itself (the card app, NFC, the cards you add) works in your region is a separate matter.

## Building

The build doesn't use Gradle. `build.sh` calls the Android SDK command-line tools directly.

Requirements:

- JDK 17+
- Android SDK with at least one `build-tools` and one `platforms` package

```bash
ANDROID_HOME=/path/to/android-sdk ./build.sh
```

The APK is written to `out/`. Environment variables you can set:

| Variable | Default | Description |
| --- | --- | --- |
| `ANDROID_HOME` | `/opt/homebrew/share/android-commandlinetools` | SDK root |
| `JAVA_HOME` | `javac` on `PATH` | JDK root |
| `KEYSTORE` | `~/.android/debug.keystore` | Signing keystore. A debug key is generated if it doesn't exist |
| `KS_PASS` / `KS_ALIAS` | `android` / `androiddebugkey` | Keystore password and key alias |
| `VERSION_NAME` | `1.0.0` | Version name. A leading `v` is stripped |
| `VERSION_CODE` | derived from `VERSION_NAME` | `x.y.z` becomes `x*10000 + y*100 + z` |

The Xposed API classes under `stubs/` are used only at compile time and are not packed into the dex.

### Release builds

Publishing a GitHub Release triggers [`.github/workflows/release.yml`](.github/workflows/release.yml). It builds the APK with the release tag as the version name and uploads it to that release.

To sign with a fixed key, add these repository secrets:

- `SIGNING_KEYSTORE_BASE64`: the keystore file, base64-encoded
- `SIGNING_KEYSTORE_PASSWORD`
- `SIGNING_KEY_ALIAS`

Without them, CI signs with a throwaway debug key. Each release then has a different signature, and you can't install one over another.

## Disclaimer

This module modifies system framework behavior. Use it at your own risk.

## License

[MIT](LICENSE)
