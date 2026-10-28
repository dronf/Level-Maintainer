package dev.dronf.neilevel;

import cpw.mods.fml.common.FMLCommonHandler;
import cpw.mods.fml.common.eventhandler.SubscribeEvent;
import cpw.mods.fml.common.gameevent.InputEvent;
import cpw.mods.fml.common.gameevent.TickEvent;
import net.minecraft.client.gui.GuiScreen;

import codechicken.nei.guihook.GuiContainerManager;
import codechicken.nei.guihook.IContainerInputHandler;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.inventory.GuiContainer;
import net.minecraft.client.multiplayer.WorldClient;
import net.minecraft.item.ItemStack;
import org.lwjgl.input.Keyboard;

/** Gameplay shortcut plus NEI's item-panel and inventory hover resolution. */
public final class ClientProxy extends CommonProxy implements IContainerInputHandler {
    private GuiScreen pending, expected;
    private WorldClient expectedWorld;
    private int pendingKey;
    @Override public void init() {
        Minecraft mc=Minecraft.func_71410_x();
        ShortcutSettings.load(mc.field_71412_D);
        ShortcutSettings.register(mc.field_71474_y);
        // Run before NEI's search field and other handlers consume the shortcut.
        GuiContainerManager.inputHandlers.addFirst(this);
        FMLCommonHandler.instance().bus().register(this);
    }
    private void queue(Minecraft mc, GuiScreen next,int key) {
        pending=next;expected=mc.field_71462_r;expectedWorld=mc.field_71441_e;
        pendingKey=key;
    }
    @SubscribeEvent public void keyInput(InputEvent.KeyInputEvent event) {
        Minecraft mc=Minecraft.func_71410_x();
        // Text-entry screens (including OC terminals) retain their own shortcuts.
        if(mc.field_71462_r!=null || mc.field_71441_e==null || mc.field_71439_g==null)return;
        int key=Keyboard.getEventKey();
        if(!Keyboard.getEventKeyState() || (!ShortcutSettings.context(key)&&!ShortcutSettings.manager(key)))return;
        if(Keyboard.isRepeatEvent() || pending!=null)return;
        queue(mc,new ManagerGui(""),key);
    }
    @Override public boolean keyTyped(GuiContainer gui, char ch, int key) {
        Minecraft mc = Minecraft.func_71410_x();
        // A stale container callback must not send editor keys to NEI's search.
        if(mc.field_71462_r instanceof MaintainerScreen) {
            ((MaintainerScreen)mc.field_71462_r).acceptKey(ch,key);return true;
        }
        if (mc.field_71462_r!=gui) return false;
        if (!ShortcutSettings.context(key)&&!ShortcutSettings.manager(key)) return false;
        if (Keyboard.isRepeatEvent() || pending!=null) return true;
        boolean managerOnly=ShortcutSettings.forceManager(key);
        ItemStack stack = managerOnly ? null : GuiContainerManager.getStackMouseOver(gui);
        if (stack == null) {
            queue(mc,new ManagerGui(""),key);
        } else {
            queue(mc,new MaintenanceGui(stack),key);
        }
        return true;
    }
    @SubscribeEvent public void tick(TickEvent.ClientTickEvent event) {
        if(event.phase!=TickEvent.Phase.END || pending==null)return;
        Minecraft mc=Minecraft.func_71410_x();
        if(mc.field_71462_r!=expected || mc.field_71441_e!=expectedWorld || mc.field_71439_g==null){
            pending=null;expected=null;expectedWorld=null;return;
        }
        if(Keyboard.isKeyDown(pendingKey)||ShortcutSettings.anyModifier())return;
        GuiScreen next=pending;pending=null;expected=null;expectedWorld=null;
        // Finish the originating keyboard event and release the chord before opening.
        mc.func_147108_a(next);
    }
    @Override public void onKeyTyped(GuiContainer gui, char ch, int key) { }
    @Override public boolean lastKeyTyped(GuiContainer gui, char ch, int key) { return false; }
    @Override public boolean mouseClicked(GuiContainer gui, int x, int y, int button) { return false; }
    @Override public void onMouseClicked(GuiContainer gui, int x, int y, int button) { }
    @Override public void onMouseUp(GuiContainer gui, int x, int y, int button) { }
    @Override public boolean mouseScrolled(GuiContainer gui, int x, int y, int direction) { return false; }
    @Override public void onMouseScrolled(GuiContainer gui, int x, int y, int direction) { }
    @Override public void onMouseDragged(GuiContainer gui, int x, int y, int button, long time) { }
}
