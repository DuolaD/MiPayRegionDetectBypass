package de.robv.android.xposed.callbacks;

/** 编译期桩代码。 */
public abstract class XC_LoadPackage {
    public static final class LoadPackageParam {
        public String packageName;
        public ClassLoader classLoader;
    }
}
