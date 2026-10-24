package dev.dronf.neilevel;

import li.cil.oc.client.ComponentTracker;
import li.cil.oc.common.component.TextBuffer;
import li.cil.oc.api.network.ManagedEnvironment;
import net.minecraft.client.Minecraft;
import scala.Option;

public final class ScreenReader {
    private ScreenReader() { }
    public static String read(String address) {
        Option<ManagedEnvironment> found=ComponentTracker.get(Minecraft.func_71410_x().field_71441_e,address);
        if(found.isEmpty() || !(found.get() instanceof TextBuffer)) return "";
        li.cil.oc.util.TextBuffer data=((TextBuffer)found.get()).data();
        int w=data.width(),h=data.height();
        if(w<1||h<1||w*h>100000) return "";
        StringBuilder text=new StringBuilder(w*h);
        for(int y=0;y<h;y++)for(int x=0;x<w;x++){
            text.appendCodePoint(data.get(x,y));
            if(text.length()==5&&!text.toString().matches("LM[234]R\\|"))return "";
            int n=text.length();
            if(n>=4&&text.charAt(n-4)=='|'&&text.charAt(n-3)=='E'&&text.charAt(n-2)=='N'&&text.charAt(n-1)=='D')return text.toString();
        }
        return text.toString();
    }
}
