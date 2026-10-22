package dev.dronf.neilevel;

import java.io.*;
import java.lang.reflect.*;
import java.util.*;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.*;
import net.minecraft.item.*;

/** Execute the real editor lifecycle and input handlers without rendering/OpenGL. */
public final class EditorInputTest {
    public static final class TestItem extends Item {
        @Override public String func_77653_i(ItemStack stack){return "New Test Item";}
    }
    public static final class TestNeiField extends codechicken.nei.TextField {
        private TestNeiField(){super("test");}
        @Override public void onTextChange(String before) { }
    }
    private static int checks;
    private static void check(boolean b){checks++;if(!b)throw new AssertionError("editor check "+checks);}
    private static Object allocate(Class<?> type)throws Exception{
        Class<?> u=Class.forName("sun.misc.Unsafe");Field f=u.getDeclaredField("theUnsafe");f.setAccessible(true);
        return u.getMethod("allocateInstance",Class.class).invoke(f.get(null),type);
    }
    private static GuiTextField field(MaintenanceGui gui,String name)throws Exception{
        Field f=MaintenanceGui.class.getDeclaredField(name);f.setAccessible(true);return (GuiTextField)f.get(gui);
    }
    private static void replace(MaintenanceGui gui,String name,String value)throws Exception {
        GuiTextField f=field(gui,name);
        Method click=MaintenanceGui.class.getDeclaredMethod("func_73864_a",int.class,int.class,int.class);click.setAccessible(true);
        click.invoke(gui,f.field_146209_f+8,f.field_146210_g+8,0);
        Method key=MaintenanceGui.class.getDeclaredMethod("func_73869_a",char.class,int.class);key.setAccessible(true);
        key.invoke(gui,(char)0,14);
        check(f.func_146179_b().isEmpty());
        for(char c:value.toCharArray()) {key.invoke(gui,(char)0,c=='0'?11:c-'0'+1);key.invoke(gui,c,0);}
        if(!field(gui,name).func_146179_b().equals(value))throw new AssertionError(name+": expected "+value+", got "+field(gui,name).func_146179_b());
        checks++;
    }
    private static final class DrawSpy extends FlatButton {
        final List<int[]> boxes=new ArrayList<>();int labels,lastColor;
        DrawSpy(int width){super(0,10,20,width,20,"Wide button");}
        @Override protected void rectangle(int l,int t,int r,int b,int color){boxes.add(new int[]{l,t,r,b,color});}
        @Override protected void label(Minecraft mc,String s,int x,int y,int color){labels++;lastColor=color;check(x==10+field_146120_f/2&&y==26);}
    }
    public static void main(String[] args)throws Exception {
        for(int width:new int[]{56,86,200,270,304,480}){
            DrawSpy b=new DrawSpy(width);b.func_146112_a(null,11,21);
            check(b.boxes.size()==2&&b.labels==1);
            for(int[] box:b.boxes)check(box[0]>=10&&box[2]<=10+width&&box[1]>=20&&box[3]<=40);
            check(b.boxes.get(1)[4]!=0xffffffff);
            b.field_146125_m=false;b.func_146112_a(null,0,0);check(b.labels==1);
        }
        DrawSpy pausedButton=new DrawSpy(270);pausedButton.textColor(0xcc88ff);pausedButton.func_146112_a(null,11,21);
        check(pausedButton.lastColor==0xcc88ff);
        Minecraft mc=(Minecraft)allocate(Minecraft.class);
        Field singleton=Minecraft.class.getDeclaredField("field_71432_P");singleton.setAccessible(true);singleton.set(null,mc);
        mc.field_71466_p=(FontRenderer)allocate(FieldFocusTest.TestFont.class);
        File root=new File(args[0],"editor-regression");new File(root,"config").mkdirs();
        Field dataDir=Minecraft.class.getDeclaredField("field_71412_D");dataDir.setAccessible(true);dataDir.set(mc,root);
        Properties prefs=new Properties();prefs.setProperty("screen","2ba877c7-82c0-42df-96e6-27c880772f9d");
        prefs.setProperty("low","100000");prefs.setProperty("target","120000");prefs.setProperty("batch","100");
        try(FileOutputStream out=new FileOutputStream(new File(root,"config/nei-level-maintainer.properties"))){prefs.store(out,"");}
        ItemStack stack=(ItemStack)allocate(ItemStack.class);
        Field item=ItemStack.class.getDeclaredField("field_151002_e");item.setAccessible(true);item.set(stack,allocate(TestItem.class));
        StringBuilder shared=null;
        if(args.length>1) {
            shared=(StringBuilder)Class.forName("me.eigenraven.lwjgl3ify.client.TextFieldHandler").getField("textBuffer").get(null);
            shared.append("stale NEI text");
        }
        TestNeiField nei=(TestNeiField)allocate(TestNeiField.class);
        GuiTextField neiField=new GuiTextField(mc.field_71466_p,0,0,90,18);neiField.func_146180_a("original search");
        Field wrapped=codechicken.nei.TextField.class.getDeclaredField("field");wrapped.setAccessible(true);wrapped.set(nei,neiField);
        nei.setFocus(true);codechicken.nei.LayoutManager.setInputFocused(nei);
        MaintenanceGui hover=new MaintenanceGui(stack);
        hover.func_146280_a(mc,640,360);
        check(!nei.focused()&&codechicken.nei.LayoutManager.getInputFocused()==null);
        if(shared!=null)check(shared.length()==0);
        replace(hover,"low","10");replace(hover,"target","64");replace(hover,"batch","16");
        check(BridgeCommand.item(field(hover,"name").func_146179_b(),field(hover,"low").func_146179_b(),field(hover,"target").func_146179_b(),field(hover,"batch").func_146179_b()).equals("LM1|I|New Test Item|10|64|16"));
        Field buttons=GuiScreen.class.getDeclaredField("field_146292_n");buttons.setAccessible(true);GuiButton type=null;for(Object button:(java.util.List)buttons.get(hover))if(((GuiButton)button).field_146127_k==5)type=(GuiButton)button;
        check(type!=null&&type.field_146124_l);hover.func_146284_a(type);check(type.field_146126_j.equals("Fluid"));
        hover.func_146284_a(type);check(type.field_146126_j.equals("Item"));
        hover.func_146280_a(mc,800,400);
        check(field(hover,"low").func_146179_b().equals("10")&&field(hover,"target").func_146179_b().equals("64"));
        MaintenanceGui managed=new MaintenanceGui(null,new MaintainedEntry("I","Existing Item","100000","120000","100",""),prefs.getProperty("screen"));
        managed.func_146280_a(mc,640,360);replace(managed,"low","10");replace(managed,"target","64");replace(managed,"batch","16");
        MaintenanceGui manual=new MaintenanceGui(null,null,prefs.getProperty("screen"));
        manual.func_146280_a(mc,640,360);replace(manual,"low","20");replace(manual,"target","128");replace(manual,"batch","32");
        // Simulate a stale container delivering events while the editor is open.
        mc.field_71462_r=hover;nei.setFocus(true);codechicken.nei.LayoutManager.setInputFocused(nei);
        if(shared!=null)shared.append("999");
        replace(hover,"low","123");
        ClientProxy proxy=new ClientProxy();
        check(proxy.keyTyped(null,(char)0,14));
        check(field(hover,"low").func_146179_b().equals("12"));
        check(proxy.keyTyped(null,(char)0,211));
        check(field(hover,"low").func_146179_b().equals("12"));
        check(proxy.keyTyped(null,(char)0,5));check(proxy.keyTyped(null,'4',0));
        check(field(hover,"low").func_146179_b().equals("124"));
        check(!nei.focused()&&codechicken.nei.LayoutManager.getInputFocused()==null);
        check(neiField.func_146179_b().equals("original search"));
        if(shared!=null)check(shared.length()==0);
        if(shared!=null)shared.append("close residue");
        hover.func_146281_b();
        for(String name:new String[]{"screen","low","target","batch"})check(!field(hover,name).func_146206_l());
        if(shared!=null)check(shared.length()==0);
        manual.func_146281_b();managed.func_146281_b();
        System.out.println("PASS: real editor lifecycle/input and button drawing checks: "+checks);
    }
}
