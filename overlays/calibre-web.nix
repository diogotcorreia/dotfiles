# TODO: remove when https://github.com/NixOS/nixpkgs/pull/422382
# reaches nixos-25.05 channel
{ ... }:
(_: prev: {
  calibre-web = prev.calibre-web.overridePythonAttrs (oldAttrs: {
    pythonRelaxDeps = (oldAttrs.pythonRelaxDeps or [ ]) ++ [ "tornado" ];
  });
})
