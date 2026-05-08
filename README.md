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
- **bitcoin-tui** - [bitcoin-tui](https://github.com/janb84/bitcoin-tui) is a terminal UI for Bitcoin Core/Knots nodes.
- **rpcauth** - [rpcauth](https://github.com/bitcoinknots/bitcoin/blob/a9aee730466ac67d35a3c03ee24676be5e045878/share/rpcauth/rpcauth.py) is a utility provided by Bitcoin Core (and derivatives such as Bitcoin Knots) which is used to generate username/password pairs for bitcoind RPC authentication. This package obtains rpcauth from Bitcoin Knots.
- **datum_gateway** - [DATUM Gateway](https://github.com/OCEAN-xyz/datum_gateway) implements lightweight efficient client side decentralized block template creation for solo or pool mining.

### Maintenance packages

These packages are used to help me maintain this repository:

- **sparrow-get-source-hashes** - A BASH script for me to get the SHA256 hashes for a specific version of Sparrow wallet.
- **update-checker** - A BASH script for me to quickly check GitHub for updates to the above packages. 
- **bisq2.webcam-app** - Launches the [Bisq 2](https://github.com/bisq-network/bisq2) webcam app, to test QR code scanning.

## Other packages

- **Bitcoin Knots BIP-110 Activation Client** - A package for this UASF client is available in another repo (I'm assuming it will eventually be merged into Bitcoin Knots). See [https://github.com/emmanuelrosa/bitcoin-knots-bip-110-nix](https://github.com/emmanuelrosa/bitcoin-knots-bip-110-nix).
