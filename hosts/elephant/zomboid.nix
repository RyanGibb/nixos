{
  config,
  lib,
  pkgs,
  ...
}:

let
  # builtins.fetchTarball rather than fetchFromGitHub: these are imported for
  # their Nix files, and a derivation would make that import-from-derivation.
  # Pinned by rev because the game depots are fixed-output against a Steam
  # manifest id and Steam stops serving superseded manifests.
  nixzoid = builtins.fetchTarball {
    url = "https://github.com/hcbt/nixzoid/archive/c221f01c76b21b6031289a070bcd15aa3a724d65.tar.gz";
    sha256 = "0xq4yn5scb7glvm7qlb0bxbl72345z16ykih9s2ks7ldsys8mgjn";
  };
  coldstart = builtins.fetchTarball {
    url = "https://github.com/hcbt/coldstart/archive/0c650a794ecc82792a42b827e641ce914c6e1cef.tar.gz";
    sha256 = "0p3r7rlb62an9wfrr1j6gx8c85kr4pa75hf3r1lisqpj8nd4ql00";
  };
  steamFetcher = builtins.fetchTarball {
    url = "https://github.com/nix-community/steam-fetcher/archive/ab5e3a0828b4b179feb548c57be584ce812956a8.tar.gz";
    sha256 = "0x7i5c46lj3g5kbflvlg3na50aia31p1wqr20xm3s203hik1j585";
  };

  # Pinned so the host-side secret can be chowned to the account that reads it
  # inside the container. NixOS allocates system uids descending from 999, so a
  # low one stays clear of anything elephant picks up later.
  uid = 901;

  zcfg = config.services.zomboid;
  # Same list the module opens in the firewall: the game port plus one per
  # concurrent direct connection.
  ports = [ zcfg.port ] ++ lib.genList (i: zcfg.port + 1 + i) zcfg.directConnectPorts;

  natpmpLifetime = 3600;
in
{
  imports = [
    (import "${nixzoid}/nix/nixos-module.nix" {
      overlay = import "${nixzoid}/nix/overlay.nix";
      steam-fetcher.overlay = import "${steamFetcher}/default.nix";
      inherit coldstart;
    })
  ];

  # nixzoid c221f01 pins the shared depot at manifest 2587362105419356756, which
  # Steam has since retired -- anonymous fetches of it now 401. Only 380871
  # rotated; the Linux half is still current, so just that one source is
  # replaced. mkAfter to land after the overlay the imported module installs.
  nixpkgs.overlays = lib.mkAfter [
    (final: prev: {
      zomboid-server-unwrapped = prev.zomboid-server-unwrapped.overrideAttrs (old: {
        srcs = [
          (final.fetchSteam {
            name = "zomboid-server-common";
            appId = "380870";
            depotId = "380871";
            manifestId = "8198713088050651526";
            hash = "sha256-LJsa00nt5IDip94AyI9p6zAb8tGrVFIAZ00jAn+c33g=";
          })
          (builtins.elemAt old.srcs 1)
        ];
      });
    })
  ];

  # Real files at fixed paths rather than the default /run/agenix symlinks,
  # whose target generation changes on every activation and would strand the
  # container's bind mounts.
  age.secrets.zomboid-admin = {
    file = ../../secrets/zomboid-admin.age;
    symlink = false;
    path = "/var/lib/zomboid-secret/admin-password";
    owner = toString uid;
    group = toString uid;
    mode = "0400";
  };

  # Holds `Password=`. Kept out of `settings`, which is rendered into the
  # world-readable Nix store.
  age.secrets.zomboid-config = {
    file = ../../secrets/zomboid-config.age;
    symlink = false;
    path = "/var/lib/zomboid-secret/config";
    owner = toString uid;
    group = toString uid;
    mode = "0400";
  };

  # The router does NAT-PMP but not UPnP IGD, and leases expire, so the mappings
  # are renewed on a timer at half their lifetime rather than set up once.
  systemd.services.zomboid-natpmp = {
    description = "Renew NAT-PMP forwards for the Project Zomboid server";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "zomboid-natpmp" ''
        set -u
        rc=0
        for p in ${toString ports}; do
          ${pkgs.libnatpmp}/bin/natpmpc -a "$p" "$p" udp ${toString natpmpLifetime} || rc=1
        done
        exit "$rc"
      '';
    };
  };

  systemd.timers.zomboid-natpmp = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "${toString (natpmpLifetime / 2)}s";
      Unit = "zomboid-natpmp.service";
    };
  };

  coldstart.containers.zomboid.extraConfig = {
    users.users.zomboid.uid = uid;
    users.groups.zomboid.gid = uid;
  };

  services.zomboid = {
    enable = true;
    serverName = "knox";
    # Upstream defaults to 8g, which does not fit beside jellyfin, immich and
    # garage on a 16G box.
    package = pkgs.zomboid-server.override { heapSize = "3g"; };
    stateDir = "/var/lib/zomboid";
    adminPasswordFile = config.age.secrets.zomboid-admin.path;
    secretConfigFile = config.age.secrets.zomboid-config.path;

    # Reachable from off the tailnet. This only opens elephant's own firewall --
    # the router at 192.168.1.254 still has to forward these UDP ports here.
    openFirewall = true;
    directConnectPorts = 8;
  };
}
