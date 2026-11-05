package de.robv.android.xposed;

/** 编译期桩代码。 */
public abstract class XC_MethodReplacement extends XC_MethodHook {
    public static XC_MethodReplacement returnConstant(Object result) { throw new UnsupportedOperationException(); }
}
