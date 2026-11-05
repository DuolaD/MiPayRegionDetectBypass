package com.fixmipay.regionbypass;

import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodReplacement;
import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage;

/**
 * 解除 HyperOS 国际版对“双击电源键唤起刷卡页”(mi_pay) 的地区限制。
 *
 * 系统框架 (miui-services.jar) 在以下两处调用地区判断：
 *   1. ShortCutActionsUtils.triggerFunction()：双击时若两项都为 false，打印
 *      "Region restriction: mi_pay" 并直接返回，不启动小米智能卡。
 *   2. ShortcutFunctionManager（经 MiuiSingleKeyObserver.setDefaultFunction）：
 *      开机时判定 mi_pay 不可用，把 double_click_power_key 清空，导致开关被重置。
 *
 * 两处都是 `isCnRegionWithCardSupport() || isInternationalRegionWithCardSupport()`，
 * 且这两个方法在整个系统框架中只被上述两处调用，所以只改它们的返回值，影响面最小。
 * 两个都 hook：前者方法体很小，可能被 ART 内联进调用方导致 hook 失效，后者作兜底。
 */
public class HookEntry implements IXposedHookLoadPackage {

    private static final String TAG = "FixMiPayRegionBypass: ";
    private static final String FEATURE_CLASS = "miui.hardware.input.shortcut.MiInputShortcutFeature";
    private static final String[] METHODS = {
            "isCnRegionWithCardSupport",
            "isInternationalRegionWithCardSupport",
    };

    @Override
    public void handleLoadPackage(XC_LoadPackage.LoadPackageParam lpparam) {
        if (!"android".equals(lpparam.packageName)) {
            return;
        }
        Class<?> feature = XposedHelpers.findClassIfExists(FEATURE_CLASS, lpparam.classLoader);
        if (feature == null) {
            XposedBridge.log(TAG + FEATURE_CLASS + " not found, skip");
            return;
        }
        for (String name : METHODS) {
            try {
                XposedHelpers.findAndHookMethod(feature, name, XC_MethodReplacement.returnConstant(true));
                XposedBridge.log(TAG + "hooked " + name);
            } catch (Throwable t) {
                XposedBridge.log(TAG + "failed to hook " + name + ": " + t);
            }
        }
    }
}
