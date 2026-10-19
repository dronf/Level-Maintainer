package dev.dronf.neilevel;

import java.nio.charset.StandardCharsets;
import java.util.Locale;

/** PR #5-compatible updates and LM2 removal commands. */
public final class BridgeCommand {
    public static final long MAX = 1000000000000L;
    private BridgeCommand() { }

    public static String address(String input) {
        String value = input.trim().toLowerCase(Locale.ROOT);
        if (!value.matches("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"))
            throw new IllegalArgumentException("Enter the full OC screen UUID.");
        return value;
    }
    public static String item(String name, String low, String target, String batch) {
        return update("I", name, low, target, batch);
    }
    public static void name(String name) {
        if (name == null || name.isEmpty() || name.getBytes(StandardCharsets.UTF_8).length > 160)
            throw new IllegalArgumentException("Item name must be 1-160 UTF-8 bytes.");
        for (int i = 0; i < name.length(); i++) {
            if (name.charAt(i) == '|' || Character.isISOControl(name.charAt(i)))
                throw new IllegalArgumentException("Item name contains an unsupported character.");
        }
    }
    public static String update(String kind, String name, String low, String target, String batch) {
        name(name); kind(kind);
        long lo = number(low), ta = number(target), ba = number(batch);
        if (lo > ta || ba < 1)
            throw new IllegalArgumentException("Require low <= target and batch >= 1.");
        return "LM1|" + kind + "|" + name + "|" + lo + "|" + ta + "|" + ba;
    }
    public static String remove(String kind, String name) { kind(kind); name(name); return "LM2|D|" + kind + "|" + name; }
    private static void kind(String kind) { if (!"I".equals(kind) && !"F".equals(kind)) throw new IllegalArgumentException("Invalid entry type."); }
    private static long number(String input) {
        String s = input.trim();
        if (!s.matches("[0-9]{1,13}")) throw new IllegalArgumentException("Enter whole numbers, 0 to 10^12.");
        long n = Long.parseLong(s);
        if (n > MAX) throw new IllegalArgumentException("Amounts must be at most 10^12.");
        return n;
    }
}
