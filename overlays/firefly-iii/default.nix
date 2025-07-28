# Apply patches to firefly-iii
{ ... }:
_final: prev: {
  firefly-iii = prev.firefly-iii.overrideAttrs (_oldAttrs: {
    patches = [
      # Include seconds in the date field when editing transaction
      # https://github.com/firefly-iii/firefly-iii/issues/9666
      ./0001-allow-seconds-in-transaction-date.diff
    ];
  });
}
