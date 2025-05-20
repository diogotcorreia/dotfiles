# https://github.com/NixOS/nixpkgs/issues/401010
{...}: (_: prev: {
  healthchecks = let
    inherit (prev) lib;
    # https://discourse.nixos.org/t/python-possible-to-override-packageoverrides/63855/3
    preservePython3PackageOverrides = p:
      p
      // {
        override = lib.mirrorFunctionArgs p.override (
          fdrv:
            preservePython3PackageOverrides (
              p.override (
                previous: let
                  fdrv' = lib.toFunction fdrv previous;
                in
                  fdrv'
                  // lib.optionalAttrs (fdrv' ? python3) {
                    python3 =
                      fdrv'.python3
                      // {
                        override = lib.mirrorFunctionArgs fdrv'.python3.override (
                          fdrv:
                            fdrv'.python3.override (
                              previous: let
                                fdrv' = lib.toFunction fdrv previous;
                              in
                                fdrv'
                                // {
                                  packageOverrides =
                                    lib.composeExtensions previous.packageOverrides or (_: _: {})
                                    fdrv'.packageOverrides or (_: _: {});
                                }
                            )
                        );
                      };
                  }
              )
            )
        );
      };
    python = let
      packageOverrides = _pyfinal: pyprev: {
        pydantic = pyprev.pydantic.overridePythonAttrs rec {
          version = "2.11.4";
          src = prev.fetchFromGitHub {
            owner = "pydantic";
            repo = "pydantic";
            tag = "v${version}";
            hash = "sha256-/LMemrO01KnhDrqKbH1qBVyO/uAiqTh5+FHnrxE8BUo=";
          };
        };
        pydantic-core = pyprev.pydantic-core.overridePythonAttrs (_old: rec {
          version = "2.33.2";
          src = prev.fetchFromGitHub {
            owner = "pydantic";
            repo = "pydantic-core";
            tag = "v${version}";
            hash = "sha256-2jUkd/Y92Iuq/A31cevqjZK4bCOp+AEC/MAnHSt2HLY=";
          };
          cargoDeps = prev.rustPlatform.fetchCargoVendor {
            inherit src;
            name = "pydantic-core-2.33.2";
            hash = "sha256-MY6Gxoz5Q7nCptR+zvdABh2agfbpqOtfTtor4pmkb9c=";
          };
        });
      };
    in
      prev.python3.override {
        self = python;
        inherit packageOverrides;
      };
  in
    (preservePython3PackageOverrides prev.healthchecks).override {
      python3 = python;
    };
})
