# playit.gg NixOS Module

Although designed for gaming servers, with the playit.gg you can create a static and public raw TCP ports for your DATUM Gateway instances. You can then point hashrate from a provider such as Brains to the public IP/ports to mine Bitcoin from the comfort of your man cave.

Beware that to use TCP ports on playit.gg you need to pay for a [premium](https://playit.gg/pricing) account.

## Quick Start

To begin, add this Nix flake to your NixOS configuration and add the `playit` module:

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
        btc-clients-nix.nixosModules.playit
        ./configuration.nix
      ];
    };
  };
};
```

Luckily the playit module is super easy to configure. Here's how it's done:

 ```
 services.playit = {
   enable = true;
   package = btc-clients-nix.packages.x86_64-linux.playit;
 };
```

Playit consists of a background daemon and a client cli application. They both communicate via a UNIX domain socket, which by default is located at `/var/lib/playit/playit.socket`. This file is owned by the `playit` Linux user account so the client app cannot access the socket by default.

Choose how you want to execute the client app:

- Add your Linux user account to the `playit` group. A good option if you intend to run the client app often, though you probably don't need to do so.
- Use `run0 -d playit playit` to run the client. This will require that you enter your root password, but the client is executed under the `playit` user account.


If you decide to add your account to the `playit` group, you can do so like this:

```
users.users.<your linux account> = {
  ...
  group = "users";

  extraGroups = [
    ...
    "playit"
  ];
};
```

Now you can `nixos-rebuild switch` to activate your configuration.

Now that `playit` is set up, you'll need to create an account and link it to the `playit` instance that's running on your computer:

- Create an account at [playit.gg](https://playit.gg/) using your email.
- You'll be sent an email verification code. Use that to verify your email address.
- Now you'll need to link your "agent" to your account. Run the `playit` cli app to the the "claim URL".
- Open the claim URL in your web browser and setup your "agent".

Next, use the playit website to create a **TCP** tunnel, where the local port number is the same as your DATUM Gateway stratum port number. Refer to the [DATUM Gateway](../datum_gateway) module documentation to.
