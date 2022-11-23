{ lib }:

{
  imports = [ ./options.nix ];
  
  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_GB.UTF-8";

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 90d";
    };
  };
}