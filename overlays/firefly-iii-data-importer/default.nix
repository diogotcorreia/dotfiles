# Apply patches to firefly-iii-data-importer
{...}: final: prev: {
  firefly-iii-data-importer = prev.firefly-iii-data-importer.overrideAttrs (oldAttrs: {
    patches = [
      # Throw warning instead of error if transactions cannot be found
      ./0001-no-transactions-warning-instead-of-error.diff
    ];
  });
}
