package de.robv.android.xposed;

/** 编译期桩代码。 */
public final class XposedBridge {
    public static void log(String text) { throw new UnsupportedOperationException(); }
}
