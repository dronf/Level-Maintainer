package dev.dronf.neilevel;

import cpw.mods.fml.common.FMLCommonHandler;
import cpw.mods.fml.common.eventhandler.SubscribeEvent;
import cpw.mods.fml.common.gameevent.TickEvent;
import net.minecraft.client.gui.GuiScreen;

import codechicken.nei.guihook.GuiContainerManager;
import codechicken.nei.guihook.IContainerInputHandler;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.inventory.GuiContainer;
import net.minecraft.item.ItemStack;
import net.minecraft.util.ChatComponentText;
import org.lwjgl.input.Keyboard;

/** Uses NEI's 1.7.10 input hook, including item-panel and inventory hover resolution. */
public final class ClientProxy extends CommonProxy implements IContainerInputHandler {
    private GuiScreen pending, expected;
    @Override public void init() {
        // Run before NEI's search field and other handlers can consume Ctrl+M.
        GuiContainerManager.inputHandlers.addFirst(this);
        FMLCommonHandler.instance().bus().register(this);
    }
    @Override public boolean keyTyped(GuiContainer gui, char ch, int key) {
        if (key != Keyboard.KEY_M || !Keyboard.isKeyDown(Keyboard.KEY_LCONTROL)) return false;
        if (Keyboard.isRepeatEvent() || pending!=null) return true;
        ItemStack stack = GuiContainerManager.getStackMouseOver(gui);
        Minecraft mc = Minecraft.func_71410_x(); // getMinecraft
        if (stack == null || Keyboard.isKeyDown(Keyboard.KEY_LSHIFT) || Keyboard.isKeyDown(Keyboard.KEY_RSHIFT)) {
            pending=new ManagerGui("");
        } else {
            pending=new MaintenanceGui(stack);
        }
        expected=gui;
        return true;
    }
    @SubscribeEvent public void tick(TickEvent.ClientTickEvent event) {
        if(event.phase!=TickEvent.Phase.END || pending==null)return;
        Minecraft mc=Minecraft.func_71410_x();
        if(mc.field_71462_r!=expected){pending=null;expected=null;return;}
        if(Keyboard.isKeyDown(Keyboard.KEY_M)||Keyboard.isKeyDown(Keyboard.KEY_LCONTROL))return;
        GuiScreen next=pending;pending=null;expected=null;
        // Finish the old container's keyboard event before opening a new screen.
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
