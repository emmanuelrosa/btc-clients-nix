# HashGG NixOS module

With this HashGG NixOS module you can install HashGG on NixOS with ease!

## Differences from upstream's HashGG

HashGG is designed to run within a Docker container, which is currently built from Debian 12. While it's possible to run such a container on NixOS, I opted to use a [bubblewrap](https://github.com/containers/bubblewrap) container built from Nixpkgs instead. This provides up-to-date dependencies (thanks to Nixpkgs) and a much lighter build and runtime footprint.

Another difference from upstream is that by default the HashGG web UI listens on 127.0.0.1 rather than 0.0.0.0.

## Setup

Before you can use this HashGG NixOS module, you need to configure the [DATUM Gateway](../datum_gateway) NixOS module.

After configuring DATUM Gateway, add the `hashgg` module:

```
{
  ...
  inputs.btc-clients-nix.url = "github:emmanuelrosa/btc-clients-nix";

  outputs = { self, nixpkgs, btc-clients-nix, }@attrs: {
    nixosConfigurations.nixos-laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [ 
        ...
        btc-clients-nix.nixosModules.hashgg
        ./configuration.nix
      ];
    };
  };
};
```

Then, enable the hashgg service
```
 services.hashgg = {
   enable = true;
   package = btc-clients-nix.packages.x86_64-linux.hashgg;
 };
```

That's it!

Note that by default HashGG is configured to listen on 127.0.0.1 and ports 3000 and 3001. But you can change this if needed.

Now you can go to [http://127.0.0.1:3000](http://127.0.0.1:3000) to configure HashGG for solo mining, or [http://127.0.0.1:3001](http://127.0.0.1:3001) to configure HashGG for pool mining.

## HashGG data and Ports

This NixOS module configures up to two HashGG instances; One per DATUM Gateway instance. The table below shows the default data directories and ports configured for each instance:

| Instance | Web UI port | stratum port | Data directory               |
|----------|-------------|--------------|------------------------------|
| **solo** | 3000        | 23334        | /var/lib/hashgg/mainnet/solo | 
| **pool** | 3001        | 23335        | /var/lib/hashgg/mainnet/pool |

**TIP:** You can access the Web UI from your desktop's application menu.
