# btc-clients-nix

This repository is a Nix flake containing NixOS packages for Bitcoin end-user software.

## Overview

The objective of this Nix flake is to deliver a small package set of the most important Bitcoin client software; Essentially, Bitcoin wallets.

It's important for the package set to remain as small and simple as possible so that it can easily be audited by end-users, and maintained; The simplicity being the most challenging part :)

## Packages

The following packages are included in this Nix flake:

- **bisq** - [Bisq](https://github.com/bisq-network) (aka. Bisq v1) is a decentralized bitcoin exchange network.
- **bisq-desktop** - An alias for the **bisq** package.
- **bisq2** - [Bisq 2](https://github.com/bisq-network/bisq2) will be the successor to Bisq v1 and will support multiple trade protocols, multiple privacy networks and multiple identities.
- **sparrow** - [Sparrow](https://github.com/sparrowwallet) is a desktop Bitcoin wallet focused on security and privacy.
- **update-checker** - A BASH script for me to quickly check GitHub for updates to the above packages. 
- **bisq2.webcam-app** - Launches the [Bisq 2](https://github.com/bisq-network/bisq2) webcam app, to test QR code scanning. Intended for package maintainers. 
