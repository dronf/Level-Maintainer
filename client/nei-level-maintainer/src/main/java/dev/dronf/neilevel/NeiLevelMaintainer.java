package dev.dronf.neilevel;

import cpw.mods.fml.common.Mod;
import cpw.mods.fml.common.SidedProxy;
import cpw.mods.fml.common.event.FMLInitializationEvent;

@Mod(modid="neilevelmaintainer", name="NEI Level Maintainer", version="1.1.4",
    acceptedMinecraftVersions="[1.7.10]", acceptableRemoteVersions="*",
    dependencies="required-after:NotEnoughItems;required-after:OpenComputers")
public final class NeiLevelMaintainer {
    @SidedProxy(clientSide="dev.dronf.neilevel.ClientProxy", serverSide="dev.dronf.neilevel.CommonProxy")
    public static CommonProxy proxy;

    @Mod.EventHandler public void init(FMLInitializationEvent event) { proxy.init(); }
}
