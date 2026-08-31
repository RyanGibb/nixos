{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom;

  # dictd in inetd mode reports the peer as the literal string "inetd" rather
  # than resolving it, so an "allow 127.0.0.1" rule never matches. The socket
  # unit below is what actually restricts access to localhost.
  dictdb = pkgs.dictDBCollector {
    dictlist = map (x: {
      name = x.name;
      filename = x;
    }) (with pkgs.dictdDBs; [ wiktionary wordnet ]);
    allowList = [ "*" ];
  };
in
{
  options.custom.dict = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf cfg.dict {
    # Enabled for the dictd user/group and /etc/dict.conf; the always-on
    # daemon it defines is replaced by the socket activation below.
    services.dictd.enable = true;
    systemd.services.dictd.enable = lib.mkForce false;

    systemd.sockets.dictd = {
      description = "DICT.org Dictionary Server Socket";
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenStream = "127.0.0.1:2628";
        Accept = true;
      };
    };

    systemd.services."dictd@" = {
      description = "DICT.org Dictionary Server (per connection)";
      environment.LOCALE_ARCHIVE = "/run/current-system/sw/lib/locale/locale-archive";
      serviceConfig = {
        ExecStart = "${pkgs.dict}/sbin/dictd -i -c ${dictdb}/share/dictd/dictd.conf --locale en_US.UTF-8";
        StandardInput = "socket";
        StandardError = "journal";
        User = "dictd";
        Group = "dictd";
      };
    };

    environment.systemPackages = with pkgs; [ dict ];
  };
}
