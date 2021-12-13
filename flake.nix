{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "aarch64-linux" "i686-linux" "x86_64-linux" ]
    (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        defaultPackage = packages.particleulary-good-campfire;
        devShell = pkgs.mkShell {
          inputsFrom = [ defaultPackage ];
          buildInputs = [
            pkgs.inotify-tools # For `dune build -w'.
            pkgs.ocamlPackages.utop
          ];
        };
        packages = {
          glfw-ocaml = pkgs.ocamlPackages.buildDunePackage rec {
            pname = "glfw-ocaml";
            version = "3.3.1-1";

            useDune2 = true;
            minimalOCamlVersion = "4.12";
            src = pkgs.fetchFromGitHub {
              owner = "SylvainBoilard";
              repo = pname;
              rev = version;
              hash = "sha256-ik0lFc3QChZSUkaSr28RFdtM2CSNNW4Q9SqWtrzjMAc=";
            };

            nativeBuildInputs = [ pkgs.pkg-config ];
            buildInputs = [ pkgs.ocamlPackages.dune-configurator ];
            propagatedBuildInputs = [ pkgs.glfw ];
          };
          particleulary-good-campfire = pkgs.ocamlPackages.buildDunePackage {
            pname = "particleulary_good_campfire";
            version = "0.1.0";

            useDune2 = true;
            minimalOCamlVersion = "4.12";
            src = ./.;
            doCheck = true;

            buildInputs =
              [ packages.glfw-ocaml packages.tgls pkgs.ocamlPackages.imagelib ];
            postInstall = ''
              cp -r assets $out/assets
            '';
          };
          tgls = pkgs.stdenv.mkDerivation rec {
            pname = "tgls";
            version = "0.8.5";

            src = pkgs.fetchurl {
              url =
                "https://erratique.ch/software/${pname}/releases/${pname}-${version}.tbz";
              hash = "sha256-o7Us5/9uwDigZo2nqsErHlL7JJTpv8hXDSnH/IZErHU=";
            };

            nativeBuildInputs = [ pkgs.pkg-config ];
            buildInputs = [
              pkgs.libGL
              pkgs.ocaml
              pkgs.ocamlPackages.findlib
              pkgs.ocamlPackages.ocamlbuild
              pkgs.ocamlPackages.topkg
            ];
            propagatedBuildInputs = [ pkgs.ocamlPackages.ctypes ];

            inherit (pkgs.ocamlPackages.topkg) buildPhase installPhase;
          };
        };
      });
}
