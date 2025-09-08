# Apply patches to firefly-iii-data-importer
{ ... }:
_final: prev: {
  firefly-iii-data-importer = prev.firefly-iii-data-importer.overrideAttrs (_oldAttrs: {
    patches = [
      # Throw warning instead of error if transactions cannot be found
      ./0001-no-transactions-warning-instead-of-error.diff
      # Send file name of JSON config in email report.
      # This is helpful when the Nordigen/GoCardless EUA expires,
      # otherwise it is not possible to know which account expired
      ./0002-send-file-name-in-email.diff
      # When the transaction ID starts with "FOBA", use GoCardless
      # internal transaction ID instead.
      # This is because this specific bank does not have a stable
      # transaction ID (i.e., it changes every time data is fetched),
      # resulting in duplicate transactions.
      ./0003-use-internal-transaction-id-foba.diff
      # Show GoCardless max access date for each bank during setup
      ./0004-show-gocardless-max-access-days.diff
    ];
  });
}
