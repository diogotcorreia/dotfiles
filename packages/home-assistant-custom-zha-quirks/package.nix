# Custom quirks for ZHA
# https://github.com/zigpy/zha-device-handlers
{
  lib,
  runCommandLocal,
  ...
}: let
  mkQuirk = quirkPath:
    runCommandLocal (builtins.baseNameOf quirkPath) {} ''
      cp ${quirkPath} $out
    '';

  customQuirks = builtins.listToAttrs (
    map
    (quirkPath:
      lib.nameValuePair
      (lib.removeSuffix ".py" (builtins.baseNameOf quirkPath))
      (mkQuirk quirkPath))
    (lib.my.listFilesWithSuffixRecursive ".py" ./.)
  );
in
  customQuirks
