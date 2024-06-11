let
  user = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAGNcdBuEeoJiMH8TMO4k/w3OVKfiSZ9IZ3xrzFOZEi8 ryan@dell-xps"
  ];

  gecko =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGLEtqkSlJx219h1aYRXRjP60vBmJmhrCp0Mj1FIF25N root@gecko";
  owl =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILP6Cgm/BWnJvuGgU1SjWwjOCjuE5AXGqEdQonWYR7BA root@owl";
  elephant =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL+ddohsRFrypCVJqIhI3p3R12pJI8iwuMfRu0TJWuPe root@elephant";
  shrew =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHLiZ0xdXSlF1eMibrs320lVQaushEpEDMrR6lp9uFkx root@shrew";
in {
  "cache-priv-key.pem.age".publicKeys = user ++ [ elephant ];
  "email-ryan.age".publicKeys = user ++ [ gecko owl ];
  "email-system.age".publicKeys = user ++ [ gecko owl elephant ];
  "matrix-shared-secret.age".publicKeys = user ++ [ owl ];
  "matrix-turn-shared-secret.age".publicKeys = user ++ [ owl ];
  "coturn.age".publicKeys = user ++ [ owl ];
  "website-phd.age".publicKeys = user ++ [ owl ];
  "rmfakecloud.age".publicKeys = user ++ [ owl ];
  "restic-owl.age".publicKeys = user ++ [ owl elephant ];
  "restic-gecko.age".publicKeys = user ++ [ gecko elephant ];
  "restic-elephant.age".publicKeys = user ++ [ elephant ];
  "restic.env.age".publicKeys = user ++ [ elephant ];
  "restic-repo.age".publicKeys = user ++ [ elephant ];
  "nextcloud.age".publicKeys = user ++ [ elephant ];
  "headscale.age".publicKeys = user ++ [ owl ];
  "eon-capnp.age".publicKeys = user ++ [ owl ];
  "eon-vpn.freumh.org.cap.age".publicKeys = user ++ [ elephant ];
  "eon-sirref-primary.cap.age".publicKeys = user ++ [ owl ];
}
