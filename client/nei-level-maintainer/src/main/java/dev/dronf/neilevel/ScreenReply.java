package dev.dronf.neilevel;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.*;

/** Parse only complete, nonce-matched frames from the synchronized OC screen. */
public final class ScreenReply {
    public final int index,total,protocol,nextIndex;
    public final MaintainedEntry entry;
    public final List<MaintainedEntry> entries;
    private ScreenReply(int index,int total,int protocol,List<MaintainedEntry> entries) {
        this.index=index;this.total=total;this.protocol=protocol;
        this.entries=Collections.unmodifiableList(entries);this.entry=entries.isEmpty()?null:entries.get(0);
        this.nextIndex=protocol==4?index+entries.size():index+1;
    }
    public boolean complete(){return protocol==4?nextIndex==total:index==total;}
    public static ScreenReply parse(String text,String token,int expected) {
        int protocol=4;String marker="LM4R|"+token+"|";int start=text.indexOf(marker);
        while(start<0&&protocol>2){protocol--;marker="LM"+protocol+"R|"+token+"|";start=text.indexOf(marker);}
        if(start<0) return null;
        int end=text.indexOf("|END",start);
        if(end<0) return null;
        int checksumAt=text.lastIndexOf('|',end-1);
        if(checksumAt<start+marker.length()) return null;
        String body=text.substring(start,checksumAt);
        java.util.zip.Adler32 checksum=new java.util.zip.Adler32();
        byte[] encoded=body.getBytes(StandardCharsets.US_ASCII);checksum.update(encoded,0,encoded.length);
        if(!String.format(java.util.Locale.ROOT,"%08x",checksum.getValue()).equals(text.substring(checksumAt+1,end)))return null;
        String[] p=text.substring(start+marker.length(),checksumAt).split("\\|",protocol==4?4:-1);
        if(p.length>1 && p[0].equals("ERR")) throw new IllegalArgumentException(p[1]);
        if(p.length<2) return null;
        int index=Integer.parseInt(p[0]),total=Integer.parseInt(p[1]);
        if(index!=expected) return null;
        if(total<0 || total>10000 || index<0 || index>total) throw new IllegalArgumentException("Invalid list size.");
        List<MaintainedEntry> entries=new ArrayList<>();
        if(protocol==4){
            if(p.length!=4)throw new IllegalArgumentException("Invalid batch reply.");
            int count=Integer.parseInt(p[2]);
            if(count<0||count>64||index+count>total||(count==0&&index<total))throw new IllegalArgumentException("Invalid batch size.");
            String[] records=p[3].isEmpty()?new String[0]:p[3].split(";",-1);
            if(records.length!=count)throw new IllegalArgumentException("Incomplete batch.");
            for(String record:records)entries.add(parseEntry(record.split("\\|",-1),true));
        }else if(index>0)entries.add(parseEntry(Arrays.copyOfRange(p,2,p.length),protocol==3));
        return new ScreenReply(index,total,protocol,entries);
    }
    private static MaintainedEntry parseEntry(String[] p,boolean withPause){
        if(p.length!=(withPause?7:6) || (!p[0].equals("I")&&!p[0].equals("F"))) throw new IllegalArgumentException("Invalid entry reply.");
        if(withPause&&!p[6].equals("0")&&!p[6].equals("1"))throw new IllegalArgumentException("Invalid pause state.");
        String name=decode(p[1]); BridgeCommand.name(name);
        for(int i=2;i<6;i++) if(!p[i].isEmpty()) {
            double n=Double.parseDouble(p[i]);
            if(!Double.isFinite(n) || n<0) throw new IllegalArgumentException("Invalid numeric reply.");
        }
        return new MaintainedEntry(p[0],name,decimal(p[2]),decimal(p[3]),decimal(p[4]),decimal(p[5]),withPause&&p[6].equals("1"));
    }
    private static String decimal(String s) {return s.isEmpty()?s:new java.math.BigDecimal(s).stripTrailingZeros().toPlainString();}
    private static String decode(String hex) {
        if(hex.length()>320 || (hex.length()&1)!=0) throw new IllegalArgumentException("Invalid name encoding.");
        byte[] bytes=new byte[hex.length()/2];
        for(int i=0;i<bytes.length;i++) {
            int a=Character.digit(hex.charAt(i*2),16),b=Character.digit(hex.charAt(i*2+1),16);
            if(a<0||b<0)throw new IllegalArgumentException("Invalid name encoding.");
            bytes[i]=(byte)(a*16+b);
        }
        try { return StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(bytes)).toString(); }
        catch(CharacterCodingException ex) { throw new IllegalArgumentException("Invalid UTF-8 name."); }
    }
}
