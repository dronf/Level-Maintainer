package dev.dronf.neilevel;

import java.lang.reflect.Field;
import net.minecraft.client.gui.*;

/** Regression against the actual installed lwjgl3ify StringBuilder. */
public final class SharedBufferTest {
    public static void main(String[] args)throws Exception {
        Class<?> unsafeType=Class.forName("sun.misc.Unsafe");Field singleton=unsafeType.getDeclaredField("theUnsafe");singleton.setAccessible(true);
        FontRenderer font=(FontRenderer)unsafeType.getMethod("allocateInstance",Class.class).invoke(singleton.get(null),FieldFocusTest.TestFont.class);
        GuiTextField f=new GuiTextField(font,0,0,90,18);
        FieldFocus input=new FieldFocus(new GuiTextField[]{f},new boolean[]{true});input.focus(0,true);
        StringBuilder shared=(StringBuilder)Class.forName("me.eigenraven.lwjgl3ify.client.TextFieldHandler").getField("textBuffer").get(null);
        shared.append("123");input.key((char)0,2);input.key('1',0);
        if(shared.length()!=0)throw new AssertionError("Numeric text remains queued for NEI: "+shared);
        if(!f.func_146179_b().equals("1"))throw new AssertionError("Expected one digit");
        System.out.println("PASS: installed lwjgl3ify numeric buffer leak regression");
    }
}
