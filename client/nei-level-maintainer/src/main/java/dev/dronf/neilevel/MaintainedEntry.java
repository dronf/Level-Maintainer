package dev.dronf.neilevel;

public final class MaintainedEntry {
    public final String kind, name, low, target, batch, refill;
    public final boolean paused;
    public MaintainedEntry(String kind,String name,String low,String target,String batch,String refill) {
        this(kind,name,low,target,batch,refill,false);
    }
    public MaintainedEntry(String kind,String name,String low,String target,String batch,String refill,boolean paused) {
        this.paused=paused;
        this.kind=kind; this.name=name; this.low=low; this.target=target; this.batch=batch; this.refill=refill;
    }
    public String summary() {
        return (paused?"[Paused] ":"")+"["+kind+"] "+name+" | "+(low.isEmpty()?"always":low)+" -> "+(target.isEmpty()?"legacy":target)+" / "+batch;
    }
}
