{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Not in nixpkgs; packaged here. It's plain python, so this is just a wrapper
  # around main.py with the runtime deps on PYTHONPATH (approach borrowed from
  # xddxdd's NUR package).
  decluttarr = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "decluttarr";
    version = "2.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "ManiMatter";
      repo = "decluttarr";
      rev = "v${finalAttrs.version}";
      hash = "sha256-pOuAQ2KKvhmUM6xX5iX9s33ZXL3OLx6yIOL8LZF1W64=";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase =
      let
        # Taken from the actual imports in main.py/src, not docker/requirements.txt
        # (which lists dev tooling and omits `packaging`) — demjson3 and
        # verboselogs are listed there but unused in 2.1.0.
        py = pkgs.python3.withPackages (
          p: with p; [
            requests
            python-dateutil
            packaging
            pyyaml
            pyyaml-env-tag
            watchdog
          ]
        );
      in
      ''
        runHook preInstall
        mkdir -p $out/{bin,share/decluttarr}
        cp -r . $out/share/decluttarr
        makeWrapper ${lib.getExe py} $out/bin/decluttarr \
          --add-flags $out/share/decluttarr/main.py
        runHook postInstall
      '';

    meta = {
      description = "Watches *arr download queues and removes stalled/failed downloads";
      homepage = "https://github.com/ManiMatter/decluttarr";
      license = lib.licenses.gpl3Only;
      mainProgram = "decluttarr";
    };
  });

  # API keys are read from each app's config.xml at runtime by the preStart
  # below, so they never enter the nix store. Everything else is static.
  settings = {
    general = {
      log_level = "INFO";
      # Set true to dry-run: it then only logs what it *would* remove.
      test_run = false;
      timer = 10;
      public_tracker_handling = "remove";
      private_tracker_handling = "remove";
    };
    job_defaults = {
      max_strikes = 3;
      min_days_between_searches = 7;
      max_concurrent_searches = 3;
    };
    jobs = {
      # blocklists the release and re-searches, so a bad grab isn't retried
      remove_failed_imports = {
        message_patterns = [
          "*Found potentially dangerous file with extension*"
          "*Found executable file with extension*"
          "Not an upgrade for existing*"
          "Not a Custom Format upgrade for existing*"
          "Invalid video file*"
          # duplicate grabs of something already in the library; these
          # otherwise sit in the queue indefinitely (glob covers sonarr's
          # "Episode file already imported at ..." and radarr's "Movie ...")
          "*file already imported*"
          "No files found are eligible for import*"
          "One or more episodes expected in this release were not imported or missing from the release"
        ];
      };
      remove_failed_downloads = { };
      remove_stalled = { };
      remove_metadata_missing = { };
      remove_orphans = { };
      remove_bad_files = { };
    };
    instances = {
      sonarr = [
        {
          base_url = "http://localhost:8989";
          api_key = "@SONARR_KEY@";
        }
      ];
      radarr = [
        {
          base_url = "http://localhost:7878";
          api_key = "@RADARR_KEY@";
        }
      ];
      lidarr = [
        {
          base_url = "http://localhost:8686";
          api_key = "@LIDARR_KEY@";
        }
      ];
    };
  };

  configTemplate = (pkgs.formats.yaml { }).generate "decluttarr-config.yaml" settings;
in
{
  systemd.services.decluttarr = {
    description = "Clean stalled and failed downloads out of the *arr queues";
    after = [
      "network.target"
      "sonarr.service"
      "radarr.service"
      "lidarr.service"
    ];
    wantedBy = [ "multi-user.target" ];

    # Substitute the API keys in from each app's config.xml at runtime. The
    # rendered config lives in RuntimeDirectory (tmpfs, 0700), never the store.
    #
    # decluttarr has no --config flag: the path is hardcoded to the *relative*
    # "./config/config.yaml" (and "./logs/logs.txt"), so it only works with
    # WorkingDirectory set and the file in a config/ subdirectory.
    preStart = ''
      umask 077
      mkdir -p /run/decluttarr/config /run/decluttarr/logs
      cp ${configTemplate} /run/decluttarr/config/config.yaml
      ${lib.concatMapStringsSep "\n" (a: ''
        key=$(${pkgs.gnused}/bin/sed -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p' ${a.cfg})
        ${pkgs.gnused}/bin/sed -i "s|@${a.name}_KEY@|$key|" /run/decluttarr/config/config.yaml
      '') [
        {
          name = "SONARR";
          cfg = "/var/lib/sonarr/.config/NzbDrone/config.xml";
        }
        {
          name = "RADARR";
          cfg = "/var/lib/radarr/.config/Radarr/config.xml";
        }
        {
          name = "LIDARR";
          cfg = "/var/lib/lidarr/.config/Lidarr/config.xml";
        }
      ]}
    '';

    serviceConfig = {
      Type = "simple";
      # needs root to read the *arr config.xml files (each is 0600 and owned by
      # its own service user)
      User = "root";
      RuntimeDirectory = "decluttarr";
      RuntimeDirectoryMode = "0700";
      WorkingDirectory = "/run/decluttarr";
      ExecStart = lib.getExe decluttarr;
      Restart = "on-failure";
      RestartSec = "30s";
    };
  };
}
