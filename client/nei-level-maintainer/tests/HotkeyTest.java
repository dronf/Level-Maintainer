package dev.dronf.neilevel;

import cpw.mods.fml.common.eventhandler.SubscribeEvent;
import cpw.mods.fml.common.gameevent.InputEvent;
import cpw.mods.fml.common.gameevent.TickEvent;
import java.lang.reflect.Field;
import java.nio.ByteBuffer;
import java.io.File;
import java.nio.file.Files;
import net.minecraft.client.settings.GameSettings;
import net.minecraft.client.settings.KeyBinding;
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
    public static final class TestSettings extends GameSettings {
        int saves;
        @Override public void func_74303_b(){saves++;}
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

            // Rebinding removes both the old M trigger and the need for Ctrl.
            ShortcutSettings.key(ShortcutSettings.CONTEXT,Keyboard.KEY_N);
            ShortcutSettings.contextModifier=ShortcutSettings.Modifier.NONE;
            ShortcutSettings.key(ShortcutSettings.MANAGER,Keyboard.KEY_F6);
            ShortcutSettings.managerModifier=ShortcutSettings.Modifier.NONE;
            mc.field_71462_r=null;
            keys(Keyboard.KEY_M);event(proxy,Keyboard.KEY_M,true,false);release(proxy);check(mc.opens==before);
            keys(Keyboard.KEY_LCONTROL,Keyboard.KEY_M);event(proxy,Keyboard.KEY_M,true,false);release(proxy);check(mc.opens==before);
            keys(Keyboard.KEY_LCONTROL,Keyboard.KEY_N);event(proxy,Keyboard.KEY_N,true,false);release(proxy);check(mc.opens==before);
            keys(Keyboard.KEY_N);event(proxy,Keyboard.KEY_N,true,false);tick(proxy);check(mc.opens==before);
            release(proxy);before++;check(mc.opens==before&&mc.field_71462_r instanceof ManagerGui);
            mc.field_71462_r=null;keys(Keyboard.KEY_F6);event(proxy,Keyboard.KEY_F6,true,false);
            release(proxy);before++;check(mc.opens==before&&mc.field_71462_r instanceof ManagerGui);
            mc.field_71462_r=inventory;keys(Keyboard.KEY_F6);
            check(proxy.keyTyped(inventory,(char)0,Keyboard.KEY_F6));release(proxy);before++;
            check(mc.opens==before&&mc.field_71462_r instanceof ManagerGui);
            keys(Keyboard.KEY_LCONTROL,Keyboard.KEY_F6);check(!ShortcutSettings.manager(Keyboard.KEY_F6));
            for(int alt:new int[]{Keyboard.KEY_LMENU,Keyboard.KEY_RMENU}){
                ShortcutSettings.contextModifier=ShortcutSettings.Modifier.ALT;
                mc.field_71462_r=null;keys(alt,Keyboard.KEY_N);event(proxy,Keyboard.KEY_N,true,false);
                keys(alt);tick(proxy);check(mc.opens==before);
                release(proxy);before++;check(mc.opens==before&&mc.field_71462_r instanceof ManagerGui);
            }
            ShortcutSettings.contextModifier=ShortcutSettings.Modifier.SHIFT;
            keys(Keyboard.KEY_LSHIFT,Keyboard.KEY_N);check(ShortcutSettings.context(Keyboard.KEY_N));
            check(!ShortcutSettings.forceManager(Keyboard.KEY_N));
            ShortcutSettings.key(ShortcutSettings.CONTEXT,Keyboard.KEY_NONE);
            keys();check(!ShortcutSettings.context(0));
            ShortcutSettings.key(ShortcutSettings.MANAGER,-99);check(!ShortcutSettings.manager(-99));
            ShortcutSettings.key(ShortcutSettings.CONTEXT,Keyboard.KEY_LCONTROL);
            ShortcutSettings.contextModifier=ShortcutSettings.Modifier.CTRL;
            keys(Keyboard.KEY_LCONTROL);check(!ShortcutSettings.context(Keyboard.KEY_LCONTROL));
            ShortcutSettings.key(ShortcutSettings.CONTEXT,Keyboard.KEY_NONE);

            TestSettings settings=(TestSettings)ManagerPauseTest.allocate(TestSettings.class);
            settings.field_74324_K=new KeyBinding[0];
            ShortcutSettings.register(settings);ShortcutSettings.register(settings);
            check(settings.field_74324_K.length==2&&settings.field_74324_K[0]==ShortcutSettings.CONTEXT
                &&settings.field_74324_K[1]==ShortcutSettings.MANAGER);
            File directory=Files.createTempDirectory("nei-shortcut-test").toFile();
            ShortcutSettings.load(directory);
            check(ShortcutSettings.contextModifier==ShortcutSettings.Modifier.CTRL
                &&ShortcutSettings.managerModifier==ShortcutSettings.Modifier.NONE);
            ShortcutSettings.contextModifier=ShortcutSettings.Modifier.NONE;
            ShortcutSettings.managerModifier=ShortcutSettings.Modifier.ALT;
            ShortcutSettings.save(settings);check(settings.saves==1);
            ShortcutSettings.contextModifier=ShortcutSettings.Modifier.CTRL;
            ShortcutSettings.load(directory);
            check(ShortcutSettings.contextModifier==ShortcutSettings.Modifier.NONE
                &&ShortcutSettings.managerModifier==ShortcutSettings.Modifier.ALT);
            File config=new File(directory,"config/nei-level-maintainer-hotkeys.properties");
            Files.write(config.toPath(),"contextModifier=BOGUS\nmanagerModifier=CTRL\n".getBytes("UTF-8"));
            ShortcutSettings.load(directory);check(ShortcutSettings.contextModifier==ShortcutSettings.Modifier.CTRL
                &&ShortcutSettings.managerModifier==ShortcutSettings.Modifier.CTRL);
            // Press/release delivery through a shortcut screen cannot leak to NEI.
            ShortcutGui gui=new ShortcutGui(null);mc.field_71474_y=settings;
            gui.func_146280_a(mc,640,360);
            gui.func_146284_a(new net.minecraft.client.gui.GuiButton(1,0,0,"key"));
            gui.acceptKey((char)0,Keyboard.KEY_LCONTROL);check(ShortcutSettings.CONTEXT.func_151463_i()==0);
            gui.acceptKey('n',Keyboard.KEY_N);check(ShortcutSettings.CONTEXT.func_151463_i()==Keyboard.KEY_N);
            gui.func_146284_a(new net.minecraft.client.gui.GuiButton(2,0,0,"modifier"));
            check(ShortcutSettings.contextModifier==ShortcutSettings.Modifier.ALT);
            gui.func_146284_a(new net.minecraft.client.gui.GuiButton(1,0,0,"key"));
            gui.acceptKey((char)0,Keyboard.KEY_ESCAPE);check(ShortcutSettings.CONTEXT.func_151463_i()==0);
            config.delete();config.getParentFile().delete();directory.delete();
        } finally {keys();field(Keyboard.class,"created").setBoolean(null,false);}
        System.out.println("PASS: gameplay/NEI hotkey dispatch, release, repeat and cancellation: "+checks+" checks");
    }
}
