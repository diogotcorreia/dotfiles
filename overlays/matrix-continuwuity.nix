# Update to 0.5.6 (has security fixes)
{ ... }:
(_: prev: {
  matrix-continuwuity = prev.matrix-continuwuity.overrideAttrs (
    finalAttrs: oldAttrs: {
      version = "0.5.6";
      src = prev.fetchFromGitea {
        domain = "forgejo.ellis.link";
        owner = "continuwuation";
        repo = "continuwuity";
        tag = "v${finalAttrs.version}";
        hash = "sha256-p6dL1wL9n+1ivUItdlZuLxTneDBjCHEdNr0ukau2rHI=";
      };
      cargoHash = "sha256-lLbnFA2WS96er84G2e9bGrYhhqe2zL3Npn1SXB3De2w=";

      cargoDeps = prev.rustPlatform.fetchCargoVendor {
        inherit (oldAttrs) pname;
        inherit (finalAttrs) src version;
        hash = finalAttrs.cargoHash;
      };

    }
  );
})
