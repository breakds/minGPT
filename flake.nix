{
  description = "A minimal PyTorch re-implementation of the OpenAI GPT (Generative Pretrained Transformer) training";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";

    utils.url = "github:numtide/flake-utils";
    utils.inputs.nixpkgs.follows = "nixpkgs";

    ml-pkgs.url = "github:nixvital/ml-pkgs";
    ml-pkgs.inputs.nixpkgs.follows = "nixpkgs";
    ml-pkgs.inputs.utils.follows = "utils";
  };

  outputs = { self, nixpkgs, ... }@inputs : inputs.utils.lib.eachSystem [
    "x86_64-linux"
  ] (system:
    let pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            (final: prev: rec {
              python3 = prev.python3.override {
                packageOverrides = pyFinal: pyPrev: rec {
                  pytorchWithCuda11 = inputs.ml-pkgs.packages."${system}".pytorchWithCuda11;
                };
              };
              python3Packages = python3.pkgs;
            })
          ];
        };
    in {
      devShells.default = let pythonForMinGPT = pkgs.python3.withPackages (pyPkgs: with pyPkgs; [
        numpy
        pytorchWithCuda11

        # Tools
        jupyterlab
        rich
        matplotlib
      ]); in pkgs.mkShell {
        name = "minGPT";

        packages = [
          pythonForMinGPT
          pkgs.nodePackages.pyright
        ];
      };
    });
}
