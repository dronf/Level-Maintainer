package dev.dronf.neilevel;

public final class MaintainedEntry {
    public final String kind, name, low, target, batch, refill;
    public MaintainedEntry(String kind,String name,String low,String target,String batch,String refill) {
        this.kind=kind; this.name=name; this.low=low; this.target=target; this.batch=batch; this.refill=refill;
    }
    public String summary() {
        return "["+kind+"] "+name+" | "+(low.isEmpty()?"always":low)+" -> "+(target.isEmpty()?"legacy":target)+" / "+batch;
    }
}
