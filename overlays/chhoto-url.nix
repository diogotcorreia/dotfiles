# Listen on ::1
# Upstream issue: https://github.com/SinTan1729/chhoto-url/issues/93
{ ... }:
(_: prev: {
  chhoto-url = prev.chhoto-url.overrideAttrs (prev: {
    postPatch = (prev.postPatch or "") + ''
      substituteInPlace src/main.rs --replace-fail "0.0.0.0" "::1"
    '';
  });
})
