# MiPayRegionDetectBypass

[English](README.md) | [简体中文](README.zh-CN.md) | **繁體中文**

一個 LSPosed 模組，用來解除較新非中國版 HyperOS 3 對「按兩下電源鍵開啟刷卡頁面」的地區限制。

## 背景

在較新的國際版及其他非中國版 HyperOS 3 上，系統框架會先判斷裝置地區，才決定按兩下電源鍵能不能開啟小米智慧卡刷卡頁面（`mi_pay`）。判斷不通過時：

1. 按兩下電源鍵，框架輸出 `Region restriction: mi_pay` 後直接返回，什麼也不會發生。
2. 開機時框架認為 `mi_pay` 無法使用，把 `double_click_power_key` 清空，所以設定好的快捷方式會一再被重設。

裝上模組後，這兩處判斷都會通過。

## 使用條件

- 執行非中國版 HyperOS 3 的小米 / Redmi / POCO 裝置
- Android 11（API 30）以上
- 已 Root 並安裝 [LSPosed](https://github.com/LSPosed/LSPosed)（或相容分支）

## 安裝

1. 從 [Releases](https://github.com/DuolaD/MiPayRegionDetectBypass/releases) 下載最新 APK。
2. 安裝後在 LSPosed 中啟用模組。
3. 確認作用域已勾選 **系統框架**（`android`），預設會勾選。
4. 重新開機。
5. 在設定中把「按兩下電源鍵」快捷方式設為小米智慧卡。多數版本位於「更多設定 → 快捷手勢」。

模組本身沒有介面，也沒有設定項。想確認是否生效，可以在 LSPosed 日誌中搜尋 `MiPayRegionDetectBypass`，正常會看到 `hooked isCnRegionWithCardSupport` 和 `hooked isInternationalRegionWithCardSupport` 兩行。

## 原理

上面兩處判斷都在 `miui-services.jar` 裡：

- `ShortCutActionsUtils.triggerFunction()`：按兩下電源鍵時呼叫
- `ShortcutFunctionManager`：開機時經 `MiuiSingleKeyObserver.setDefaultFunction` 呼叫

兩處用的是同一個條件：

```java
isCnRegionWithCardSupport() || isInternationalRegionWithCardSupport()
```

這兩個方法都屬於 `miui.hardware.input.shortcut.MiInputShortcutFeature`，整個系統框架中只有上面兩處呼叫它們。模組只把它們的回傳值改成 `true`，盡量縮小改動範圍。

兩個方法都 hook，是因為前一個方法本體很小，ART 可能把它內嵌進呼叫端，這時 hook 不會生效，後一個用來補位。

模組只拿掉了地區判斷。小米智慧卡本身（卡包 App、NFC、能新增哪些卡）在你所在的地區能不能用，是另一回事。

## 自行建置

不依賴 Gradle，`build.sh` 直接呼叫 Android SDK 命令列工具打包。

需要：

- JDK 17+
- Android SDK（`build-tools` 和 `platforms` 各安裝一個即可）

```bash
ANDROID_HOME=/path/to/android-sdk ./build.sh
```

APK 輸出到 `out/`。可用的環境變數：

| 變數 | 預設值 | 說明 |
| --- | --- | --- |
| `ANDROID_HOME` | `/opt/homebrew/share/android-commandlinetools` | SDK 根目錄 |
| `JAVA_HOME` | `PATH` 中的 `javac` | JDK 根目錄 |
| `KEYSTORE` | `~/.android/debug.keystore` | 簽署用的 keystore，不存在時自動產生偵錯金鑰 |
| `KS_PASS` / `KS_ALIAS` | `android` / `androiddebugkey` | keystore 密碼和金鑰別名 |
| `VERSION_NAME` | `1.0.0` | 版本名稱，開頭的 `v` 會被去掉 |
| `VERSION_CODE` | 由 `VERSION_NAME` 換算 | `x.y.z` 換算為 `x*10000 + y*100 + z` |

`stubs/` 下的 Xposed API 樁程式碼只參與編譯，不會打包進 dex。

### Release 自動建置

在 GitHub 發布 Release 會觸發 [`.github/workflows/release.yml`](.github/workflows/release.yml)，以 Release Tag 作為版本名稱建置 APK 並上傳到該 Release。

如果要用固定金鑰簽署，請在儲存庫 Secrets 中設定：

- `SIGNING_KEYSTORE_BASE64`：keystore 檔案的 base64 編碼
- `SIGNING_KEYSTORE_PASSWORD`
- `SIGNING_KEY_ALIAS`

未設定時，CI 會用臨時產生的偵錯金鑰簽署，每個版本的簽章都不同，無法覆蓋安裝。

## 免責聲明

本模組會修改系統框架行為，使用風險自負。

## 授權條款

[MIT](LICENSE)
