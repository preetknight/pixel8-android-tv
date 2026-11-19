import java.lang.reflect.*;

public class Keep4KHDR {
    static int findBestModeId(Object dynInfo) {
        try {
            Field modesField = dynInfo.getClass().getDeclaredField("supportedDisplayModes");
            Object[] modes = (Object[]) modesField.get(dynInfo);
            if (modes == null || modes.length == 0) return 0;

            int bestId = 0;
            long bestScore = -1;
            for (Object m : modes) {
                Class<?> mc = m.getClass();
                int id = mc.getDeclaredField("id").getInt(m);
                int w = mc.getDeclaredField("width").getInt(m);
                int h = mc.getDeclaredField("height").getInt(m);
                float fps = 60.0f;
                try {
                    fps = mc.getDeclaredField("peakRefreshRate").getFloat(m);
                } catch (Throwable ignored) {
                    try { fps = mc.getDeclaredField("vsyncRate").getFloat(m); } catch (Throwable ignored2) {}
                }
                // Prefer 3840x2160 over 4096x2160/1080p, and ~60Hz over 30Hz/24Hz
                long pixels = (long) w * h;
                if (w == 3840 && h == 2160) pixels += 100_000_000L;
                int hzBonus = (fps >= 59.0f && fps <= 61.0f) ? 10_000_000 : (int) (fps * 1000);
                long score = pixels + hzBonus;
                if (score > bestScore) {
                    bestScore = score;
                    bestId = id;
                }
            }
            return bestId;
        } catch (Throwable t) {
            return 0;
        }
    }

    public static void main(String[] args) {
        try {
            System.loadLibrary("android_servers");
            Class<?> dc = Class.forName("com.android.server.display.DisplayControl");
            Class<?> ibinderCls = Class.forName("android.os.IBinder");
            Class<?> sc = Class.forName("android.view.SurfaceControl");
            Class<?> specsCls = Class.forName("android.view.SurfaceControl$DesiredDisplayModeSpecs");

            Method getIds = dc.getDeclaredMethod("getPhysicalDisplayIds");
            Method getToken = dc.getDeclaredMethod("getPhysicalDisplayToken", long.class);
            Method getSpecs = sc.getDeclaredMethod("getDesiredDisplayModeSpecs", ibinderCls);
            Method setSpecs = sc.getDeclaredMethod("setDesiredDisplayModeSpecs", ibinderCls, Array.newInstance(specsCls, 0).getClass());
            Method overrideHdr = dc.getDeclaredMethod("overrideHdrTypes", ibinderCls, int[].class);
            Method getDynInfo = sc.getDeclaredMethod("getDynamicDisplayInfo", long.class);

            Field defaultModeField = specsCls.getDeclaredField("defaultMode");
            Field tokenField = specsCls.getDeclaredField("displayToken");
            Field allowGroupField = specsCls.getDeclaredField("allowGroupSwitching");

            long lastHandledId = -1;
            while (true) {
                long[] ids = (long[]) getIds.invoke(null);
                boolean foundExternal = false;
                for (long id : ids) {
                    if (id != 4619827078044484352L) {
                        foundExternal = true;
                        Object token = getToken.invoke(null, id);
                        if (id != lastHandledId) {
                            overrideHdr.invoke(null, token, new int[]{1, 2, 3, 4});
                            lastHandledId = id;
                            Thread.sleep(500);
                        }
                        Object dynInfo = getDynInfo.invoke(null, id);
                        if (dynInfo != null) {
                            int targetMode = findBestModeId(dynInfo);
                            Field activeModeField = dynInfo.getClass().getDeclaredField("activeDisplayModeId");
                            int activeMode = activeModeField.getInt(dynInfo);
                            if (activeMode != targetMode) {
                                Object specs = getSpecs.invoke(null, token);
                                defaultModeField.setInt(specs, targetMode);
                                tokenField.set(specs, token);
                                allowGroupField.setBoolean(specs, false);
                                Object specsArray = Array.newInstance(specsCls, 1);
                                Array.set(specsArray, 0, specs);
                                setSpecs.invoke(null, token, specsArray);
                                System.out.println("Restored best mode " + targetMode + " on display " + id);
                            }
                        }
                    }
                }
                if (!foundExternal) {
                    lastHandledId = -1;
                }
                Thread.sleep(500);
            }
        } catch (Throwable t) {
            t.printStackTrace(System.out);
        }
    }
}
