# Temporary fix for https://github.com/NixOS/nixpkgs/pull/354728
# To be removed as soon as PR is available in nixos-24.05.
{...}: final: prev: let
  overrideImapTools = drv:
    drv.overridePythonAttrs (old: rec {
      version = "1.7.3";
      src = prev.fetchFromGitHub {
        owner = "ikvk";
        repo = "imap_tools";
        rev = "refs/tags/v${version}";
        hash = "sha256-orzU5jTFTj8O1zYDUDJYbXGpfZ60Egz0/eUttvej08k=";
      };
      pyproject = true;
      format = null;
      build-system = [prev.python3.pkgs.setuptools];
    });
in {
  paperless-ngx-cursed = prev.paperless-ngx.override (old: {
    # unfortunately paperless-ngx is also using packageOverrides,
    # so a naive override of imap-tools does not work
    python3 =
      old.python3
      // {
        override = newAttrs:
          old.python3.override ({
              packageOverrides = final: prev:
                {
                  imap-tools = overrideImapTools prev.imap-tools;
                }
                // (newAttrs.packageOverrides final prev);
              # self = old.python3;
            }
            // builtins.removeAttrs newAttrs ["packageOverrides"]);
      };
  });
}
