{
  config,
  pkgs,
  lib,
  ...
}:

let
  python = pkgs.python3;

  music-tag = python.pkgs.buildPythonPackage rec {
    pname = "music-tag";
    version = "0.4.3";
    src = python.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "1xpzpk6qfmldrs8v0ajn0dz1nmklpn822bgc2r9hzpx8xmp6xaqa";
    };
    pyproject = true;
    build-system = with python.pkgs; [ setuptools ];
    propagatedBuildInputs = with python.pkgs; [ mutagen ];
    doCheck = false;
  };

  slskd-api = python.pkgs.buildPythonPackage rec {
    pname = "slskd-api";
    version = "0.1.5";
    src = python.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "1kr3i6dqnvzfn3qmslm964mv5s8qilnsjybffxi8br6ap7nqyr9f";
    };
    pyproject = true;
    build-system = with python.pkgs; [
      setuptools
      setuptools-git-versioning
    ];
    propagatedBuildInputs = with python.pkgs; [ requests ];
    doCheck = false;
  };

  soularr = pkgs.stdenv.mkDerivation {
    pname = "soularr";
    version = "0-unstable-2026-07-31";
    src = pkgs.fetchFromGitHub {
      owner = "mrusse";
      repo = "soularr";
      rev = "0700090ed1c539455b05af9e16ab1a5bf8b9baff";
      sha256 = "1m508siavcwc8dv6l0h4r13p2m9af14pjy6qgpzjchc127mj8611";
    };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontBuild = true;
    installPhase = ''
      install -Dm755 soularr.py $out/share/soularr/soularr.py
      makeWrapper ${python.withPackages (ps: [ ps.pyarr music-tag slskd-api ])}/bin/python3 \
        $out/bin/soularr --add-flags $out/share/soularr/soularr.py
    '';
  };

  downloadDir = "/tank/slskd";
in
{
  services.slskd = {
    enable = true;
    openFirewall = true;
    domain = null;
    # web api has no key: the generated yaml is world-readable in /nix/store,
    # so it is bound to loopback and left unauthenticated instead
    environmentFile = "/var/lib/slskd/secrets.env";
    settings = {
      shares.directories = [ "/tank/music" ];
      directories.downloads = "${downloadDir}/complete";
      directories.incomplete = "${downloadDir}/incomplete";
      web = {
        port = 5030;
        authentication.disabled = true;
      };
    };
  };

  # setgid + umask 002 so soularr (running as lidarr) can move completed
  # downloads out of directories slskd creates
  systemd.tmpfiles.rules = [
    "d ${downloadDir} 2775 slskd slskd -"
    "d ${downloadDir}/complete 2775 slskd slskd -"
    "d ${downloadDir}/incomplete 2775 slskd slskd -"
  ];
  systemd.services.slskd.serviceConfig.UMask = "0002";

  users.users.${config.services.lidarr.user}.extraGroups = [ "slskd" ];
  users.users.slskd.extraGroups = [ config.services.lidarr.group ];

  systemd.services.soularr = {
    description = "Search Soulseek for albums Lidarr is missing";
    after = [
      "slskd.service"
      "lidarr.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      User = config.services.lidarr.user;
      Group = config.services.lidarr.group;
      StateDirectory = "soularr";
      RuntimeDirectory = "soularr";
      WorkingDirectory = "/run/soularr";
      ExecStart = "${soularr}/bin/soularr";
    };
    preStart = ''
      lidarr_key=$(${lib.getExe pkgs.gnugrep} -oP '(?<=<ApiKey>)[^<]+' \
        ${config.services.lidarr.dataDir}/config.xml)
      cat > /run/soularr/config.ini <<EOF
      [Lidarr]
      api_key = $lidarr_key
      host_url = http://localhost:8686
      download_dir = ${downloadDir}/complete
      disable_sync = False

      [Slskd]
      api_key = unauthenticated
      host_url = http://localhost:5030
      url_base = /
      download_dir = ${downloadDir}/complete
      delete_searches = False
      stalled_timeout = 3600
      remote_queue_timeout = 120

      [Release Settings]
      use_most_common_tracknum = True
      allow_multi_disc = True
      skip_region_check = True
      accepted_formats = CD,Digital Media,Vinyl,Web

      [Search Settings]
      search_timeout = 15000
      maximum_peer_queue = 50
      minimum_peer_upload_speed = 0
      minimum_filename_match_ratio = 0.7
      allowed_filetypes = flac,mp3 320,mp3
      album_prepend_artist = True
      number_of_albums_to_grab = 30
      search_source = missing
      failed_import_denylist = True

      [Download Settings]
      download_filtering = True
      rename_download_folders = True

      [Logging]
      level = INFO
      EOF
    '';
  };

  systemd.timers.soularr = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      RandomizedDelaySec = "10m";
      Persistent = true;
    };
  };
}
