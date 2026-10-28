package dev.dronf.neilevel;

import java.io.IOException;
import net.minecraft.client.gui.*;
import net.minecraft.client.settings.KeyBinding;
import org.lwjgl.input.Keyboard;

/** Also reachable via a newly bound manager key when the old chord conflicts. */
public final class ShortcutGui extends MaintainerScreen {
    private final GuiScreen parent;
    private KeyBinding capturing;
    private String status="Click a key to rebind. Escape while choosing a key unbinds it.";
    public ShortcutGui(GuiScreen parent){this.parent=parent;}
    @Override public boolean func_73868_f(){return false;}
    @Override public void func_73866_w_(){beginInput();buttons();}
    private void buttons(){
        int x=field_146294_l/2-150,y=field_146295_m/2-65;
        field_146292_n.clear();
        field_146292_n.add(new FlatButton(1,x,y,195,20,"Context key: "+ShortcutSettings.keyName(ShortcutSettings.CONTEXT)));
        field_146292_n.add(new FlatButton(2,x+200,y,100,20,ShortcutSettings.contextModifier.name()));
        field_146292_n.add(new FlatButton(3,x,y+27,195,20,"Manager key: "+ShortcutSettings.keyName(ShortcutSettings.MANAGER)));
        field_146292_n.add(new FlatButton(4,x+200,y+27,100,20,ShortcutSettings.managerModifier.name()));
        field_146292_n.add(new FlatButton(5,x,y+60,145,20,"Minecraft Controls"));
        field_146292_n.add(new FlatButton(6,x+155,y+60,145,20,"Done"));
    }
    @Override protected void func_146284_a(GuiButton b){
        if(b.field_146127_k==1||b.field_146127_k==3){
            capturing=b.field_146127_k==1?ShortcutSettings.CONTEXT:ShortcutSettings.MANAGER;
            status="Press a keyboard key; Escape unbinds. Choose the modifier separately.";return;
        }
        capturing=null;
        if(b.field_146127_k==2)ShortcutSettings.contextModifier=next(ShortcutSettings.contextModifier);
        if(b.field_146127_k==4)ShortcutSettings.managerModifier=next(ShortcutSettings.managerModifier);
        if(b.field_146127_k==5){field_146297_k.func_147108_a(new GuiControls(this,field_146297_k.field_71474_y));return;}
        if(b.field_146127_k==6){if(save())field_146297_k.func_147108_a(parent);return;}
        buttons();
    }
    private static ShortcutSettings.Modifier next(ShortcutSettings.Modifier m){
        ShortcutSettings.Modifier[] values=ShortcutSettings.Modifier.values();return values[(m.ordinal()+1)%values.length];
    }
    @Override protected void func_73869_a(char ch,int key){
        if(capturing!=null){
            if(key==0)return;
            if(ShortcutSettings.modifierKey(key)){status="Choose a regular key; set CTRL/ALT/SHIFT using its button.";return;}
            ShortcutSettings.key(capturing,key==Keyboard.KEY_ESCAPE?Keyboard.KEY_NONE:key);
            capturing=null;status="Changed. Done saves keys and modifiers immediately.";buttons();return;
        }
        if(key==Keyboard.KEY_ESCAPE&&save())field_146297_k.func_147108_a(parent);
    }
    private boolean save(){
        try{ShortcutSettings.save(field_146297_k.field_71474_y);return true;}
        catch(IOException ex){status="Could not save shortcuts: "+ex.getMessage();return false;}
    }
    @Override public void func_146281_b(){capturing=null;TextInputBuffer.clear();}
    @Override public void func_73863_a(int mx,int my,float partial){
        func_146276_q_();int x=field_146294_l/2-150,y=field_146295_m/2-65;
        func_73732_a(field_146289_q,"NEI Level Maintainer shortcuts",field_146294_l/2,y-25,0xffffff);
        int line=y+90;
        for(Object s:field_146289_q.func_78271_c(status,300)){field_146289_q.func_78276_b((String)s,x,line,0xffcc55);line+=10;}
        super.func_73863_a(mx,my,partial);
    }
}
