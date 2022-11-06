{
  # This will add secrets.yml to the nix store
  # You can avoid this by adding a string to the full path instead, i.e.
  # sops.defaultSopsFile = "/root/.sops/secrets/example.yaml";
  sops.defaultSopsFile = ../../secrets2/secret.yaml;
  # This will automatically import SSH keys as age keys
  sops.age.sshKeyPaths = [ "/home/ryan/.ssh/id_ed25519.pub" ];
  # This is using an age key that is expected to already be in the filesystem
  #sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  # This will generate a new key if the key specified above does not exist
  #sops.age.generateKey = true;
  # This is the actual specification of the secrets.
  sops.secrets.example-key = {};
  sops.secrets."myservice/my_subdir/my_secret" = {};
}
