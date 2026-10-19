package dev.dronf.neilevel;

import codechicken.nei.LayoutManager;
import codechicken.nei.TextField;
import codechicken.nei.Widget;
import net.minecraft.client.gui.GuiScreen;
import org.lwjgl.input.Keyboard;

/** Own keyboard dispatch while a maintainer window is visible. */
public abstract class MaintainerScreen extends GuiScreen {
    static void releaseNeiFocus() {
        Widget previous=LayoutManager.getInputFocused();
        if(previous instanceof TextField)((TextField)previous).setFocus(false);
        LayoutManager.setInputFocused(null);
        if(LayoutManager.searchField!=null && LayoutManager.searchField.focused())LayoutManager.searchField.setFocus(false);
    }
    protected void beginInput() {releaseNeiFocus();TextInputBuffer.clear();}
    public final void acceptKey(char ch,int key) {releaseNeiFocus();func_73869_a(ch,key);}
    @Override public final void func_146282_l() {
        if(Keyboard.getEventKeyState())acceptKey(Keyboard.getEventCharacter(),Keyboard.getEventKey());
        field_146297_k.func_152348_aa();
    }
}
