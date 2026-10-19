package dev.dronf.neilevel;

import net.minecraft.client.gui.FontRenderer;
import net.minecraft.client.gui.GuiTextField;

/** Real Minecraft GuiTextFields; font metrics stubbed to avoid OpenGL/resources. */
public final class FieldFocusTest {
    public static final class TestFont extends FontRenderer {
        private TestFont(){super(null,null,null,false);}
        @Override public String func_78269_a(String s,int width){return s.substring(0,Math.min(s.length(),Math.max(0,width/6)));}
        @Override public String func_78262_a(String s,int width,boolean reverse){int n=Math.min(s.length(),Math.max(0,width/6));return reverse?s.substring(s.length()-n):s.substring(0,n);}
        @Override public int func_78256_a(String s){return s.length()*6;}
    }
    private static int checks;
    private static void check(boolean ok){checks++;if(!ok)throw new AssertionError("input check "+checks);}
    public static void main(String[] args)throws Exception {
        // Skip FontRenderer's GL/resource constructor; real text editing code is unchanged.
        Class<?> unsafeType=Class.forName("sun.misc.Unsafe");
        java.lang.reflect.Field singleton=unsafeType.getDeclaredField("theUnsafe");singleton.setAccessible(true);
        Object unsafe=singleton.get(null);
        FontRenderer font=(FontRenderer)unsafeType.getMethod("allocateInstance",Class.class).invoke(unsafe,TestFont.class);
        GuiTextField[] fields=new GuiTextField[4];
        for(int i=0;i<4;i++){fields[i]=new GuiTextField(font,i*100,20,90,18);fields[i].func_146203_f(13);fields[i].func_146180_a(i==0?"screen":i==1?"10000":i==2?"15000":"1000");}
        FieldFocus input=new FieldFocus(fields,new boolean[]{false,true,true,true});
        input.focus(0,false);input.click(110,25,0);
        check(fields[1].func_146206_l()&&!fields[0].func_146206_l());
        check(fields[1].func_146207_c().equals("10000"));
        input.key('2',3);input.key('5',6);
        check(fields[1].func_146179_b().equals("25"));
        check(fields[0].func_146179_b().equals("screen")&&fields[2].func_146179_b().equals("15000"));
        input.next(false);input.key('6',7);input.key('4',5);
        check(fields[2].func_146179_b().equals("64"));
        input.next(false);input.key((char)0,79);input.key((char)0,82);
        check(fields[3].func_146179_b().equals("10"));
        input.next(true);input.key((char)1,30);input.key('7',8);
        check(fields[2].func_146179_b().equals("7"));
        fields[2].func_146195_b(false);input.key('8',9);
        check(fields[2].func_146179_b().equals("78")); // recover from externally lost focus
        fields[1].func_146180_a("1000000000000");input.click(110,25,0);
        check(fields[1].func_146207_c().equals("1000000000000"));input.key('3',4);
        check(fields[1].func_146179_b().equals("3")); // full-length saved number is replaceable
        fields[1].func_146180_a("1000000000000");fields[1].func_146202_e();fields[1].func_146199_i(0);
        input.key('4',5);check(fields[1].func_146179_b().equals("4")); // backward selection regression
        fields[1].func_146180_a("1000000000000");input.key((char)1,30);input.key('3',4);
        check(fields[1].func_146179_b().equals("3")); // Ctrl+A at the length limit
        input.click(400,100,0);input.key('2',3);
        check(fields[1].func_146179_b().equals("32")); // non-field click retains active editor
        input.click(310,25,1);input.key('1',2);
        check(fields[1].func_146179_b().equals("321")); // right click doesn't steal focus
        input.click(312,25,0);check(fields[3].func_146206_l()&&!fields[1].func_146206_l());
        fields[3].func_146191_b("");check(fields[3].func_146179_b().isEmpty());
        for(int key:new int[]{82,79,80,81,75,76,77,71,72,73})check(FieldFocus.keypadDigit(key)>=0);
        check(FieldFocus.keypadDigit(30)==-1);
        System.out.println("PASS: real Minecraft text-field focus/input checks: "+checks);
    }
}
