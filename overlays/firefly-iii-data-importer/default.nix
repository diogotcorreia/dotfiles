# Apply patches to firefly-iii-data-importer
{...}: final: prev: {
  firefly-iii-data-importer = prev.firefly-iii-data-importer.overrideAttrs (oldAttrs: {
    patches = [
      # Throw warning instead of error if transactions cannot be found
      ./0001-no-transactions-warning-instead-of-error.diff
      # Send file name of JSON config in email report.
      # This is helpful when the Nordigen/GoCardless EUA expires,
      # otherwise it is not possible to know which account expired
      ./0002-send-file-name-in-email.diff
      # Do not execute `artisan config:clear` when pressing the "Start Over"
      # button, otherwise the env variables will be cleared.
      ./0003-do-not-clear-config-when-starting-over.diff
    ];
  });
}
