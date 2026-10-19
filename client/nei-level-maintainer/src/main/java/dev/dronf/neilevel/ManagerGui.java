package dev.dronf.neilevel;

import net.minecraft.client.gui.GuiScreen;
import net.minecraft.client.gui.GuiButton;
import net.minecraft.client.gui.GuiTextField;
import org.lwjgl.input.Keyboard;
import li.cil.oc.client.PacketSender;
import java.util.*;
import java.io.*;

public final class ManagerGui extends GuiScreen {
    private GuiTextField screen,search;
    private final List<MaintainedEntry> entries=new ArrayList<>(),incoming=new ArrayList<>();
    private List<MaintainedEntry> visible=new ArrayList<>();
    private String address="",filter="",status="Enter the OC screen UUID and click Refresh.",token;
    private int page,selected=-1,index,total=-1;
    private long sentAt,nextSend;
    private boolean syncing,removeArmed;
    private int listWidth,left,rows;
    public ManagerGui(String address) { this.address=address; }
    @Override public boolean func_73868_f() { return false; }
    @Override public void func_73866_w_() {
        if(screen!=null)address=screen.func_146179_b();
        if(search!=null)filter=search.func_146179_b();
        if(address.isEmpty())try(FileInputStream in=new FileInputStream(new File(field_146297_k.field_71412_D,"config/nei-level-maintainer.properties"))) {
            Properties prefs=new Properties();prefs.load(in);address=prefs.getProperty("screen","");
        }catch(IOException ignored) { }
        listWidth=Math.min(480,field_146294_l-16);left=(field_146294_l-listWidth)/2;
        rows=Math.max(1,(field_146295_m-150)/21);
        screen=new GuiTextField(field_146289_q,left,28,listWidth-74,18);screen.func_146203_f(36);screen.func_146180_a(address);
        search=new GuiTextField(field_146289_q,left+43,52,listWidth-43,18);search.func_146180_a(filter);
        rebuild();Keyboard.enableRepeatEvents(true);
        if(token==null && !screen.func_146179_b().isEmpty())refreshOnOpen=true;
    }
    private void rebuild() {
        field_146292_n.clear();
        field_146292_n.add(new GuiButton(1,left+listWidth-68,27,68,20,"Refresh"));
        visible=new ArrayList<>();
        for(MaintainedEntry e:entries)if((e.name+" "+e.kind).toLowerCase(Locale.ROOT).contains(filter.toLowerCase(Locale.ROOT)))visible.add(e);
        page=Math.max(0,Math.min(page,Math.max(0,(visible.size()-1)/rows)));
        for(int r=0;r<rows;r++) {
            int at=page*rows+r;if(at>=visible.size())break;
            String label=(selected==at?"> ":"")+visible.get(at).summary();
            field_146292_n.add(new GuiButton(100+r,left,77+r*21,listWidth,20,field_146289_q.func_78269_a(label,listWidth-10)));
        }
        int y=field_146295_m-66,bw=(listWidth-12)/5;
        String[] labels={"Add","Edit",removeArmed?"Confirm?":"Remove","Prev","Next"};
        for(int i=0;i<5;i++) {
            GuiButton b=new GuiButton(2+i,left+i*(bw+3),y,bw,20,labels[i]);
            b.field_146124_l=!syncing && (i!=1&&i!=2 || selected>=0&&selected<visible.size());
            if(i==3)b.field_146124_l=!syncing&&page>0;
            if(i==4)b.field_146124_l=!syncing&&(page+1)*rows<visible.size();
            field_146292_n.add(b);
        }
        field_146292_n.add(new GuiButton(7,left,field_146295_m-24,listWidth,20,"Done"));
    }
    private void refresh() {
        try {
            address=BridgeCommand.address(screen.func_146179_b());
            token=UUID.randomUUID().toString().replace("-","").substring(0,16);
            incoming.clear();index=0;total=-1;syncing=true;sentAt=0;nextSend=System.currentTimeMillis()+150;
            selected=-1;removeArmed=false;status="Reading actual OC configuration...";
            PacketSender.sendTextBufferInit(address);rebuild();
        }catch(Exception ex) { status="Error: "+ex.getMessage(); }
    }
    @Override public void func_73876_c() {
        screen.func_146178_a();search.func_146178_a();
        if(!syncing)return;
        long now=System.currentTimeMillis();
        try {
            if(sentAt>0) {
                ScreenReply reply=ScreenReply.parse(ScreenReader.read(address),token,index);
                if(reply!=null) {
                    if(total<0)total=reply.total;
                    if(total!=reply.total)throw new IllegalStateException("List changed; refresh again.");
                    if(reply.entry!=null)incoming.add(reply.entry);
                    if(index==total) {
                        entries.clear();entries.addAll(incoming);syncing=false;
                        status="Loaded "+entries.size()+" entries from OC.";
                        try { ClipboardTransport.send(address,"LM2|END|"+token); }catch(Exception ignored) { }
                        rebuild();return;
                    }
                    index++;sentAt=0;nextSend=now+100;status="Reading "+index+" / "+total+"...";
                }else if(now-sentAt>8000)throw new IllegalStateException("No reply. Update OC scripts, run Maintainer and open its screen once.");
            }
            if(sentAt==0 && now>=nextSend) {
                try { ClipboardTransport.send(address,"LM2|Q|"+token+"|"+address+"|"+index);sentAt=now; }
                catch(IllegalStateException cooldown) { nextSend=now+100; }
            } else if(sentAt>0 && now>=nextSend && now-sentAt>1000) {
                // Reissue the same page if a dashboard redraw or network update hid it.
                try { ClipboardTransport.send(address,"LM2|Q|"+token+"|"+address+"|"+index); }catch(IllegalStateException ignored) { }
                nextSend=now+1000;
            }
        }catch(Exception ex) { syncing=false;status="Sync failed: "+ex.getMessage();rebuild(); }
    }
    @Override protected void func_146284_a(GuiButton button) {
        int id=button.field_146127_k;
        if(id>=100) {selected=page*rows+id-100;removeArmed=false;rebuild();return;}
        if(id==7) {field_146297_k.func_147108_a(null);return;}
        if(id==1) {refresh();return;}
        if(syncing)return;
        address=screen.func_146179_b();
        if(id==2)field_146297_k.func_147108_a(new MaintenanceGui(this,null,address));
        if(id==3 && selected>=0 && selected<visible.size())field_146297_k.func_147108_a(new MaintenanceGui(this,visible.get(selected),address));
        if(id==4 && selected>=0 && selected<visible.size()) {
            if(!removeArmed) {removeArmed=true;status="Click Confirm? to stop maintaining this entry (including base config).";rebuild();return;}
            try {
                MaintainedEntry entry=visible.get(selected);
                address=BridgeCommand.address(screen.func_146179_b());
                ClipboardTransport.send(address,BridgeCommand.remove(entry.kind,entry.name));
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
        screen.func_146201_a(ch,key);search.func_146201_a(ch,key);
        if(!screen.func_146179_b().equals(address)) {
            address=screen.func_146179_b();syncing=false;entries.clear();selected=-1;removeArmed=false;
            status="Screen changed; click Refresh to load its entries.";rebuild();
        }
        String f=search.func_146179_b();
        if(!f.equals(filter)) {filter=f;selected=-1;page=0;removeArmed=false;rebuild();}
    }
    @Override protected void func_73864_a(int x,int y,int b) {
        super.func_73864_a(x,y,b);screen.func_146192_a(x,y,b);search.func_146192_a(x,y,b);
    }
    @Override public void func_146281_b() {Keyboard.enableRepeatEvents(false);}
}
