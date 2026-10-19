package dev.dronf.neilevel;

import li.cil.oc.Settings$;
import li.cil.oc.client.PacketSender;
import li.cil.oc.client.PacketSender$;

/** Calls OC 1.12.64-GTNH's public Scala Java forwarder; no custom network channel. */
public final class ClipboardTransport {
    private ClipboardTransport() { }
    public static void send(String screen, String message) {
        if (message.length() > Settings$.MODULE$.get().maxClipboardLength())
            throw new IllegalArgumentException("Command exceeds the OC clipboard limit.");
        if (System.currentTimeMillis() < PacketSender$.MODULE$.clipboardCooldown())
            throw new IllegalStateException("OC clipboard is cooling down; try again shortly.");
        PacketSender.sendClipboard(screen, message);
    }
}
