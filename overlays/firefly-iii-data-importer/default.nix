# Apply patches to firefly-iii-data-importer
{...}: final: prev: {
  # TODO: use stable on nixos-24.11
  firefly-iii-data-importer = prev.unstable.firefly-iii-data-importer.overrideAttrs (oldAttrs: {
    patches = [
      # Fix issue where too long external IDs in transactions break import
      # https://github.com/firefly-iii/firefly-iii/issues/9347
      (prev.fetchpatch {
        url = "https://github.com/firefly-iii/data-importer/commit/abb351f268b0f91c52cc7076098d79f5661a8873.patch";
        sha256 = "sha256-KTghYeQH7EQ5aDJvOsgdImuEg1H7qJ8vB9zagMbKiPI=";
      })
      # Throw warning instead of error if transactions cannot be found
      ./0001-no-transactions-warning-instead-of-error.diff
    ];
  });
}
