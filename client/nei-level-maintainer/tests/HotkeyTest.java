package dev.dronf.neilevel;

import cpw.mods.fml.common.eventhandler.SubscribeEvent;
import cpw.mods.fml.common.gameevent.InputEvent;
import cpw.mods.fml.common.gameevent.TickEvent;
import java.lang.reflect.Field;
import java.nio.ByteBuffer;
import net.minecraft.client.Minecraft;
import net.minecraft.client.entity.EntityClientPlayerMP;
import net.minecraft.client.gui.GuiChat;
import net.minecraft.client.gui.GuiScreen;
import net.minecraft.client.gui.inventory.GuiContainer;
import net.minecraft.client.multiplayer.WorldClient;
import org.lwjgl.input.Keyboard;

/** Real FML/NEI callbacks and LWJGL event state; no game window or OC network. */
public final class HotkeyTest {
    public static final class TestMinecraft extends Minecraft {
        private TestMinecraft(){super(null,0,0,false,false,null,null,null,null,null,null,null);}
        int opens;
        @Override public void func_147108_a(GuiScreen screen){opens++;field_71462_r=screen;}
    }
    public static final class TestContainer extends GuiContainer {
        private TestContainer(){super(null);}
        @Override protected void func_146976_a(float t,int x,int y){}
    }
    private static int checks;
    private static void check(boolean b){checks++;if(!b)throw new AssertionError("hotkey check "+checks);}
    private static Field field(Class<?> type,String name)throws Exception {
        Field f=type.getDeclaredField(name);f.setAccessible(true);return f;
    }
    private static void keys(int... keys)throws Exception {
        ByteBuffer state=(ByteBuffer)field(Keyboard.class,"keyDownBuffer").get(null);
        for(int i=0;i<state.capacity();i++)state.put(i,(byte)0);
        for(int key:keys)state.put(key,(byte)1);
    }
    private static void event(ClientProxy proxy,int key,boolean down,boolean repeat)throws Exception {
        Object e=field(Keyboard.class,"current_event").get(null);
        field(e.getClass(),"key").setInt(e,key);
        field(e.getClass(),"state").setBoolean(e,down);
        field(e.getClass(),"repeat").setBoolean(e,repeat);
        proxy.keyInput(new InputEvent.KeyInputEvent());
    }
    private static void tick(ClientProxy proxy){proxy.tick(new TickEvent.ClientTickEvent(TickEvent.Phase.END));}
    private static void release(ClientProxy proxy)throws Exception {keys();tick(proxy);}
    public static void main(String[] args)throws Exception {
        TestMinecraft mc=(TestMinecraft)ManagerPauseTest.allocate(TestMinecraft.class);
        field(Minecraft.class,"field_71432_P").set(null,mc);
        WorldClient world=(WorldClient)ManagerPauseTest.allocate(WorldClient.class);
        EntityClientPlayerMP player=(EntityClientPlayerMP)ManagerPauseTest.allocate(EntityClientPlayerMP.class);
        mc.field_71441_e=world;mc.field_71439_g=player;
        field(Keyboard.class,"created").setBoolean(null,true);
        try {
            ClientProxy proxy=new ClientProxy();
            check(ClientProxy.class.getMethod("keyInput",InputEvent.KeyInputEvent.class).isAnnotationPresent(SubscribeEvent.class));
            check(ClientProxy.class.getMethod("tick",TickEvent.ClientTickEvent.class).isAnnotationPresent(SubscribeEvent.class));
            for(int ctrl:new int[]{Keyboard.KEY_LCONTROL,Keyboard.KEY_RCONTROL}) {
                mc.field_71462_r=null;int before=mc.opens;
                keys(ctrl,Keyboard.KEY_M);event(proxy,Keyboard.KEY_M,true,false);tick(proxy);
                check(mc.opens==before); // held shortcut must not enter the new GUI
                event(proxy,Keyboard.KEY_M,true,true);event(proxy,Keyboard.KEY_M,true,false);
                keys(ctrl);tick(proxy);check(mc.opens==before);
                keys();proxy.tick(new TickEvent.ClientTickEvent(TickEvent.Phase.START));check(mc.opens==before);
                tick(proxy);check(mc.opens==before+1&&mc.field_71462_r instanceof ManagerGui);
                tick(proxy);check(mc.opens==before+1); // duplicate events still open exactly once
            }
            int before=mc.opens;
            mc.field_71462_r=null;
            keys(Keyboard.KEY_M);event(proxy,Keyboard.KEY_M,true,false);release(proxy);check(mc.opens==before);
            keys(Keyboard.KEY_LCONTROL);event(proxy,Keyboard.KEY_A,true,false);release(proxy);check(mc.opens==before);
            keys(Keyboard.KEY_LCONTROL);event(proxy,0,true,false);release(proxy);check(mc.opens==before);
            keys(Keyboard.KEY_LCONTROL);event(proxy,Keyboard.KEY_M,false,false);release(proxy);check(mc.opens==before);
            keys(Keyboard.KEY_LCONTROL,Keyboard.KEY_M);event(proxy,Keyboard.KEY_M,true,true);release(proxy);check(mc.opens==before);

            // Chat, terminals, inventories and our own GUIs are not captured by the gameplay path.
            for(GuiScreen screen:new GuiScreen[]{new GuiChat(),new GuiScreen(),new ManagerGui(""),
                    (GuiScreen)ManagerPauseTest.allocate(TestContainer.class)}) {
                mc.field_71462_r=screen;
                keys(Keyboard.KEY_LCONTROL,Keyboard.KEY_M);event(proxy,Keyboard.KEY_M,true,false);
                release(proxy);check(mc.opens==before&&mc.field_71462_r==screen);
            }
            mc.field_71462_r=null;mc.field_71441_e=null;
            keys(Keyboard.KEY_LCONTROL,Keyboard.KEY_M);event(proxy,Keyboard.KEY_M,true,false);release(proxy);check(mc.opens==before);
            mc.field_71441_e=world;mc.field_71439_g=null;
            keys(Keyboard.KEY_LCONTROL,Keyboard.KEY_M);event(proxy,Keyboard.KEY_M,true,false);release(proxy);check(mc.opens==before);
            mc.field_71439_g=player;

            // Cancel queued opens if another GUI opens, the world changes or the player disconnects.
            keys(Keyboard.KEY_LCONTROL,Keyboard.KEY_M);event(proxy,Keyboard.KEY_M,true,false);
            mc.field_71462_r=new GuiChat();release(proxy);mc.field_71462_r=null;tick(proxy);check(mc.opens==before);
            keys(Keyboard.KEY_LCONTROL,Keyboard.KEY_M);event(proxy,Keyboard.KEY_M,true,false);
            mc.field_71441_e=(WorldClient)ManagerPauseTest.allocate(WorldClient.class);
            release(proxy);mc.field_71441_e=world;tick(proxy);check(mc.opens==before);
            keys(Keyboard.KEY_LCONTROL,Keyboard.KEY_M);event(proxy,Keyboard.KEY_M,true,false);
            mc.field_71439_g=null;release(proxy);mc.field_71439_g=player;tick(proxy);check(mc.opens==before);

            // The same manager shortcut remains available through NEI's inventory callback.
            GuiContainer inventory=(GuiContainer)ManagerPauseTest.allocate(TestContainer.class);
            for(int shift:new int[]{Keyboard.KEY_LSHIFT,Keyboard.KEY_RSHIFT}) {
                mc.field_71462_r=inventory;
                keys(Keyboard.KEY_RCONTROL,shift,Keyboard.KEY_M);event(proxy,Keyboard.KEY_M,true,false);
                check(proxy.keyTyped(inventory,'m',Keyboard.KEY_M));tick(proxy);check(mc.opens==before);
                release(proxy);before++;check(mc.opens==before&&mc.field_71462_r instanceof ManagerGui);
            }
            mc.field_71462_r=new GuiChat();keys(Keyboard.KEY_LCONTROL,Keyboard.KEY_M);
            check(!proxy.keyTyped(inventory,'m',Keyboard.KEY_M));release(proxy);check(mc.opens==before);
        } finally {keys();field(Keyboard.class,"created").setBoolean(null,false);}
        System.out.println("PASS: gameplay/NEI hotkey dispatch, release, repeat and cancellation: "+checks+" checks");
    }
}
