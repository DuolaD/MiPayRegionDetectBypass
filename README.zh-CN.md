# MiPayRegionDetectBypass

[English](README.md) | **简体中文** | [繁體中文](README.zh-TW.md)

一个 LSPosed 模块，用来解除较新非国行 HyperOS 3 对“双击电源键唤起刷卡页”的地区限制。

## 背景

在较新的国际版及其他非国行 HyperOS 3 上，系统框架会先判断设备地区，才决定双击电源键能不能打开小米智能卡刷卡页（`mi_pay`）。判断不通过时：

1. 双击电源键，框架打印 `Region restriction: mi_pay` 后直接返回，什么也不发生。
2. 开机时框架认为 `mi_pay` 不可用，把 `double_click_power_key` 清空，所以设置好的快捷方式会被反复重置。

装上模块后，这两处判断都会通过。

## 使用条件

- 运行非国行 HyperOS 3 的小米 / Redmi / POCO 设备
- Android 11（API 30）及以上
- 已 Root 并安装 [LSPosed](https://github.com/LSPosed/LSPosed)（或兼容分支）

## 安装

1. 从 [Releases](https://github.com/DuolaD/MiPayRegionDetectBypass/releases) 下载最新 APK。
2. 安装后在 LSPosed 中启用模块。
3. 确认作用域勾选了 **系统框架**（`android`），默认已勾选。
4. 重启手机。
5. 在设置里把“双击电源键”快捷方式设为小米智能卡。多数版本在“更多设置 → 快捷手势”下。

模块本身没有界面，也没有设置项。想确认是否生效，可以在 LSPosed 日志里搜 `MiPayRegionDetectBypass`，正常会看到 `hooked isCnRegionWithCardSupport` 和 `hooked isInternationalRegionWithCardSupport` 两行。

## 原理

上面两处判断都在 `miui-services.jar` 里：

- `ShortCutActionsUtils.triggerFunction()`：双击电源键时调用
- `ShortcutFunctionManager`：开机时经 `MiuiSingleKeyObserver.setDefaultFunction` 调用

两处用的是同一个条件：

```java
isCnRegionWithCardSupport() || isInternationalRegionWithCardSupport()
```

这两个方法都属于 `miui.hardware.input.shortcut.MiInputShortcutFeature`，整个系统框架里只有上面两处调用它们。模块只把它们的返回值改成 `true`，改动范围尽量小。

两个方法都 hook，是因为前一个方法体很小，ART 可能把它内联进调用方，这时 hook 不会生效，后一个用来兜底。

模块只去掉了地区判断。小米智能卡本身（卡包 App、NFC、能添加哪些卡）在你所在地区能不能用，是另一回事。

## 自行构建

不依赖 Gradle，`build.sh` 直接调用 Android SDK 命令行工具打包。

需要：

- JDK 17+
- Android SDK（`build-tools` 和 `platforms` 各装一个即可）

```bash
ANDROID_HOME=/path/to/android-sdk ./build.sh
```

APK 输出到 `out/`。可用的环境变量：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `ANDROID_HOME` | `/opt/homebrew/share/android-commandlinetools` | SDK 根目录 |
| `JAVA_HOME` | `PATH` 里的 `javac` | JDK 根目录 |
| `KEYSTORE` | `~/.android/debug.keystore` | 签名用的 keystore，不存在时自动生成调试密钥 |
| `KS_PASS` / `KS_ALIAS` | `android` / `androiddebugkey` | keystore 密码和密钥别名 |
| `VERSION_NAME` | `1.0.0` | 版本名，开头的 `v` 会被去掉 |
| `VERSION_CODE` | 由 `VERSION_NAME` 换算 | `x.y.z` 换算为 `x*10000 + y*100 + z` |

`stubs/` 下的 Xposed API 桩代码只参与编译，不会打进 dex。

### Release 自动构建

在 GitHub 发布 Release 会触发 [`.github/workflows/release.yml`](.github/workflows/release.yml)，以 Release Tag 作为版本名构建 APK 并上传到该 Release。

如果要用固定密钥签名，在仓库 Secrets 里配置：

- `SIGNING_KEYSTORE_BASE64`：keystore 文件的 base64 编码
- `SIGNING_KEYSTORE_PASSWORD`
- `SIGNING_KEY_ALIAS`

没配置时，CI 会用临时生成的调试密钥签名，每个版本签名都不同，不能覆盖安装。

## 免责声明

本模块会修改系统框架行为，使用风险自负。

## 许可证

[MIT](LICENSE)
