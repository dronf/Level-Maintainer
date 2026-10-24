package dev.dronf.neilevel;

import java.io.*;
import java.lang.reflect.*;
import java.util.*;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.*;
import static dev.dronf.neilevel.ManagerPauseTest.*;

/** Exercise real manager tick/control code with delayed and corrupted screen replies. */
public final class ManagerSyncTest {
    private static int checks;
    private static void check(boolean value){checks++;if(!value)throw new AssertionError("manager sync check "+checks);}
    private static final String IRON="I|49726f6e|100|200|64|2|0",WATER="F|5761746572|10|20|4|1|1",GOLD="I|476f6c64|1|2|3||0";
    private static final class Link implements ManagerGui.Channel{
        long time=1000;String text="";List<String> commands=new ArrayList<>();
        public long now(){return time;}public String read(String address){return text;}
        public void initialize(String address){}
        public void send(String address,String message){commands.add(message);}
        String last(){return commands.get(commands.size()-1);}
        String token(){return last().split("\\|")[2];}
        void reply(String token,String fields){text=ScreenReplyTest.frame("LM4R|"+token+"|"+fields+"|END");}
        void legacy(String token,String fields){text=ScreenReplyTest.frame("LM3R|"+token+"|"+fields+"|END");}
        void tick(ManagerGui gui,long delay){time+=delay;gui.func_73876_c();}
    }
    private static void refresh(ManagerGui gui,Link link){link.text="";gui.func_146284_a(buttonUnchecked(gui,1));link.tick(gui,50);}
    private static GuiButton buttonUnchecked(ManagerGui gui,int id){try{return button(gui,id);}catch(Exception e){throw new AssertionError(e);}}
    public static void main(String[] args)throws Exception{
        Minecraft mc=(Minecraft)allocate(Minecraft.class);mc.field_71466_p=(FontRenderer)allocate(FieldFocusTest.TestFont.class);
        Field dir=Minecraft.class.getDeclaredField("field_71412_D");dir.setAccessible(true);dir.set(mc,new File(args[0],"sync-test"));
        Link link=new Link();ManagerGui gui=new ManagerGui("2ba877c7-82c0-42df-96e6-27c880772f9d",link);
        gui.func_146280_a(mc,640,360);
        List<MaintainedEntry> entries=(List<MaintainedEntry>)property("entries").get(gui);
        entries.add(new MaintainedEntry("I","Iron","100","200","64","2"));
        entries.add(new MaintainedEntry("F","Water","10","20","4","1",true));property("verified").setBoolean(gui,true);rebuild(gui);
        gui.func_146284_a(button(gui,101));refresh(gui,link);
        check(link.last().startsWith("LM4|Q|")&&link.last().endsWith("|0"));String token=link.token();
        check(button(gui,1).field_146126_j.equals("Cancel")&&!button(gui,8).field_146124_l);
        link.reply(token,"0|3|2|"+IRON+";"+WATER);link.tick(gui,50);
        check(link.last().endsWith("|2")&&entries.size()==2&&!property("verified").getBoolean(gui));
        int sent=link.commands.size();link.tick(gui,50);check(link.commands.size()==sent); // stale offset zero
        link.tick(gui,1100);check(link.commands.size()==sent+1&&link.last().endsWith("|2"));
        link.reply(token,"2|3|1|"+GOLD);link.text=link.text.substring(0,link.text.length()-1);link.tick(gui,50);
        check(entries.size()==2&&!property("verified").getBoolean(gui)); // partial frame
        link.reply(token,"2|3|1|"+GOLD);link.tick(gui,50);
        check(entries.size()==3&&property("verified").getBoolean(gui)&&!property("syncing").getBoolean(gui));
        check(property("selected").getInt(gui)==1&&button(gui,8).field_146126_j.equals("Resume"));
        check(link.last().equals("LM2|END|"+token)&&((String)property("status").get(gui)).contains("entries in"));
        sent=link.commands.size();gui.func_146281_b();check(link.commands.size()==sent); // already released
        // Cancel leaves the previous list visible but does not allow stale mutations.
        refresh(gui,link);token=link.token();gui.func_146284_a(button(gui,1));
        check(link.last().equals("LM2|END|"+token)&&entries.size()==3&&!property("syncing").getBoolean(gui));
        gui.func_146284_a(button(gui,100));check(!button(gui,8).field_146124_l&&!button(gui,3).field_146124_l);
        // Old receiver fallback uses a new nonce and rejects late LM4 data.
        refresh(gui,link);String oldToken=link.token();link.tick(gui,1500);token=link.token();
        check(link.last().startsWith("LM3|Q|")&&!token.equals(oldToken));
        link.reply(oldToken,"0|0|0|");link.tick(gui,50);check(property("syncing").getBoolean(gui));
        link.legacy(token,"0|1|");link.tick(gui,50);check(link.last().endsWith("|1"));
        link.legacy(token,"1|1|"+WATER);link.tick(gui,50);
        check(entries.size()==1&&entries.get(0).paused&&property("verified").getBoolean(gui));
        check(((String)property("status").get(gui)).contains("Update OC scripts"));
        // A changed total aborts atomically and releases the overlay.
        refresh(gui,link);token=link.token();link.reply(token,"0|3|2|"+IRON+";"+WATER);link.tick(gui,50);
        link.reply(token,"2|4|1|"+GOLD);link.tick(gui,50);
        check(entries.size()==1&&!property("verified").getBoolean(gui)&&link.last().equals("LM2|END|"+token));
        check(((String)property("status").get(gui)).contains("List changed"));
        // Empty list completes on its first reply, without a count-only handshake.
        refresh(gui,link);token=link.token();link.reply(token,"0|0|0|");link.tick(gui,50);
        check(entries.isEmpty()&&property("verified").getBoolean(gui));
        refresh(gui,link);token=link.token();gui.func_146281_b();
        check(link.last().equals("LM2|END|"+token)&&!property("syncing").getBoolean(gui));
        // No-reply timeout on the legacy fallback keeps mutation controls disabled.
        refresh(gui,link);link.tick(gui,1500);token=link.token();link.tick(gui,8100);
        check(!property("syncing").getBoolean(gui)&&!property("verified").getBoolean(gui));
        check(link.last().equals("LM2|END|"+token));
        gui.func_146281_b();
        System.out.println("PASS: real manager bulk/fallback sync, delayed/partial replies, atomic commit, selection, cancel/close and timeout: "+checks+" checks");
    }
}
