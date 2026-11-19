import java.lang.reflect.*;

public class Set4KHDR {
    public static void main(String[] args) {
        try {
            System.loadLibrary("android_servers");
            Class<?> dc = Class.forName("com.android.server.display.DisplayControl");
            Class<?> ibinderCls = Class.forName("android.os.IBinder");
            Class<?> sc = Class.forName("android.view.SurfaceControl");
            Class<?> specsCls = Class.forName("android.view.SurfaceControl$DesiredDisplayModeSpecs");

            Method getIds = dc.getDeclaredMethod("getPhysicalDisplayIds");
            long[] ids = (long[]) getIds.invoke(null);
            Method getToken = dc.getDeclaredMethod("getPhysicalDisplayToken", long.class);
            Method getSpecs = sc.getDeclaredMethod("getDesiredDisplayModeSpecs", ibinderCls);
            Method setSpecs = sc.getDeclaredMethod("setDesiredDisplayModeSpecs", ibinderCls, Array.newInstance(specsCls, 0).getClass());
            Method overrideHdr = dc.getDeclaredMethod("overrideHdrTypes", ibinderCls, int[].class);

            for (long id : ids) {
                if (id != 4619827078044484352L) {
                    Object token = getToken.invoke(null, id);
                    // 1. Override HDR types first
                    overrideHdr.invoke(null, token, new int[]{1, 2, 3, 4});
                    Thread.sleep(1000);

                    // 2. Now set DesiredDisplayModeSpecs to Mode 0 (3840x2160 @ 60Hz)
                    Object specs = getSpecs.invoke(null, token);
                    Field defaultModeField = specsCls.getDeclaredField("defaultMode");
                    Field tokenField = specsCls.getDeclaredField("displayToken");
                    Field allowGroupField = specsCls.getDeclaredField("allowGroupSwitching");
                    defaultModeField.setInt(specs, 0); // Mode 0 = 3840x2160 @ 60Hz
                    tokenField.set(specs, token);
                    allowGroupField.setBoolean(specs, true);

                    Object specsArray = Array.newInstance(specsCls, 1);
                    Array.set(specsArray, 0, specs);
                    Object res = setSpecs.invoke(null, token, specsArray);
                    System.out.println("setDesiredDisplayModeSpecs result: " + res);
                    Thread.sleep(1000);
                    System.out.println("After 1s specs: " + getSpecs.invoke(null, token));
                }
            }
        } catch (Throwable t) {
            t.printStackTrace(System.out);
        }
    }
}
