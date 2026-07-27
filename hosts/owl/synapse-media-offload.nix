{
  config,
  pkgs,
  lib,
  ...
}:

let
  plugin = pkgs.matrix-synapse-plugins.matrix-synapse-s3-storage-provider;
  py = pkgs.python3.withPackages (p: [ p.boto3 ]);
in
{
  systemd.services.synapse-media-offload = {
    description = "Offload cold synapse media to garage S3";
    after = [
      "network-online.target"
      "matrix-synapse.service"
    ];
    wants = [ "network-online.target" ];
    path = [ pkgs.systemd ];

    environment = {
      S3_MEDIA_UPLOAD = "${plugin}/bin/s3_media_upload";
      OFFLOAD_AGE = "90d";
    };

    serviceConfig = {
      Type = "oneshot";
      User = config.systemd.services.matrix-synapse.serviceConfig.User;
      Group = config.systemd.services.matrix-synapse.serviceConfig.Group;
      StateDirectory = "synapse-media-offload";
      ExecStart = "${py}/bin/python3 ${./synapse-media-offload.py}";
      # long-running and IO heavy; don't let it fight synapse for the disk
      IOSchedulingClass = "idle";
      Nice = 10;
    };
  };

  systemd.timers.synapse-media-offload = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 04:00";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };
}
