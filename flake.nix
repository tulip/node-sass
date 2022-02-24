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
        , python3
        , fetchurl
        , fetchgit
        , nix-gitignore
        }@args:
          let
            nodeEnv = node-sass-env { inherit system; };
            globalBuildInputs = [libsass python3];
            filteredArgs =
              builtins.removeAttrs args [
                "system" "libsass" "python3"
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
          } ).shell.nodeDependencies.overrideAttrs ( prev: {
                dontNpmInstall = true;
              } );
        in nixpkgs.legacyPackages.aarch64-darwin.stdenv.mkDerivation {
          pname = "node-sass";
          version = "7.0.1";
          src = ./.;
          buildInputs = with nixpkgs.legacyPackages.aarch64-darwin; [
            nodejs-12_x
            python3
            xcbuild
          ];
          buildPhase = 
            let
              libsass = self.packages.aarch64-darwin.libsass;
            in ''
            export HOME=$TMPDIR
            export PATH="${nodeDependencies}/bin:$PATH"
            export NODE_PATH="${nodeDependencies}/lib/node_modules:$NODE_PATH"
            export libsass_ext=yes
            export libsass_cflags="-I${libsass}/include"
            export libsass_ldflags="-L${libsass}/lib"
            export libsass_library="-lsass"
            node scripts/build --force
          '';

          installPhase = ''
            mkdir -p $out
            test -d lib && cp -r lib $out/lib
            test -d bin && cp -r bin $out/bin
            test -d build && cp -r build $out/build
            test -d scripts && cp -r scripts $out/scripts
            test -d src && cp -r src $out/src
            test -d test && cp -r test $out/test
            test -d vendor && cp -r vendor $out/vendor
            test -f package.json && cp package.json $out/package.json
            test -f package-lock.json && cp package-lock.json $out/package-lock.json
            test -f CHANGELOG.md && cp CHANGELOG.md $out/CHANGELOG.md
            test -f LICENSE && cp LICENSE $out/LICENSE
            test -f README.md && cp README.md $out/README.md
            test -f binding.gyp && cp binding.gyp $out/binding.gyp
            true
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
