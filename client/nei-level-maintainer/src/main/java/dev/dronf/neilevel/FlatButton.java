package dev.dronf.neilevel;

import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiButton;

/** Vanilla's button texture is only 200px wide; wider buttons sample outside it. */
public class FlatButton extends GuiButton {
    private int textColor=-1;
    public FlatButton textColor(int color){this.textColor=color;return this;}
    public FlatButton(int id,int x,int y,int width,int height,String label){super(id,x,y,width,height,label);}
    public FlatButton(int id,int x,int y,String label){this(id,x,y,200,20,label);}
    @Override public void func_146112_a(Minecraft mc,int mouseX,int mouseY) {
        if(!field_146125_m)return;
        int x=field_146128_h,y=field_146129_i,w=field_146120_f,h=field_146121_g;
        field_146123_n=mouseX>=x&&mouseX<x+w&&mouseY>=y&&mouseY<y+h;
        int edge=field_146124_l?(field_146123_n?0xff9aaadb:0xff777777):0xff444444;
        int fill=field_146124_l?(field_146123_n?0xff404c70:0xff303030):0xff202020;
        rectangle(x,y,x+w,y+h,edge);rectangle(x+1,y+1,x+w-1,y+h-1,fill);
        label(mc,field_146126_j,x+w/2,y+(h-8)/2,field_146124_l?(textColor!=-1?textColor:field_146123_n?0xffffa0:0xe0e0e0):0xa0a0a0);
    }
    protected void rectangle(int left,int top,int right,int bottom,int color){func_73734_a(left,top,right,bottom,color);}
    protected void label(Minecraft mc,String text,int x,int y,int color){func_73732_a(mc.field_71466_p,text,x,y,color);}
}
