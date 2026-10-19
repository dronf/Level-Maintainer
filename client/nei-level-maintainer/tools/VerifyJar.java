import org.objectweb.asm.*;
import java.io.*;
import java.net.*;
import java.util.*;
import java.util.jar.*;

/** Resolves bytecode member references against real SRG Minecraft/Forge/mod JARs.
 * Reads class bytes without initializing Minecraft or requiring a running game.
 */
public final class VerifyJar {
    private static final Map<String, ClassInfo> classes = new HashMap<>();
    private static ClassLoader loader;
    private static int references;
    private static class ClassInfo {
        String parent;
        String[] interfaces;
        Map<String,Integer> methods = new HashMap<>(), fields = new HashMap<>();
    }
    private static ClassInfo info(String name) {
        if (classes.containsKey(name)) return classes.get(name);
        try (InputStream in = loader.getResourceAsStream(name + ".class")) {
            if (in == null) throw new IllegalStateException("Missing class " + name);
            ClassInfo value = new ClassInfo();
            new ClassReader(in).accept(new ClassVisitor(Opcodes.ASM9) {
                public void visit(int v,int a,String n,String sig,String parent,String[] interfaces) {
                    value.parent=parent; value.interfaces=interfaces;
                }
                public MethodVisitor visitMethod(int a,String n,String d,String sig,String[] ex) {
                    value.methods.put(n+d,a); return null;
                }
                public FieldVisitor visitField(int a,String n,String d,String sig,Object data) {
                    value.fields.put(n+":"+d,a); return null;
                }
            }, ClassReader.SKIP_CODE | ClassReader.SKIP_DEBUG | ClassReader.SKIP_FRAMES);
            classes.put(name,value); return value;
        } catch (IOException ex) { throw new RuntimeException(ex); }
    }
    private static Integer member(String owner,String key,boolean method) {
        ClassInfo c=info(owner);
        Integer access=(method?c.methods:c.fields).get(key);
        if(access!=null) return access;
        if(method && key.startsWith("<init>")) return null;
        if(c.parent!=null) { access=member(c.parent,key,method); if(access!=null) return access; }
        for(String i:c.interfaces) { access=member(i,key,method); if(access!=null) return access; }
        return null;
    }
    private static void reference(String owner,String name,String desc,boolean method,boolean isStatic) {
        if(owner.startsWith("[")) return; // JVM array clone
        Integer access=member(owner,name+(method?"":":")+desc,method);
        if(access==null) throw new IllegalStateException("Unresolved " + owner + "." + name + desc);
        if(((access & Opcodes.ACC_STATIC)!=0)!=isStatic) throw new IllegalStateException("Static mismatch: " + owner+"."+name);
        references++;
    }
    public static void main(String[] args) throws Exception {
        List<URL> urls=new ArrayList<>();
        for(String path:args) urls.add(new File(path).toURI().toURL());
        loader=new URLClassLoader(urls.toArray(new URL[0]),ClassLoader.getSystemClassLoader());
        int count=0;
        try(JarFile jar=new JarFile(args[0])) {
            Enumeration<JarEntry> entries=jar.entries();
            while(entries.hasMoreElements()) {
                JarEntry e=entries.nextElement();
                if(!e.getName().endsWith(".class")) continue;
                if(!e.getName().startsWith("dev/dronf/neilevel/")) throw new IllegalStateException("Bundled dependency: "+e.getName());
                byte[] bytes;
                try(InputStream in=jar.getInputStream(e)) {
                    ByteArrayOutputStream out=new ByteArrayOutputStream(); byte[] buf=new byte[4096]; int n;
                    while((n=in.read(buf))!=-1)out.write(buf,0,n); bytes=out.toByteArray();
                }
                if(((bytes[6]&255)<<8 | (bytes[7]&255))!=52) throw new IllegalStateException("Not Java 8 bytecode");
                Class<?> loaded=Class.forName(e.getName().substring(0,e.getName().length()-6).replace('/','.'),false,loader);
                loaded.getDeclaredMethods(); loaded.getDeclaredFields(); // JVM verification without client initialization.
                new ClassReader(bytes).accept(new ClassVisitor(Opcodes.ASM9) {
                    public MethodVisitor visitMethod(int a,String n,String d,String sig,String[] ex) {
                        return new MethodVisitor(Opcodes.ASM9) {
                            public void visitMethodInsn(int op,String owner,String name,String desc,boolean itf) {
                                reference(owner,name,desc,true,op==Opcodes.INVOKESTATIC);
                            }
                            public void visitFieldInsn(int op,String owner,String name,String desc) {
                                reference(owner,name,desc,false,op==Opcodes.GETSTATIC||op==Opcodes.PUTSTATIC);
                            }
                        };
                    }
                },ClassReader.SKIP_DEBUG|ClassReader.SKIP_FRAMES);
                count++;
            }
            if(jar.getJarEntry("mcmod.info")==null)throw new IllegalStateException("Missing metadata");
        }
        // Ensure the GUI overrides the production methods rather than defining MCP-only methods.
        ClassInfo gui=info("dev/dronf/neilevel/MaintenanceGui");
        for(String key:new String[]{"func_73866_w_()V","func_73863_a(IIF)V","func_73869_a(CI)V",
            "func_73864_a(III)V","func_146284_a(Lnet/minecraft/client/gui/GuiButton;)V","func_73868_f()Z"})
            if(!gui.methods.containsKey(key))throw new IllegalStateException("Missing GUI override: "+key);
        for(String common:new String[]{"dev/dronf/neilevel/NeiLevelMaintainer","dev/dronf/neilevel/CommonProxy"})
            Class.forName(common.replace('/','.'),true,loader); // No client initialization.
        System.out.println("PASS: "+count+" Java 8 classes; "+references+" member references resolved; SRG GUI overrides, metadata and common entrypoint verified.");
    }
}
