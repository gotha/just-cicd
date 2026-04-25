{
  description = "just-cicd - Agent skill for Justfile conventions and CI/CD pipelines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          name = "just-cicd-dev";

          packages = with pkgs; [
            just
            nixfmt-rfc-style
            statix
            shellcheck
            actionlint
          ];

          shellHook = ''
            echo "🛠️  just-cicd development environment"
            echo "    just version: $(just --version)"
            echo ""
            echo "Validate example Justfiles:"
            echo "    for f in examples/justfiles/*.justfile; do"
            echo "        just --justfile \"\$f\" --list >/dev/null"
            echo "    done"
            echo ""
          '';
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
