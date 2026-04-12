{
  description = "AWS Developer Associate labs — dev shell";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            # IaC
            pkgs.terraform
            pkgs.awscli2

            # Go (app/)
            pkgs.go

            # Python toolchain
            pkgs.python312
            pkgs.uv

            # Handy extras
            pkgs.jq
            pkgs.curl
          ];

          shellHook = ''
            echo "aws-labs dev shell"
            echo "  terraform $(terraform version -json | jq -r '.terraform_version')"
            echo "  $(python3 --version)"
            echo "  uv $(uv --version)"
            echo ""
            echo "  make lab-apply LAB=01-lambda-apigw"
            echo "  make py-test"
          '';
        };
      });
}
