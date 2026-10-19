package dev.dronf.neilevel;

import net.minecraft.client.gui.GuiTextField;

/** Own focus explicitly rather than relying on every field to update itself. */
public final class FieldFocus {
    private final GuiTextField[] fields;
    private final boolean[] replace;
    private int active=-1;
    public FieldFocus(GuiTextField[] fields,boolean[] replace) {
        if(fields.length!=replace.length)throw new IllegalArgumentException("Field configuration mismatch");
        this.fields=fields;this.replace=replace;
        for(GuiTextField field:fields) {field.func_146184_c(true);field.func_146205_d(false);field.func_146195_b(false);}
    }
    public void focus(int index,boolean select) {
        active=index;
        for(int i=0;i<fields.length;i++)if(fields[i].func_146206_l()!=(i==active))fields[i].func_146195_b(i==active);
        if(active>=0&&select&&replace[active])selectAll(fields[active]);
    }
    private static void selectAll(GuiTextField field) {field.func_146196_d();field.func_146199_i(field.func_146179_b().length());}
    public void next(boolean reverse) {focus((active+(reverse?fields.length-1:1)+fields.length)%fields.length,true);}
    public void click(int x,int y,int button) {
        if(button!=0)return;
        for(int i=0;i<fields.length;i++) {
            GuiTextField f=fields[i];
            if(x>=f.field_146209_f&&x<f.field_146209_f+f.field_146218_h&&y>=f.field_146210_g&&y<f.field_146210_g+f.field_146219_i) {
                focus(i,false);
                f.func_146192_a(x,y,button);
                // A numeric click means replace the value, including the
                // initially focused field and repeated clicks on that field.
                if(replace[i])focus(i,true);
                return;
            }
        }
    }
    public void key(char ch,int key) {
        if(active<0)return;
        focus(active,false);
        if(ch==1) {selectAll(fields[active]);return;}
        // lwjgl3ify emits key=0 text events in addition to physical presses.
        // Numbers use physical keys only; accepting both would double each digit.
        // Control characters (e.g. paste) still use the normal edit commands.
        if(replace[active] && key==0 && ch>=32)return;
        // Some keyboard layouts supply keypad scan codes without a text character.
        if(replace[active]) {
            int digit=key>=2&&key<=11?(key==11?0:key-1):keypadDigit(key);if(digit>=0)ch=(char)('0'+digit);
        }
        // Vanilla 1.7.10 can reject replacement at the length limit when the
        // selection points backwards. Normalize it before typing or pasting.
        GuiTextField field=fields[active];
        if((ch>=32||ch==22)&&!field.func_146207_c().isEmpty()) {
            int cursor=field.func_146198_h(),anchor=field.func_146186_n();
            if(cursor>anchor) {field.func_146190_e(anchor);field.func_146199_i(cursor);}
        }
        // Do not route insertion through textboxKeyTyped: lwjgl3ify redirects
        // that call to its SDL buffer, discarding supplied characters.
        if(key==14 || key==211) {field.func_146175_b(key==14?-1:1);return;}
        if(replace[active] && ch>=32 && ch!=127) {
            if(ch>='0'&&ch<='9')field.func_146191_b(String.valueOf(ch));
            return;
        }
        fields[active].func_146201_a(ch,key);
    }
    public static int keypadDigit(int key) {
        switch(key) {
            case 82:return 0;case 79:return 1;case 80:return 2;case 81:return 3;
            case 75:return 4;case 76:return 5;case 77:return 6;
            case 71:return 7;case 72:return 8;case 73:return 9;default:return -1;
        }
    }
}
