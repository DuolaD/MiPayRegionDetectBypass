package de.robv.android.xposed;

/** 编译期桩代码。 */
public abstract class XC_MethodHook {
    public class Unhook {}

    public static class MethodHookParam {
        public Object[] args;
        public Object getResult() { throw new UnsupportedOperationException(); }
        public void setResult(Object result) { throw new UnsupportedOperationException(); }
    }
}
