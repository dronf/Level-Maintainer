package dev.dronf.neilevel;

import codechicken.nei.guihook.GuiContainerManager;
import codechicken.nei.guihook.IContainerInputHandler;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.inventory.GuiContainer;
import net.minecraft.item.ItemStack;
import net.minecraft.util.ChatComponentText;
import org.lwjgl.input.Keyboard;

/** Uses NEI's 1.7.10 input hook, including item-panel and inventory hover resolution. */
public final class ClientProxy extends CommonProxy implements IContainerInputHandler {
    @Override public void init() {
        // Run before NEI's search field and other handlers can consume Ctrl+M.
        GuiContainerManager.inputHandlers.addFirst(this);
    }
    @Override public boolean keyTyped(GuiContainer gui, char ch, int key) {
        if (key != Keyboard.KEY_M || !Keyboard.isKeyDown(Keyboard.KEY_LCONTROL)) return false;
        if (Keyboard.isRepeatEvent()) return true;
        ItemStack stack = GuiContainerManager.getStackMouseOver(gui);
        Minecraft mc = Minecraft.func_71410_x(); // getMinecraft
        if (stack == null || Keyboard.isKeyDown(Keyboard.KEY_LSHIFT) || Keyboard.isKeyDown(Keyboard.KEY_RSHIFT)) {
            mc.func_147108_a(new ManagerGui(""));
        } else {
            mc.func_147108_a(new MaintenanceGui(stack)); // displayGuiScreen
        }
        return true;
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
