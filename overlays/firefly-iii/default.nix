# Apply patches to firefly-iii
{...}: final: prev: {
  firefly-iii = prev.firefly-iii.overrideAttrs (oldAttrs: {
    patches = [
      # Include seconds in the date field when editing transaction
      # https://github.com/firefly-iii/firefly-iii/issues/9666
      ./0001-allow-seconds-in-transaction-date.diff
    ];
  });
}
