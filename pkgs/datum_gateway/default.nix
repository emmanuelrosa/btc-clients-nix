{ lib
, stdenv
, fetchgit
, cmake
, pkg-config
, git
, curl
, jansson
, libmicrohttpd
, gnutls
, libtasn1
, p11-kit
, libsodium
}: stdenv.mkDerivation rec {
  pname = "datum_gateway";
  version = "0.4.1beta";

  src = fetchgit {
    url = "https://github.com/OCEAN-xyz/datum_gateway.git";
    rev = "v${version}";
    hash = "sha256-U+SVvZW5fxOVSbAIa0iB65rBeN/c2I8D/GiXqbFtH9w=";
    leaveDotGit = true; # Allows the git commit hash to be added to the built executable.
  };

  nativeBuildInputs = [ cmake
                        pkg-config
                        git
                        curl
                        jansson
                        libmicrohttpd
                        gnutls
                        libtasn1
                        p11-kit
                        libsodium ];

  installPhase = ''
    mkdir -p $out/{bin,share/doc}

    cp ./datum_gateway $out/bin/
    cp -r ${src}/doc/. $out/share/doc/
  '';

  meta = {
    description = "The DATUM Gateway implements lightweight efficient client side decentralized block template creation for true solo mining.";
    homepage = "https://github.com/OCEAN-xyz/datum_gateway";
    mainProgram = "datum_gateway";
    license = lib.licenses.mit; # I think the license is MIT.
    maintainers = with lib.maintainers; [ emmanuelrosa ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
