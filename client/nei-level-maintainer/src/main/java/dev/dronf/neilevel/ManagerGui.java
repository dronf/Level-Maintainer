package dev.dronf.neilevel;

import net.minecraft.client.gui.GuiScreen;
import net.minecraft.client.gui.GuiButton;
import net.minecraft.client.gui.GuiTextField;
import org.lwjgl.input.Keyboard;
import org.lwjgl.input.Mouse;
import li.cil.oc.client.PacketSender;
import java.util.*;
import java.io.*;

public final class ManagerGui extends MaintainerScreen {
    private GuiTextField screen,search;
    private FieldFocus input;
    private final List<MaintainedEntry> entries=new ArrayList<>(),incoming=new ArrayList<>();
    private List<MaintainedEntry> visible=new ArrayList<>();
    private String address="",filter="",status="Enter the OC screen UUID and click Refresh.",token;
    private int page,selected=-1,index,total=-1,protocol=4;
    private long sentAt,nextSend,startedAt;
    private boolean syncing,removeArmed,verified,sessionOpen;
    private String selectionKind,selectionName;
    private int listWidth,left,rows;
    interface Channel {
        void send(String address,String message);void initialize(String address);
        default String read(String address){return ScreenReader.read(address);}
        default long now(){return System.currentTimeMillis();}
    }
    private final Channel channel;
    public ManagerGui(String address) {this(address,new Channel(){
        public void send(String a,String m){ClipboardTransport.send(a,m);}
        public void initialize(String a){PacketSender.sendTextBufferInit(a);}
    });}
    ManagerGui(String address,Channel channel){this.address=address;this.channel=channel;}
    @Override public boolean func_73868_f() { return false; }
    @Override public void func_73866_w_() {
        if(input!=null)input.close();beginInput();
        if(screen!=null)address=screen.func_146179_b();
        if(search!=null)filter=search.func_146179_b();
        if(address.isEmpty())try(FileInputStream in=new FileInputStream(new File(field_146297_k.field_71412_D,"config/nei-level-maintainer.properties"))) {
            Properties prefs=new Properties();prefs.load(in);address=prefs.getProperty("screen","");
        }catch(IOException ignored) { }
        listWidth=Math.min(480,field_146294_l-16);left=(field_146294_l-listWidth)/2;
        rows=Math.max(1,(field_146295_m-150)/21);
        screen=new GuiTextField(field_146289_q,left,28,listWidth-74,18);screen.func_146203_f(36);screen.func_146180_a(address);
        search=new GuiTextField(field_146289_q,left+43,52,listWidth-43,18);search.func_146180_a(filter);
        input=new FieldFocus(new GuiTextField[]{screen,search},new boolean[]{false,false});
        input.focus(address.isEmpty()?0:1,false);
        rebuild();Keyboard.enableRepeatEvents(true);
        if(token==null && !screen.func_146179_b().isEmpty())refreshOnOpen=true;
    }
    private void rebuild() {
        field_146292_n.clear();
        field_146292_n.add(new FlatButton(1,left+listWidth-68,27,68,20,syncing?"Cancel":"Refresh"));
        visible=new ArrayList<>();
        for(MaintainedEntry e:entries)if((e.name+" "+e.kind+(e.paused?" paused":"")).toLowerCase(Locale.ROOT).contains(filter.toLowerCase(Locale.ROOT)))visible.add(e);
        page=Math.max(0,Math.min(page,Math.max(0,(visible.size()-1)/rows)));
        for(int r=0;r<rows;r++) {
            int at=page*rows+r;if(at>=visible.size())break;
            String label=(selected==at?"> ":"")+visible.get(at).summary();
            FlatButton row=new FlatButton(100+r,left,77+r*21,listWidth,20,field_146289_q.func_78269_a(label,listWidth-10));
            if(visible.get(at).paused)row.textColor(0xcc88ff);
            field_146292_n.add(row);
        }
        int y=field_146295_m-66,bw=(listWidth-15)/6;
        boolean hasSelection=selected>=0&&selected<visible.size();
        String[] labels={"Add","Edit",hasSelection&&visible.get(selected).paused?"Resume":"Pause",removeArmed?"Confirm?":"Remove","Prev","Next"};
        int[] ids={2,3,8,4,5,6};
        for(int i=0;i<ids.length;i++) {
            GuiButton b=new FlatButton(ids[i],left+i*(bw+3),y,bw,20,labels[i]);
            b.field_146124_l=!syncing&&(ids[i]==2||verified&&hasSelection);
            if(ids[i]==5)b.field_146124_l=!syncing&&page>0;
            if(ids[i]==6)b.field_146124_l=!syncing&&(page+1)*rows<visible.size();
            field_146292_n.add(b);
        }
        field_146292_n.add(new FlatButton(7,left,field_146295_m-24,listWidth,20,"Done"));
    }
    private void refresh() {
        try {
            address=BridgeCommand.address(screen.func_146179_b());
            if(selected>=0&&selected<visible.size()){
                selectionKind=visible.get(selected).kind;selectionName=visible.get(selected).name;
            }
            endSession();token=UUID.randomUUID().toString().replace("-","").substring(0,16);
            incoming.clear();index=0;total=-1;protocol=4;syncing=true;verified=false;sentAt=0;
            startedAt=channel.now();nextSend=startedAt;
            selected=-1;removeArmed=false;status="Reading actual OC configuration...";
            channel.initialize(address);rebuild();
        }catch(Exception ex) { syncing=false;verified=false;status="Error: "+ex.getMessage();rebuild(); }
    }
    private void endSession(){
        if(sessionOpen&&token!=null)try{channel.send(address,"LM2|END|"+token);}catch(Exception ignored){}
        sessionOpen=false;
    }
    private void finish(long now){
        entries.clear();entries.addAll(incoming);syncing=false;verified=true;
        status="Loaded "+entries.size()+" entries in "+String.format(Locale.ROOT,"%.1fs",(now-startedAt)/1000.0)+".";
        if(protocol==3)status+=" Update OC scripts for faster sync.";
        endSession();rebuild();
        for(int i=0;i<visible.size();i++)if(visible.get(i).kind.equals(selectionKind)&&visible.get(i).name.equals(selectionName)){
            selected=i;page=i/rows;break;
        }
        rebuild();
        File file=new File(field_146297_k.field_71412_D,"config/nei-level-maintainer.properties");
        Properties prefs=new Properties();
        try{
            if(file.isFile())try(FileInputStream in=new FileInputStream(file)){prefs.load(in);}
            prefs.setProperty("screen",address);file.getParentFile().mkdirs();
            try(FileOutputStream out=new FileOutputStream(file)){prefs.store(out,"NEI Level Maintainer");}
        }catch(IOException ignored){}
    }
    @Override public void func_73876_c() {
        screen.func_146178_a();search.func_146178_a();
        if(!syncing)return;
        long now=channel.now();
        try {
            if(sentAt>0) {
                ScreenReply reply=ScreenReply.parse(channel.read(address),token,index);
                if(reply!=null&&reply.protocol==protocol) {
                    if(total<0)total=reply.total;
                    if(total!=reply.total)throw new IllegalStateException("List changed; refresh again.");
                    incoming.addAll(reply.entries);
                    if(reply.complete()){finish(now);return;}
                    index=reply.nextIndex;sentAt=0;nextSend=now;status="Reading "+incoming.size()+" / "+total+"...";
                }else if(protocol==4&&index==0&&now-sentAt>=1500){
                    endSession();protocol=3;token=UUID.randomUUID().toString().replace("-","").substring(0,16);
                    sentAt=0;nextSend=now;status="Trying the older OC listing protocol...";
                }else if(now-sentAt>8000)throw new IllegalStateException("No reply. Update OC scripts, run Maintainer and open its screen once.");
            }
            if(sentAt==0 && now>=nextSend) {
                try { channel.send(address,"LM"+protocol+"|Q|"+token+"|"+address+"|"+index);sentAt=now;sessionOpen=true; }
                catch(IllegalStateException cooldown) { nextSend=now+100; }
            } else if(sentAt>0 && now>=nextSend && now-sentAt>1000) {
                // Reissue the same page if a dashboard redraw or network update hid it.
                try { channel.send(address,"LM"+protocol+"|Q|"+token+"|"+address+"|"+index); }catch(IllegalStateException ignored) { }
                nextSend=now+1000;
            }
        }catch(Exception ex) { syncing=false;verified=false;endSession();status="Sync failed: "+ex.getMessage();rebuild(); }
    }
    @Override protected void func_146284_a(GuiButton button) {
        int id=button.field_146127_k;
        if(id>=100) {selected=page*rows+id-100;removeArmed=false;rebuild();return;}
        if(id==7) {field_146297_k.func_147108_a(null);return;}
        if(id==1) {
            if(syncing){endSession();syncing=false;status="Refresh cancelled. Click Refresh to load current entries.";rebuild();}
            else refresh();return;
        }
        if(syncing)return;
        if((id==3||id==4||id==8)&&!verified)return;
        address=screen.func_146179_b();
        if(id==2)field_146297_k.func_147108_a(new MaintenanceGui(this,null,address));
        if(id==3 && selected>=0 && selected<visible.size())field_146297_k.func_147108_a(new MaintenanceGui(this,visible.get(selected),address));
        if(id==8 && selected>=0 && selected<visible.size()) {
            try {
                MaintainedEntry entry=visible.get(selected);
                address=BridgeCommand.address(screen.func_146179_b());
                channel.send(address,BridgeCommand.pause(entry.kind,entry.name,!entry.paused));
                refresh();
            }catch(Exception ex){status="Error: "+ex.getMessage();}
            return;
        }
        if(id==4 && selected>=0 && selected<visible.size()) {
            if(!removeArmed) {removeArmed=true;status="Click Confirm? to stop maintaining this entry (including base config).";rebuild();return;}
            try {
                MaintainedEntry entry=visible.get(selected);
                address=BridgeCommand.address(screen.func_146179_b());
                channel.send(address,BridgeCommand.remove(entry.kind,entry.name));
                refresh();
            }catch(Exception ex) {status="Error: "+ex.getMessage();}
        }
        if(id==5||id==6) {page+=id==5?-1:1;selected=-1;removeArmed=false;rebuild();}
    }
    public void changed() { refreshOnOpen=true; }
    private boolean refreshOnOpen;
    @Override public void func_73863_a(int mx,int my,float partial) {
        if(refreshOnOpen) {refreshOnOpen=false;refresh();}
        func_146276_q_();
        func_73732_a(field_146289_q,"Level Maintainer | "+visible.size()+" entries | "+(page+1)+"/"+Math.max(1,(visible.size()+rows-1)/rows),field_146294_l/2,10,0xffffff);
        field_146289_q.func_78276_b("Filter",left,57,0xcccccc);
        screen.func_146194_f();search.func_146194_f();
        int y=field_146295_m-43;
        int count=0;for(Object line:field_146289_q.func_78271_c(status,listWidth)) {if(count++==2)break;field_146289_q.func_78276_b((String)line,left,y,0xffcc55);y+=10;}
        super.func_73863_a(mx,my,partial);
    }
    @Override protected void func_73869_a(char ch,int key) {
        if(key==Keyboard.KEY_ESCAPE) {field_146297_k.func_147108_a(null);return;}
        if(key==Keyboard.KEY_RETURN) {refresh();return;}
        if(key==Keyboard.KEY_TAB) {input.next(GuiScreen.func_146272_n());return;}
        input.key(ch,key);
        if(!screen.func_146179_b().equals(address)) {
            endSession();address=screen.func_146179_b();syncing=false;verified=false;entries.clear();selected=-1;removeArmed=false;
            selectionKind=null;selectionName=null;
            status="Screen changed; click Refresh to load its entries.";rebuild();
        }
        String f=search.func_146179_b();
        if(!f.equals(filter)) {filter=f;selected=-1;page=0;removeArmed=false;rebuild();}
    }
    @Override protected void func_73864_a(int x,int y,int b) {
        input.click(x,y,b);super.func_73864_a(x,y,b);
    }
    @Override public void func_146274_d(){
        super.func_146274_d();int wheel=Mouse.getEventDWheel();
        if(!syncing&&wheel!=0){page+=wheel>0?-1:1;selected=-1;removeArmed=false;rebuild();}
    }
    @Override public void func_146281_b() {
        if(syncing){endSession();syncing=false;refreshOnOpen=true;}
        if(input!=null)input.close();TextInputBuffer.clear();Keyboard.enableRepeatEvents(false);
    }
}
