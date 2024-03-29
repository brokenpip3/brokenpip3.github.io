{
  description = "brokenpip3 blog";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    theme = {
      url = "gitlab:gabmus/hugo-ficurinia/e681e6583286eeca1035bedeecb0a802cb824045";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, pre-commit-hooks, theme, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # from https://ilanjoselevich.com/blog/building-websites-using-nix-flakes-and-zola/
        # dynamic read theme name (easy to switch)
        themeName = ((builtins.fromTOML (builtins.readFile "${theme}/theme.toml")).name);
        baseUrl = ((builtins.fromTOML (builtins.readFile ./hugo.toml)).baseURL);
      in
      {
        # Nix fmt
        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

        # Pre commit checks in nix flake check
        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
            };
          };
        };

        # website build
        packages.website = pkgs.stdenv.mkDerivation rec {
          name = "brokenpip3-website";
          src = ./.;
          nativeBuildInputs = [ pkgs.git pkgs.hugo ];
          configurePhase = ''
            mkdir -p "themes"
            [ -L "themes/${themeName}" ] && unlink "themes/${themeName}" || true
            ln -s ${theme} "themes/${themeName}"
          '';
          buildPhase = "${pkgs.hugo}/bin/hugo --minify --baseURL ${baseUrl}";
          installPhase = "cp -r public $out";
        };

        # shell in nix develop
        devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = [
            pkgs.hugo
            pkgs.imagemagick #generate-icons script
          ];
          shellHook = ''
            echo ">"
            hugo version
            echo "Theme ${themeName}"
            echo "<"
            mkdir -p "themes"
            [ -L "themes/${themeName}" ] && unlink "themes/${themeName}" || true
            ln -s ${theme} "themes/${themeName}"
          '';
        };

      }
    );
}
