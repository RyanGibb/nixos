{ config, lib, pkgs, ... }:

let
  cfg = config.custom.gui;
in
{
  options.custom.gui.kde = lib.mkEnableOption "kde";

  config = lib.mkIf cfg.kde {
    services.desktopManager.plasma6.enable = true;
    services.displayManager.ly.enable = true;
    services.displayManager.defaultSession = lib.mkDefault null;

    # screen reader
    services.orca.enable = false;

    # Fix audio delay by disabling node suspension
    services.pipewire.wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/disable-suspension.conf" ''
        monitor.alsa.rules = [
          {
            matches = [
              {
                # Matches all sources
                node.name = "~alsa_input.*"
              },
              {
                # Matches all sinks
                node.name = "~alsa_output.*"
              }
            ]
            actions = {
              update-props = {
                session.suspend-timeout-seconds = 0
              }
            }
          }
        ]
        # bluetooth devices
        monitor.bluez.rules = [
          {
            matches = [
              {
                # Matches all sources
                node.name = "~bluez_input.*"
              },
              {
                # Matches all sinks
                node.name = "~bluez_output.*"
              }
            ]
            actions = {
              update-props = {
                session.suspend-timeout-seconds = 0
              }
            }
          }
        ]
      '')
    ];
  };
}
