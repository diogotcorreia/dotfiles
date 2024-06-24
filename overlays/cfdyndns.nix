# Use cfdyndns from nixos-unstable
{...}: final: prev: {
  cfdyndns = prev.unstable.cfdyndns.overrideAttrs (oldAttrs: {
    patches = [
      # Fix cfdyndns not working if CAA records are present in the zone
      # https://github.com/nrdxp/cfdyndns/pull/56
      (prev.fetchpatch {
        url = "https://github.com/nrdxp/cfdyndns/commit/1c7a3a4a2f0426dddce8e7195360aa39219b27f0.patch";
        hash = "sha256-aUpPUzOcfFQjf7GFfAlM2LEZiSEQULoKNXLt+5SnpAE=";
      })
    ];
  });
}
