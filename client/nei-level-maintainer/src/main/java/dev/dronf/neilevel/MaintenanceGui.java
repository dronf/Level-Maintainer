package dev.dronf.neilevel;

import net.minecraft.client.gui.*;
import net.minecraft.item.ItemStack;
import org.lwjgl.input.Keyboard;
import java.io.*;
import java.util.Properties;

/** Minecraft members use production SRG names. */
public final class MaintenanceGui extends MaintainerScreen {
    private final ManagerGui parent;
    private final MaintainedEntry entry;
    private final boolean nameLocked;
    private String initialName="",address,kind="I",savedKind="I",feedback="";
    private GuiTextField screen,name,low,target,batch;
    private boolean removeArmed,submitted;
    private FieldFocus input;
    public MaintenanceGui(ItemStack stack) {this(null,null,"",true);initialName=stack.func_82833_r();}
    public MaintenanceGui(ManagerGui parent,MaintainedEntry entry,String address) {
        this(parent,entry,address,entry!=null);
    }
    private MaintenanceGui(ManagerGui parent,MaintainedEntry entry,String address,boolean nameLocked) {
        this.parent=parent;this.entry=entry;this.address=address;
        this.nameLocked=nameLocked;
        submitted=entry!=null;
        if(entry!=null) {initialName=entry.name;kind=entry.kind;savedKind=kind;}
    }
    private File prefsFile() {return new File(field_146297_k.field_71412_D,"config/nei-level-maintainer.properties");}
    private GuiTextField field(int x,int y,int w,String value,int max) {
        GuiTextField f=new GuiTextField(field_146289_q,x,y,w,18);f.func_146203_f(max);f.func_146180_a(value);return f;
    }
    @Override public boolean func_73868_f() {return false;}
    @Override public void func_73866_w_() {
        if(input!=null)input.close();beginInput();
        String priorLow=low==null?null:low.func_146179_b(),priorTarget=target==null?null:target.func_146179_b(),priorBatch=batch==null?null:batch.func_146179_b();
        if(screen!=null)address=screen.func_146179_b();if(name!=null)initialName=name.func_146179_b();
        Properties prefs=new Properties();
        try(FileInputStream in=new FileInputStream(prefsFile())) {prefs.load(in);}catch(IOException ignored) { }
        int x=field_146294_l/2-135,y=field_146295_m/2-110;
        name=field(x,y+25,208,initialName,160);
        screen=field(x,y+65,270,address.isEmpty()?prefs.getProperty("screen",""):address,36);
        low=field(x,y+105,84,priorLow!=null?priorLow:entry!=null?(entry.low.isEmpty()?"0":entry.low):prefs.getProperty("low","10000"),13);
        target=field(x+93,y+105,84,priorTarget!=null?priorTarget:entry!=null?entry.target:prefs.getProperty("target","15000"),13);
        batch=field(x+186,y+105,84,priorBatch!=null?priorBatch:entry!=null?entry.batch:prefs.getProperty("batch","1000"),13);
        field_146292_n.clear();
        field_146292_n.add(new FlatButton(1,x,y+133,86,20,"Save to OC"));
        field_146292_n.add(new FlatButton(3,x+92,y+133,86,20,removeArmed?"Confirm?":"Remove"));
        field_146292_n.add(new FlatButton(2,x+184,y+133,86,20,"Back"));
        field_146292_n.add(new FlatButton(4,x,y+157,270,20,"Manage existing entries"));
        GuiButton type=new FlatButton(5,x+214,y+24,56,20,kind.equals("I")?"Item":"Fluid");
        type.field_146124_l=true;field_146292_n.add(type);
        if(entry!=null && entry.target.isEmpty())feedback="Legacy entry: enter a Target to convert to Low/Target mode.";
        input=new FieldFocus(fields(),nameLocked?new boolean[]{false,true,true,true}:new boolean[]{false,false,true,true,true});
        input.focus(screen.func_146179_b().isEmpty()?(nameLocked?0:1):(nameLocked?1:2),true);
        if(nameLocked)name.func_146184_c(false);
        Keyboard.enableRepeatEvents(true);
    }
    private void back() {field_146297_k.func_147108_a(parent);}
    @Override protected void func_146284_a(GuiButton b) {
        int id=b.field_146127_k;
        if(id==2) {back();return;}
        if(id==4) {field_146297_k.func_147108_a(parent==null?new ManagerGui(screen.func_146179_b()):parent);return;}
        if(id==5) {kind=kind.equals("I")?"F":"I";b.field_146126_j=kind.equals("I")?"Item":"Fluid";removeArmed=false;
            for(Object button:field_146292_n)if(((GuiButton)button).field_146127_k==3)((GuiButton)button).field_146126_j="Remove";return;}
        if(id!=1&&id!=3)return;
        if(id==3&&!removeArmed) {removeArmed=true;b.field_146126_j="Confirm?";feedback="Click Confirm? to stop maintaining this entry.";return;}
        try {
            address=BridgeCommand.address(screen.func_146179_b());
            String command=id==3?BridgeCommand.remove(submitted?savedKind:kind,name.func_146179_b()):BridgeCommand.update(kind,name.func_146179_b(),low.func_146179_b(),target.func_146179_b(),batch.func_146179_b());
            if(id==1 && submitted && !kind.equals(savedKind))
                command="LM2|T|"+savedKind+"|"+command.substring(4);
            ClipboardTransport.send(address,command);
            if(id==1){savedKind=kind;submitted=true;}
            feedback=id==3?"Removal submitted. Check OC for Removed.":"Update submitted. Check OC for Updated.";
            if(parent!=null)parent.changed();
            Properties prefs=new Properties();prefs.setProperty("screen",address);
            prefs.setProperty("low",low.func_146179_b());prefs.setProperty("target",target.func_146179_b());prefs.setProperty("batch",batch.func_146179_b());
            File file=prefsFile();file.getParentFile().mkdirs();
            try(FileOutputStream out=new FileOutputStream(file)) {prefs.store(out,"NEI Level Maintainer");}
            catch(IOException ex) {feedback+=" Could not save local defaults.";}
            removeArmed=false;for(Object button:field_146292_n)if(((GuiButton)button).field_146127_k==3)((GuiButton)button).field_146126_j="Remove";
        }catch(Exception ex) {feedback="Error: "+ex.getMessage();}
    }
    private GuiTextField[] fields() {return nameLocked?new GuiTextField[]{screen,low,target,batch}:new GuiTextField[]{name,screen,low,target,batch};}
    @Override public void func_73876_c() {for(GuiTextField f:fields())f.func_146178_a();}
    @Override protected void func_73869_a(char ch,int key) {
        if(key==Keyboard.KEY_ESCAPE){back();return;}
        if(key==Keyboard.KEY_RETURN||key==Keyboard.KEY_NUMPADENTER){func_146284_a(new FlatButton(1,0,0,"Save"));return;}
        if(key==Keyboard.KEY_TAB) {
            input.next(GuiScreen.func_146272_n());return;
        }
        input.key(ch,key);
        removeArmed=false;for(Object b:field_146292_n)if(((GuiButton)b).field_146127_k==3)((GuiButton)b).field_146126_j="Remove";
    }
    @Override protected void func_73864_a(int x,int y,int b) {input.click(x,y,b);super.func_73864_a(x,y,b);}
    @Override public void func_146281_b() {if(input!=null)input.close();TextInputBuffer.clear();Keyboard.enableRepeatEvents(false);}
    @Override public void func_73863_a(int mx,int my,float partial) {
        func_146276_q_();int x=field_146294_l/2-135,y=field_146295_m/2-110;
        func_73732_a(field_146289_q,"Level Maintainer - add / edit / remove",field_146294_l/2,y,0xffffff);
        field_146289_q.func_78276_b("Display name"+(nameLocked?" (fixed)":""),x,y+13,0xcccccc);
        field_146289_q.func_78276_b("OC screen UUID",x,y+53,0xcccccc);
        field_146289_q.func_78276_b("Low",x,y+93,0xcccccc);field_146289_q.func_78276_b("Target",x+93,y+93,0xcccccc);field_146289_q.func_78276_b("Batch",x+186,y+93,0xcccccc);
        for(GuiTextField f:new GuiTextField[]{name,screen,low,target,batch})f.func_146194_f();
        int line=y+182;for(Object text:field_146289_q.func_78271_c(feedback,270)) {field_146289_q.func_78276_b((String)text,x,line,0xffcc55);line+=10;}
        super.func_73863_a(mx,my,partial);
        if(my>=y+91&&my<y+123) {
            String help=null;
            if(mx>=x&&mx<x+84)help="Start refilling when stock falls BELOW Low. Reaching Low does not stop an active refill.";
            else if(mx>=x+93&&mx<x+177)help="Once started, keep refilling until stock reaches Target. Then wait until it falls below Low again.";
            else if(mx>=x+186&&mx<x+270)help="Maximum amount requested per job. The final request is capped by the amount missing from Target. Recipe output sizes may overshoot.";
            if(help!=null) {
                java.util.List<String> lines=new java.util.ArrayList<>();
                lines.addAll(field_146289_q.func_78271_c(help,Math.max(80,Math.min(220,field_146294_l-24))));
                lines.addAll(field_146289_q.func_78271_c("Items use individual units, not stacks. Fluids use mB (1,000 mB = 1 bucket).",Math.max(80,Math.min(220,field_146294_l-24))));
                func_146283_a(lines,mx,my);
            }
        }
    }
}
