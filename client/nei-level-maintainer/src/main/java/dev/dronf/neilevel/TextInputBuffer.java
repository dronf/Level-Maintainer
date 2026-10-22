package dev.dronf.neilevel;

/** Optional lwjgl3ify buffer cleanup. No hard dependency on lwjgl3ify. */
final class TextInputBuffer {
    private static final StringBuilder BUFFER=find();
    private static StringBuilder find() {
        try {
            Class<?> handler=Class.forName("me.eigenraven.lwjgl3ify.client.TextFieldHandler",true,TextInputBuffer.class.getClassLoader());
            return (StringBuilder)handler.getField("textBuffer").get(null);
        } catch(ReflectiveOperationException | LinkageError absent) {return null;}
    }
    static void clear() {if(BUFFER!=null)BUFFER.setLength(0);}
}
