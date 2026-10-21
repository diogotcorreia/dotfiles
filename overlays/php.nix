# https://www.php.net/archive/2026.php#2026-10-21-5
{ ... }:
(
  _: prev:
  let
    overrideFilterPackage =
      php:
      php.override {
        packageOverrides = _final: prev: {
          extensions = prev.extensions // {
            filter = prev.extensions.filter.overrideAttrs {
              postConfigure = ''
                substituteInPlace \
                  tests/oom_filter_input.phpt \
                  tests/oom_filter_input_array.phpt \
                  tests/oom_filter_default_encoded.phpt \
                  --replace-fail "'-n'," "'-n', '-d', 'extension=$PWD/modules/filter.so',"
              '';
            };
          };
        };
      };

    overridePhpVersion =
      php: prevVersion: newVersion: hash:
      php.overrideAttrs (
        finalAttrs: prevAttrs: {
          version =
            assert prevAttrs.version == prevVersion;
            newVersion;
          src = prev.fetchurl {
            url = "https://www.php.net/distributions/php-${finalAttrs.version}.tar.bz2";
            inherit hash;
          };
        }
      );
  in
  {
    php85 = overrideFilterPackage (
      overridePhpVersion prev.php85 "8.5.11" "8.5.12"
        "sha256-/7YO3EN87WO1E35JhNs3moERxQBJxxFRDYuVgnfvwag="
    );
    php84 = overrideFilterPackage (
      overridePhpVersion prev.php84 "8.4.26" "8.4.27"
        "sha256-slMKh3xyL0sIyeF0owywi6wrfhkD7m6eMV8KqfX4LCQ="
    );
    php83 = overrideFilterPackage (
      overridePhpVersion prev.php83 "8.3.35" "8.3.36"
        "sha256-RvS0XjaI7SsYGQFae1MsFbUcwFW907E/0A3f7r7tzV8="
    );
    php82 = overrideFilterPackage (
      overridePhpVersion prev.php82 "8.2.34" "8.2.35"
        "sha256-D0Pv0awk1PkAAsjU1XC/TE1Z+hQxO/JwqujPBNnf3vM="
    );
  }
)
