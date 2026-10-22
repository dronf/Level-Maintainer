package dev.dronf.neilevel;

import java.io.*;
import java.lang.reflect.*;
import java.util.*;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.*;

/** Real manager controls with OC transport recorded instead of sent. */
public final class ManagerPauseTest {
    private static int checks;
    private static void check(boolean value){checks++;if(!value)throw new AssertionError("manager pause check "+checks);}
    private static Object allocate(Class<?> type)throws Exception {
        Class<?> u=Class.forName("sun.misc.Unsafe");Field f=u.getDeclaredField("theUnsafe");f.setAccessible(true);
        return u.getMethod("allocateInstance",Class.class).invoke(f.get(null),type);
    }
    private static Field property(String name)throws Exception {Field f=ManagerGui.class.getDeclaredField(name);f.setAccessible(true);return f;}
    private static GuiButton button(ManagerGui gui,int id)throws Exception {
        Field f=GuiScreen.class.getDeclaredField("field_146292_n");f.setAccessible(true);
        for(Object value:(List)f.get(gui))if(((GuiButton)value).field_146127_k==id)return (GuiButton)value;
        throw new AssertionError("missing button "+id);
    }
    private static void rebuild(ManagerGui gui)throws Exception {Method m=ManagerGui.class.getDeclaredMethod("rebuild");m.setAccessible(true);m.invoke(gui);}
    private static final class Recording implements ManagerGui.Channel {
        final List<String> commands=new ArrayList<>();int initializations;
        public void send(String address,String command){commands.add(command);}
        public void initialize(String address){initializations++;}
    }
    public static void main(String[] args)throws Exception {
        Minecraft mc=(Minecraft)allocate(Minecraft.class);
        mc.field_71466_p=(FontRenderer)allocate(FieldFocusTest.TestFont.class);
        Field data=Minecraft.class.getDeclaredField("field_71412_D");data.setAccessible(true);data.set(mc,new File(args[0]));
        Recording link=new Recording();
        ManagerGui gui=new ManagerGui("2ba877c7-82c0-42df-96e6-27c880772f9d",link);
        gui.func_146280_a(mc,640,360);
        List<MaintainedEntry> entries=(List<MaintainedEntry>)property("entries").get(gui);
        entries.add(new MaintainedEntry("I","Iron","100","200","64","2"));
        entries.add(new MaintainedEntry("F","Water","10","20","4","1",true));rebuild(gui);
        check(!button(gui,8).field_146124_l);
        check(button(gui,4).field_146126_j.equals("Remove"));
        gui.func_146284_a(button(gui,100));check(button(gui,8).field_146124_l&&button(gui,8).field_146126_j.equals("Pause"));
        gui.func_146284_a(button(gui,8));check(link.commands.get(0).equals("LM2|P|I|Iron|1"));
        check(link.initializations==1&&!button(gui,8).field_146124_l);
        check(!entries.get(0).paused); // wait for authoritative refreshed state
        property("syncing").setBoolean(gui,false);rebuild(gui);
        gui.func_146284_a(button(gui,101));check(button(gui,8).field_146126_j.equals("Resume"));
        check(button(gui,101).field_146126_j.contains("[Paused]"));
        Field color=FlatButton.class.getDeclaredField("textColor");color.setAccessible(true);
        check(color.getInt(button(gui,101))==0xcc88ff);
        gui.func_146284_a(button(gui,8));check(link.commands.get(1).equals("LM2|P|F|Water|0"));
        check(link.initializations==2);
        property("nextSend").setLong(gui,0);gui.func_73876_c();
        check(link.commands.get(2).startsWith("LM3|Q|"));
        try(PrintWriter out=new PrintWriter(new File(args[0],"pause-commands.txt"))) {
            out.println(link.commands.get(0));out.println(link.commands.get(1));
        }
        gui.func_146281_b();
        System.out.println("PASS: real manager pause/resume controls, color, protocol and refresh: "+checks+" checks");
    }
}
