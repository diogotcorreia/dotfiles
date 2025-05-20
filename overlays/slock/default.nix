# Apply patches to slock
{...}: _final: prev: {
  slock = prev.slock.overrideAttrs (_oldAttrs: {
    patches = [
      (prev.fetchpatch {
        url = "https://tools.suckless.org/slock/patches/dpms/slock-dpms-1.4.diff";
        sha256 = "sha256-hfe71OTpDbqOKhu/LY8gDMX6/c07B4sZ+mSLsbG6qtg=";
      })
    ];
  });
}
