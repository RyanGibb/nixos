{ ... }:

{
  # to create:
  #   zpool create tank mirror /dev/disk/by-id/ata-ST16000NM001G-2KK103_ZL28CDKQ /dev/disk/by-id/ata-TOSHIBA_MG08ACA16TE_83E0A00UFVGG
  #   truncate -s 512G /var/zfs_cache
  #   zpool add poolname cache /var/zfs_cache

  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
    zfs.extraPools = [ "tank" ];
    kernelParams = [ "zfs.zfs_arc_max=12884901888" ];
  };

  networking.hostId = "e768032f";

  services.zfs.autoScrub = {
    enable = true;
    interval = "Tue, 02:00";
  };
}
