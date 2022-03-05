# man 5 configuration.nix

{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./packages.nix
    ./secret.nix
    <home-manager/nixos> 
  ];

  boot.loader.grub = {
    enable = true;
    version = 2;
  };

  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  }; 

  users.mutableUsers = false;
  users.users.ryan = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # enable sudo
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = [
      /etc/nixos/authorized_keys
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    users.ryan = import ./home.nix;
  };

  environment = {
    variables.EDITOR = "nvim";
    shellAliases = {
      ls = "ls -p --color=auto";
      pls = "sudo $(fc -ln -1)";
      o = "xdg-open";
      se = "sudoedit";
      su = "su -p";
      ssh = "TERM=xterm ssh";
    };
  };

  programs.mosh.enable = true;
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "no";
  services.openssh.passwordAuthentication = false;

  system.stateVersion = "21.11";
}

