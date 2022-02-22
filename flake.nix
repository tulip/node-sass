{
  description = "Libsass";

  outputs = { self, nixpkgs }:
    let
      node-sass-env = { system }:
        nixpkgs.legacyPackages.${system}.callPackage ./node-env.nix {
          pkgs = nixpkgs.legacyPackages.${system};
          nodejs  = nixpkgs.legacyPackages.${system}.nodejs-12_x;
          libtool = if ( ( system == "aarch64-darwin" ) ||
                         ( system == "x86_64-darwin" ) )
                      then nixpkgs.legacyPackages.${system}.darwin.cctools
                      else null;
        };

      nodePackages =
        { system
        , stdenv
        , lib
        , libsass
        , pkg-config
        , python3
        , fetchurl
        , fetchgit
        , nix-gitignore
        }@args:
          let
            nodeEnv = node-sass-env { inherit system; };
            globalBuildInputs = [pkg-config libsass python3];
            filteredArgs =
              builtins.removeAttrs args [
                "system" "libsass" "pkg-config" "python3"
              ];
            newArgs = filteredArgs // { inherit globalBuildInputs nodeEnv; };
          in import ./node-packages.nix newArgs;

      node-sass-packages = { system, libsass }:
        nixpkgs.legacyPackages.${system}.callPackage nodePackages {
          inherit libsass system;
        };
          
    in {
      # Packages
      packages.aarch64-darwin.libsass =
        nixpkgs.legacyPackages.aarch64-darwin.callPackage
          ./src/libsass/default.nix { src = ./src/libsass/.; };

      packages.aarch64-darwin.node-sass =
        let
          nodeDependencies = ( node-sass-packages {
            system  = "aarch64-darwin";
            libsass = self.packages.aarch64-darwin.libsass;
          } ).shell.nodeDependencies;
        in nixpkgs.legacyPackages.aarch64-darwin.stdenv.mkDerivation {
          pname = "node-sass";
          version = "7.0.1";
          src = ./.;
          buildInputs = [nixpkgs.legacyPackages.aarch64-darwin.nodejs-12_x];
          buildPhase = ''
            ln -s ${nodeDependencies}/lib/node_modules ./node_modules
            export PATH="${nodeDependencies}/bin:$PATH"
            export PKG_CONFIG_PATH="${self.packages.aarch64-darwin.libsass}/lib/pkgconfig:$PKG_CONFIG_PATH"
            node scripts/build -f --libsass_ext=auto
          '';
          installPhase = ''
            mkdir -p $out
            cp -r lib bin vendor package.json $out/
          '';
        };
      defaultPackage.aarch64-darwin = self.packages.aarch64-darwin.node-sass;

      # Shells
      devShells.aarch64-darwin.node-sass = ( node-sass-packages {
        system  = "aarch64-darwin";
        libsass = self.aarch64-darwin.libsass;
      } ).shell;
      devShell.aarch64-darwin = self.devShells.aarch64-darwin.node-sass;
    };
}
