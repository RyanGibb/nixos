# man 5 configuration.nix

{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./packages.nix
    ./programs.nix
    ./secret.nix
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

  environment = {
    variables.EDITOR = "nvim";
    shellAliases = {
      ls = "ls -p --color=auto";
      pls = "sudo $(fc -ln -1)";
      o = "xdg-open";
      se = "sudoedit";
      su = "su -p";
      ssh = "TERM=xterm ssh";
      nix-shell = "nix-shell --command zsh";
      inhibit-lid = "systemd-inhibit --what=handle-lid-switch sleep 1d";
    };
  };

  programs.mosh.enable = true;
  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
  };
  services.tailscale.enable = true;

  networking = {
    nameservers = [ "1.1.1.1" ];
    extraHosts = ''
      100.122.46.94  pixel-4a
      100.92.111.117 dell-xps
      100.91.12.120  hp-pavilion
      100.125.253.71 vps
      100.93.8.35    desktop
    '';
  };

  programs.ssh = {
    extraConfig = ''
      Host pixel-4a*
      	User u0_a342
      	Port 8022
      
      Host slogin
      	User rtg24
      	Hostname slogin-serv.cl.cam.ac.uk
      
      Host l41
      	User root
      	Hostname rpi4-013.advopsys.cl.cam.ac.uk
      	IdentityFile ~/.ssh/id_rsa_rpi4-013.advopsys.cl.cam.ac.uk
      	ProxyJump rtg24@slogin-serv.cl.cam.ac.uk
      	ForwardAgent yes
    '';
  };

  system.stateVersion = "21.11";
}
