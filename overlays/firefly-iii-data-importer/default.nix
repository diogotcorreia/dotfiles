# Apply patches to firefly-iii-data-importer
{ ... }:
_final: prev: {
  firefly-iii-data-importer = prev.firefly-iii-data-importer.overrideAttrs (_oldAttrs: {
    patches = [
      # Throw warning instead of error if transactions cannot be found
      ./0001-no-transactions-warning-instead-of-error.diff
      # Show GoCardless max access date for each bank during setup
      ./0002-show-gocardless-max-access-days.diff
    ];
  });
}
