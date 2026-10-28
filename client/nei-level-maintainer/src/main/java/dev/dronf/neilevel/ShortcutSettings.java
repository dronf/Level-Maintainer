package dev.dronf.neilevel;

import java.io.*;
import java.util.Arrays;
import java.util.Properties;
import net.minecraft.client.settings.GameSettings;
import net.minecraft.client.settings.KeyBinding;
import org.lwjgl.input.Keyboard;

/** Key codes belong to vanilla options.txt; modifiers have a separate file. */
public final class ShortcutSettings {
    public enum Modifier { NONE, CTRL, ALT, SHIFT }
    public static final KeyBinding CONTEXT=new KeyBinding("Editor or manager shortcut",Keyboard.KEY_M,"NEI Level Maintainer");
    public static final KeyBinding MANAGER=new KeyBinding("Open manager shortcut",Keyboard.KEY_NONE,"NEI Level Maintainer");
    static Modifier contextModifier=Modifier.CTRL,managerModifier=Modifier.NONE;
    private static File file;
    private ShortcutSettings(){}
    public static void load(File directory){
        file=new File(directory,"config/nei-level-maintainer-hotkeys.properties");
        Properties p=new Properties();
        try(FileInputStream in=new FileInputStream(file)){p.load(in);}catch(IOException ignored){}
        contextModifier=parse(p.getProperty("contextModifier"),Modifier.CTRL);
        managerModifier=parse(p.getProperty("managerModifier"),Modifier.NONE);
    }
    private static Modifier parse(String value,Modifier fallback){
        try{return Modifier.valueOf(value);}catch(IllegalArgumentException|NullPointerException ex){return fallback;}
    }
    public static void register(GameSettings settings){
        // Same array registration as Forge 1.7.10 ClientRegistry, using SRG APIs.
        for(KeyBinding binding:new KeyBinding[]{CONTEXT,MANAGER}){
            boolean found=false;
            for(KeyBinding existing:settings.field_74324_K)if(existing==binding)found=true;
            if(!found){
                settings.field_74324_K=Arrays.copyOf(settings.field_74324_K,settings.field_74324_K.length+1);
                settings.field_74324_K[settings.field_74324_K.length-1]=binding;
            }
        }
    }
    public static void save(GameSettings settings)throws IOException{
        settings.func_74303_b();
        if(file==null)return;
        Properties p=new Properties();
        p.setProperty("contextModifier",contextModifier.name());
        p.setProperty("managerModifier",managerModifier.name());
        File parent=file.getParentFile();
        if(!parent.isDirectory()&&!parent.mkdirs())throw new IOException("Cannot create config directory");
        try(FileOutputStream out=new FileOutputStream(file)){p.store(out,"NEI Level Maintainer shortcut modifiers; key codes are in options.txt");}
    }
    static boolean ctrl(){return Keyboard.isKeyDown(Keyboard.KEY_LCONTROL)||Keyboard.isKeyDown(Keyboard.KEY_RCONTROL);}
    static boolean alt(){return Keyboard.isKeyDown(Keyboard.KEY_LMENU)||Keyboard.isKeyDown(Keyboard.KEY_RMENU);}
    static boolean shift(){return Keyboard.isKeyDown(Keyboard.KEY_LSHIFT)||Keyboard.isKeyDown(Keyboard.KEY_RSHIFT);}
    static boolean anyModifier(){return ctrl()||alt()||shift();}
    private static boolean matches(int key,KeyBinding binding,Modifier modifier,boolean extraShift){
        return binding.func_151463_i()>0&&!modifierKey(key)&&key==binding.func_151463_i()
            &&ctrl()==(modifier==Modifier.CTRL)&&alt()==(modifier==Modifier.ALT)
            &&(shift()==(modifier==Modifier.SHIFT)||(extraShift&&shift()));
    }
    static boolean context(int key){return matches(key,CONTEXT,contextModifier,true);}
    static boolean manager(int key){return matches(key,MANAGER,managerModifier,false);}
    static boolean forceManager(int key){return manager(key)||(context(key)&&shift()&&contextModifier!=Modifier.SHIFT);}
    static boolean modifierKey(int key){return key==Keyboard.KEY_LCONTROL||key==Keyboard.KEY_RCONTROL
        ||key==Keyboard.KEY_LMENU||key==Keyboard.KEY_RMENU||key==Keyboard.KEY_LSHIFT||key==Keyboard.KEY_RSHIFT;}
    static void key(KeyBinding binding,int code){binding.func_151462_b(code);KeyBinding.func_74508_b();}
    static String keyName(KeyBinding binding){
        int key=binding.func_151463_i();
        if(key==0)return "Unbound";
        return key>0?Keyboard.getKeyName(key):"Mouse "+(key+101)+" (choose a keyboard key)";
    }
}
