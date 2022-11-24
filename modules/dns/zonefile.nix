{ pkgs, lib, config, ... }:

let cfg = config.dns; in pkgs.writeTextFile {
  name = "zonefile";
  text = ''
    $ORIGIN ${cfg.domain}.
    $TTL ${cfg.ttl}
    @ IN SOA ${cfg.soa.ns} ${cfg.soa.email} (
      ${cfg.soa.serial}
      ${cfg.soa.refresh}
      ${cfg.soa.retry}
      ${cfg.soa.expire}
      ${cfg.soa.negativeCacheTtl}
    )
    ${
      lib.strings.concatStringsSep "\n"
        (builtins.map (rr: "${rr.name} IN ${builtins.toString rr.ttl} ${rr.type} ${rr.data}") cfg.records)
    }
  '';
}
