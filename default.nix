let
  config = {
  packageOverrides = pkgs: rec {
    haskellPackages = pkgs.haskellPackages.override {
      overrides = haskellPackagesNew: haskellPackagesOld: rec {
              my-app = haskellPackagesNew.callCabal2nix "my-app" ./. {};
      };
    };
  };
  };

  rpiPkgs = import <nixpkgs> { 
		inherit config; 
		crossSystem = (import <nixpkgs/lib>).systems.examples.raspberryPi;
	};

  pkgs = import <nixpkgs> { 
		inherit config; 
	};
in
	{ 
    my-app-native = pkgs.haskellPackages.my-app;
    my-app-rpi = rpiPkgs.haskellPackages.my-app;
	}