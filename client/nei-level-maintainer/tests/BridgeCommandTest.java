package dev.dronf.neilevel;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;

public final class BridgeCommandTest {
    private static int assertions;
    private static void check(boolean ok) { assertions++; if (!ok) throw new AssertionError(); }
    private static void reject(Runnable action) {
        try { action.run(); } catch (IllegalArgumentException expected) { assertions++; return; }
        throw new AssertionError("Accepted invalid command");
    }
    public static void main(String[] args) throws Exception {
        check(BridgeCommand.address(" ABCDEF00-0000-0000-0000-000000000001 ").equals("abcdef00-0000-0000-0000-000000000001"));
        reject(() -> BridgeCommand.address("------------------------------------"));
        reject(() -> BridgeCommand.address("1234"));
        check(BridgeCommand.item("Iron Ingot", "100", "200", "64").equals("LM1|I|Iron Ingot|100|200|64"));
        check(BridgeCommand.item("Test", "0", "1000000000000", "1000000000000").endsWith("|0|1000000000000|1000000000000"));
        reject(() -> BridgeCommand.item("Test", "201", "200", "1"));
        reject(() -> BridgeCommand.item("Test", "0", "200", "0"));
        reject(() -> BridgeCommand.item("Test", "-1", "200", "1"));
        reject(() -> BridgeCommand.item("Test", "0", "1000000000001", "1"));
        reject(() -> BridgeCommand.item("Test", "0", "200", "1000000000001"));
        reject(() -> BridgeCommand.item("Test", "0.5", "200", "1"));
        reject(() -> BridgeCommand.item("Test", "1e2", "200", "1"));
        reject(() -> BridgeCommand.item("Test", "9999999999999999999999", "200", "1"));
        for (String bad : new String[]{"", "Bad|Name", "Bad\nName", "Bad\rName", "Bad\u0000Name"})
            reject(() -> BridgeCommand.item(bad, "0", "200", "1"));
        StringBuilder unicode = new StringBuilder();
        for (int i=0; i<80; i++) unicode.append('\u00e9');
        check(BridgeCommand.item(unicode.toString(), "0", "200", "1").startsWith("LM1|I|"));
        unicode.append('\u00e9');
        reject(() -> BridgeCommand.item(unicode.toString(), "0", "200", "1"));
        // Feed commands created by the real Java encoder into the unchanged PR #5 Lua receiver.
        if (args.length > 0) Files.write(Paths.get(args[0]), (
            BridgeCommand.item("Iron Ingot", "100", "200", "64") + "\n" +
            BridgeCommand.item("Quote \" and slash \\", "0", "300", "1") + "\n" +
            BridgeCommand.item("Caf\u00e9", "1", "1000000000000", "1") + "\n").getBytes(StandardCharsets.UTF_8));
        System.out.println("Protocol checks passed: " + assertions);
    }
}
