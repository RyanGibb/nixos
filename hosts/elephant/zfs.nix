{ pkgs, config, ... }:

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

  age.secrets.email-elephant.file = ../../secrets/email-system.age;
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      aliases = "/etc/aliases";
      port = 465;
      tls_trust_file = "/etc/ssl/certs/ca-certificates.crt";
      tls = "on";
      auth = "login";
      tls_starttls = "off";
    };
    accounts = {
      default = {
        host = "mail.${config.networking.domain}";
        passwordeval = "cat ${config.age.secrets.email-elephant.path}";
        user = "system@${config.networking.domain}";
        from = "nas@${config.networking.domain}";
      };
    };
  };

  services.zfs.zed.settings = {
    ZED_DEBUG_LOG = "/tmp/zed.debug.log";
    ZED_EMAIL_ADDR = [ "root" ];
    ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
    ZED_EMAIL_OPTS = "@ADDRESS@";

    ZED_NOTIFY_INTERVAL_SECS = 3600;
    ZED_NOTIFY_VERBOSE = true;

    ZED_USE_ENCLOSURE_LEDS = true;
    ZED_SCRUB_AFTER_RESILVER = true;
  };
  # this option does not work; will return error
  services.zfs.zed.enableMail = false;
}
