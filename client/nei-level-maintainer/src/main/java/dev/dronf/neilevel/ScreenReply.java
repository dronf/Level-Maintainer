package dev.dronf.neilevel;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;

/** Parse only complete, nonce-matched frames from the synchronized OC screen. */
public final class ScreenReply {
    public final int index,total;
    public final MaintainedEntry entry;
    private ScreenReply(int index,int total,MaintainedEntry entry) { this.index=index; this.total=total; this.entry=entry; }
    public static ScreenReply parse(String text,String token,int expected) {
        String marker="LM3R|"+token+"|";
        int start=text.indexOf(marker);
        boolean withPause=start>=0;
        if(!withPause){marker="LM2R|"+token+"|";start=text.indexOf(marker);}
        if(start<0) return null;
        int end=text.indexOf("|END",start);
        if(end<0) return null;
        int checksumAt=text.lastIndexOf('|',end-1);
        if(checksumAt<start+marker.length()) return null;
        String body=text.substring(start,checksumAt);
        java.util.zip.Adler32 checksum=new java.util.zip.Adler32();
        byte[] encoded=body.getBytes(StandardCharsets.US_ASCII);checksum.update(encoded,0,encoded.length);
        if(!String.format(java.util.Locale.ROOT,"%08x",checksum.getValue()).equals(text.substring(checksumAt+1,end)))return null;
        String[] p=text.substring(start+marker.length(),checksumAt).split("\\|",-1);
        if(p.length>1 && p[0].equals("ERR")) throw new IllegalArgumentException(p[1]);
        if(p.length<2) return null;
        int index=Integer.parseInt(p[0]),total=Integer.parseInt(p[1]);
        if(index!=expected) return null;
        if(total<0 || total>10000 || index<0 || index>total) throw new IllegalArgumentException("Invalid list size.");
        if(index==0) return new ScreenReply(index,total,null);
        if(p.length!=(withPause?9:8) || (!p[2].equals("I")&&!p[2].equals("F"))) throw new IllegalArgumentException("Invalid entry reply.");
        if(withPause&&!p[8].equals("0")&&!p[8].equals("1"))throw new IllegalArgumentException("Invalid pause state.");
        String name=decode(p[3]); BridgeCommand.name(name);
        for(int i=4;i<8;i++) if(!p[i].isEmpty()) {
            double n=Double.parseDouble(p[i]);
            if(!Double.isFinite(n) || n<0) throw new IllegalArgumentException("Invalid numeric reply.");
        }
        return new ScreenReply(index,total,new MaintainedEntry(p[2],name,decimal(p[4]),decimal(p[5]),decimal(p[6]),decimal(p[7]),withPause&&p[8].equals("1")));
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
