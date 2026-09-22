{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom;

  # Petting is deliberately gated on a real read reaching the disk. A watchdog
  # petted from RAM (as systemd's RuntimeWatchdogSec is, by PID 1) sails
  # straight through a storage failure without noticing.
  petter = pkgs.writeCBin "disk-watchdog" ''
    #define _GNU_SOURCE
    #include <errno.h>
    #include <fcntl.h>
    #include <linux/watchdog.h>
    #include <signal.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <sys/ioctl.h>
    #include <unistd.h>

    #define BLK 4096

    static int wd = -1;

    /* Magic close: without writing 'V' the driver keeps counting after we exit,
       so a clean stop or a unit restart during deploy would reboot the box. */
    static void disarm(int sig) {
      (void)sig;
      if (wd >= 0) {
        if (write(wd, "V", 1) != 1) {
          /* nothing useful left to do; the reset is the fallback */
        }
        close(wd);
      }
      _exit(0);
    }

    int main(int argc, char **argv) {
      if (argc != 5) {
        fprintf(stderr, "usage: %s <watchdog-dev> <probe-dev> <timeout-s> <interval-s>\n", argv[0]);
        return 2;
      }
      const char *wdev = argv[1], *pdev = argv[2];
      int timeout = atoi(argv[3]), interval = atoi(argv[4]);

      int probe = open(pdev, O_RDONLY | O_DIRECT);
      if (probe < 0) {
        fprintf(stderr, "disk-watchdog: open %s: %s\n", pdev, strerror(errno));
        return 1;
      }

      void *buf = NULL;
      if (posix_memalign(&buf, BLK, BLK) != 0) {
        fprintf(stderr, "disk-watchdog: posix_memalign failed\n");
        return 1;
      }

      wd = open(wdev, O_WRONLY);
      if (wd < 0) {
        fprintf(stderr, "disk-watchdog: open %s: %s\n", wdev, strerror(errno));
        return 1;
      }

      signal(SIGTERM, disarm);
      signal(SIGINT, disarm);

      if (ioctl(wd, WDIOC_SETTIMEOUT, &timeout) < 0) {
        fprintf(stderr, "disk-watchdog: set timeout: %s\n", strerror(errno));
        disarm(0);
      }
      int actual = 0;
      if (ioctl(wd, WDIOC_GETTIMEOUT, &actual) < 0)
        actual = timeout;

      /* Log which driver we actually got: the chipset TCO timer on this Dell
         accepted every ioctl and then never reset the box. */
      struct watchdog_info info;
      const char *ident = "unknown";
      if (ioctl(wd, WDIOC_GETSUPPORT, &info) == 0)
        ident = (const char *)info.identity;

      fprintf(stderr,
              "disk-watchdog: armed on %s [%s], hardware timeout %ds, probing %s every %ds\n",
              wdev, ident, actual, pdev, interval);
      fflush(stderr);

      unsigned long long n = 0;
      for (;;) {
        /* A probe that blocks in D state never returns, so we simply stop
           petting and the chipset resets us. That is the intended path. */
        ssize_t got = pread(probe, buf, BLK, (off_t)((n % 256) * BLK));
        if (got == BLK) {
          if (write(wd, "\0", 1) != 1)
            fprintf(stderr, "disk-watchdog: pet failed: %s\n", strerror(errno));
        } else {
          fprintf(stderr, "disk-watchdog: probe read of %s failed (%s); withholding pet\n",
                  pdev, got < 0 ? strerror(errno) : "short read");
          fflush(stderr);
        }
        n++;
        sleep(interval);
      }
    }
  '';
in
{
  options.custom.disk-watchdog = {
    enable = lib.mkEnableOption "hardware watchdog gated on disk reachability";

    device = lib.mkOption {
      type = lib.types.str;
      example = "/dev/sda2";
      description = "Block device to probe. Use the raw partition backing /, not a path on it.";
    };

    # ipmi_watchdog is an old-style misc driver: it creates /dev/watchdog and no
    # /sys/class/watchdog entry, unlike framework drivers such as sp5100_tco.
    watchdog = lib.mkOption {
      type = lib.types.str;
      default = if cfg.disk-watchdog.ipmi.enable then "/dev/watchdog" else "/dev/watchdog0";
      defaultText = lib.literalExpression ''"/dev/watchdog" when ipmi.enable, else "/dev/watchdog0"'';
    };

    # The hardware timeout is the tolerance window: interval 30s against a 600s
    # timeout means ~20 consecutive failed probes before a reset, so transient
    # I/O stalls under build load cannot trip it.
    timeout = lib.mkOption {
      type = lib.types.int;
      default = 600;
    };

    interval = lib.mkOption {
      type = lib.types.int;
      default = 30;
    };

    # The chipset TCO timer is present on PowerEdge hardware but inert: it
    # accepted every ioctl and then failed to reset the box after 9 h unpetted.
    # The BMC timer works in-band over /dev/ipmi0 and needs no iDRAC address.
    ipmi = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use the BMC watchdog rather than the chipset TCO timer.";
      };

      # A warm reset does not clear a wedged PERC: recovery has twice required
      # a full power cycle, which only the BMC can perform.
      action = lib.mkOption {
        type = lib.types.enum [
          "power_cycle"
          "reset"
          "power_off"
          "none"
        ];
        default = "power_cycle";
      };
    };
  };

  config = lib.mkIf cfg.disk-watchdog.enable {
    # NB do not also enable systemd's own RuntimeWatchdogSec: only one process
    # may hold the watchdog device, and systemd would win the race on boot.
    assertions = [
      {
        assertion = cfg.disk-watchdog.timeout > cfg.disk-watchdog.interval * 2;
        message = "custom.disk-watchdog.timeout must be well above interval, or a single slow read reboots the machine.";
      }
    ];

    # Blacklisting the chipset timer leaves ipmi_watchdog as the only provider,
    # so it deterministically becomes watchdog0.
    boot.blacklistedKernelModules = lib.mkIf cfg.disk-watchdog.ipmi.enable [ "sp5100_tco" ];
    boot.kernelModules = lib.mkIf cfg.disk-watchdog.ipmi.enable [ "ipmi_watchdog" ];
    boot.extraModprobeConfig = lib.mkIf cfg.disk-watchdog.ipmi.enable ''
      options ipmi_watchdog action=${cfg.disk-watchdog.ipmi.action} timeout=${toString cfg.disk-watchdog.timeout} nowayout=0
    '';

    systemd.services.disk-watchdog = {
      description = "Hardware watchdog gated on disk reachability";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];
      serviceConfig = {
        ExecStart = "${petter}/bin/disk-watchdog ${cfg.disk-watchdog.watchdog} ${cfg.disk-watchdog.device} ${toString cfg.disk-watchdog.timeout} ${toString cfg.disk-watchdog.interval}";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
