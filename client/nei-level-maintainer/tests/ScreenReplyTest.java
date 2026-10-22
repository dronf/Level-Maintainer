package dev.dronf.neilevel;

import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

public final class ScreenReplyTest {
    static int checks;
    static void check(boolean b){checks++;if(!b)throw new AssertionError("check "+checks);}
    static void reject(Runnable r){try{r.run();}catch(IllegalArgumentException ex){checks++;return;}throw new AssertionError("accepted invalid frame");}
    static String frame(String s) {
        String body=s.substring(0,s.length()-4);
        java.util.zip.Adler32 crc=new java.util.zip.Adler32();byte[] b=body.getBytes(StandardCharsets.US_ASCII);crc.update(b,0,b.length);
        return body+"|"+String.format(Locale.ROOT,"%08x",crc.getValue())+"|END";
    }
    public static void main(String[] args)throws Exception {
        String t="0123456789abcdef",p="LM2R|"+t+"|";
        check(ScreenReply.parse("ordinary dashboard",t,0)==null);
        check(ScreenReply.parse(frame(p+"0|2||END").replace("|2|","|3|"),t,0)==null);
        check(ScreenReply.parse(p+"0|2||EN",t,0)==null);
        check(ScreenReply.parse(frame(p+"0|2||END"),"ffffffffffffffff",0)==null);
        check(ScreenReply.parse(frame(p+"0|2||END"),t,1)==null);
        check(ScreenReply.parse(frame(p+"0|2||END"),t,0).total==2);
        MaintainedEntry e=ScreenReply.parse(frame(p+"1|2|I|436166c3a9|1|1e+12|64|1.5|END"),t,1).entry;
        check(e.name.equals("Caf\u00e9")&&e.target.equals("1000000000000")&&e.refill.equals("1.5"));
        check(ScreenReply.parse(frame(p+"2|2|I|41|||64||END"),t,2).entry.target.isEmpty());
        reject(()->ScreenReply.parse(frame(p+"ERR|Screen too small|END"),t,0));
        reject(()->ScreenReply.parse(frame(p+"0|10001||END"),t,0));
        reject(()->ScreenReply.parse(frame(p+"1|1|X|41|1|2|1||END"),t,1));
        reject(()->ScreenReply.parse(frame(p+"1|1|I|zz|1|2|1||END"),t,1));
        reject(()->ScreenReply.parse(frame(p+"1|1|I|ff|1|2|1||END"),t,1));
        reject(()->ScreenReply.parse(frame(p+"1|1|I|41|NaN|2|1||END"),t,1));
        check(BridgeCommand.remove("I","Iron").equals("LM2|D|I|Iron"));
        check(BridgeCommand.update("F","Water","1","2","3").equals("LM1|F|Water|1|2|3"));
        reject(()->BridgeCommand.remove("I","Bad|Name"));
        reject(()->BridgeCommand.remove("X","Iron"));
        String p3="LM3R|"+t+"|";
        MaintainedEntry paused=ScreenReply.parse(frame(p3+"1|1|I|49726f6e|100|200|64|2|1|END"),t,1).entry;
        check(paused.paused&&paused.summary().startsWith("[Paused]"));
        check(!ScreenReply.parse(frame(p3+"1|1|F|5761746572|1|2|3||0|END"),t,1).entry.paused);
        reject(()->ScreenReply.parse(frame(p3+"1|1|I|41|1|2|3||yes|END"),t,1));
        reject(()->ScreenReply.parse(frame(p3+"1|1|I|41|1|2|3||END"),t,1));
        check(BridgeCommand.pause("I","Iron",true).equals("LM2|P|I|Iron|1"));
        check(BridgeCommand.pause("F","Water",false).equals("LM2|P|F|Water|0"));
        reject(()->BridgeCommand.pause("X","Iron",true));
        reject(()->BridgeCommand.pause("I","Bad|Name",true));
        if(args.length>0) {
            List<String> frames=Files.readAllLines(Paths.get(args[0]),StandardCharsets.UTF_8);
            check(frames.size()==5);
            for(int i=0;i<frames.size();i++) {
                ScreenReply r=ScreenReply.parse(frames.get(i),t,i);check(r!=null&&r.total==4);
            }
            check(ScreenReply.parse(frames.get(1),t,1).entry.kind.equals("F"));
            check(ScreenReply.parse(frames.get(2),t,2).entry.name.equals("Caf\u00e9"));
        }
        if(args.length>1) {
            List<String> frames=Files.readAllLines(Paths.get(args[1]),StandardCharsets.UTF_8);
            check(frames.size()==5);int pausedCount=0;
            for(int i=0;i<frames.size();i++) {
                ScreenReply r=ScreenReply.parse(frames.get(i),t,i);check(r!=null&&r.total==4);
                if(r.entry!=null&&r.entry.paused)pausedCount++;
            }
            check(pausedCount==3);
        }
        System.out.println("PASS: Screen reply / remove / fluid command checks: "+checks);
    }
}
