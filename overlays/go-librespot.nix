# Update go-librespot
# TODO: remove on 26.11?
{ ... }:
(_: prev: {
  unstable = prev.unstable // {
    go-librespot = prev.unstable.go-librespot.overrideAttrs (prevAttrs: {
      version =
        prev.lib.warnIfNot (prev.lib.versionOlder prevAttrs.version "0.10.3")
          "overriden go-librespot is older than upstream's"
          "0.10.3";
      src = prevAttrs.src.overrideAttrs {
        hash = "sha256-wjqi20q1YuZ///sdPGYSyBxvW6G51Ydw+9boXYyzZoc=";
      };

      vendorHash = "sha256-fxB99qZE+U355iKJHIl7LgxqHmYgCiU1FpbyObTXVcQ=";
    });
  };
})
