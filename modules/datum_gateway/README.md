# DATUM Gateway NixOS module

This [DATUM Gateway](https://github.com/OCEAN-xyz/datum_gateway) NixOS module can be used to configure one or two instances of DATUM Gateway.

## Quick Start

To use DATUM Gateway, you'll need to create a bitcoind RPC user. You can use the included `rpcauth` package to get the info you need:

```
$ nix run github:emmanuelrosa/btc-clients-nix#rpcauth datum_gateway
String to be appended to bitcoin.conf:
rpcauth=datum_gateway:a2172d636f97ddb46c020ec52701040d$e5e542bb6e0881b5ce4c39b51bf623b2e0788fac83cb66952ccff09d71cfa94e
Your password:
xFOVoBMy7y1FG8RdK5OrtcJh05C4yaoVijNqX0gOZmA

```

Save the RPC password in a text file at a secure location which can be accessed by the datum_gateway Linux user account, which by default is `datum_gateway`. It's worth noting that this user account doesn't exist yet. In this document, I use `/secrets/datum_gateway/bitcoind-password.txt` as an example, but [agenix](https://github.com/ryantm/agenix) and [sops](https://github.com/mic92/sops-nix) are great alternatives.

Next, create the user in your bitcoind configuration:

```
 services.bitcoind.mainnet = {
   enable = true;

   # Notice how the passwordHMAC is set to the same scribble from the rpcauth output.
   rpc.users.datum_gateway.passwordHMAC = "a2172d636f97ddb46c020ec52701040d$e5e542bb6e0881b5ce4c39b51bf623b2e0788fac83cb66952ccff09d71cfa94e";
 };
```

While you're at it, go ahead and prepare bitcoind for DATUM Gateway, as shown below:

```
 services.bitcoind.mainnet = {
   ...

   extraConfig = ''
     ...

     # This chunk of configuration only applies when datum_gateway is enabled.
     # blocknotify is needed so that bitcoind can signal to DATUM Gateway that there's a newly mined block.
     # The other options are recommendations specific to DATUM Gateway.
     ${lib.optionalString config.services.datum_gateway.enable ''
     blocknotify=${config.services.datum_gateway.blockNotifyCmd}
     blockmaxweight=3985000
     maxmempool=1000
     blockreconstructionextratxn=1000000
     blockreconstructionextratxnsize=100
     ''}
   '';
   
 };
```

Next, add this Nix flake to your NixOS configuration and add the `datum_gateway` module:

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
        btc-clients-nix.nixosModules.datum_gateway
        ./configuration.nix
      ];
    };
  };
};
```

Now you're ready to configure DATUM Gateway. First create a text file containing the password you want for the DATUM API/Dashboard; ex. `/secrets/datum_gateway/api-password.txt`. Like the RPC password file, this password file will also need to be accessible to the datum_gateway Linux account.

Then, configure the service as follows:

```
 ...
 services.datum_gateway = {
   enable = true;
   package = btc-clients-nix.packages.x86_64-linux.datum_gateway;

   # For pool mining, set to "pool".
   # For solo mining, set to "solo".
   # To mine both, set to "both". This will set up *two* instances of DATUM Gateway.
   instances = "pool";

   # This needs to match the bitcoind RPC username/password you set up earlier.
   bitcoind = {
     user = "datum_gateway";
     passwordFile = "/secrets/datum_gateway/bitcoind-password.txt";
   };

   api = {
     adminPasswordFile =  "/secrets/datum_gateway/api-password.txt";
   };

   mining = {
     poolAddress = "bc1...";
     soloMiningTag = "Boycot Shitcoin Magazine";
     poolMiningTag = "NixOS Bitcoin Miner";
   };

   # If your node has a public IP address, set this to `true` to make the stratum ports accessible for mining (with Braiins).
   # If your node is behind a NAT and you want to mine solo with a miner in your LAN, set this to `true`.
   # If your node is behind a NAT and you want to pool mine, set this to `false` and set up a TCP reverse proxy to tunnel the hashrate to your node. More on this coming soon.
   openFirewallPorts = true;
 };
```

There are more options in the `datum_gateway` NixOS module, but those above should take care of most cases.

Now you can `nixos-rebuild switch` to activate your configuration.

NOTE: When DATUM Gateway first starts up it may spam the systemd journal because bitcoind may not be ready.

Nevertheless, you can check the status of your DATUM Gateway instance(s) like this: `systemctl status datum_gateway*`.

Happy mining!

## DATUM Gateway Ports

This NixOS module configures up to two DATUM Gateway instances. The table below shows the ports configured for each instance:

| Instance | API/Dashboard port | Stratum port |
|----------|--------------------|--------------|
| **solo** | 7152               | 23334        | 
| **pool** | 7153               | 23335        |  

