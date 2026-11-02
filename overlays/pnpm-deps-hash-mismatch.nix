# https://github.com/NixOS/nixpkgs/pull/580585
{ ... }:
(_: prev: {
  fetchPnpmDeps =
    args:
    (prev.fetchPnpmDeps args).overrideAttrs (prevAttrs: {
      fixupPhase = prev.lib.replaceString ''rm "$storePath/v11/index.db"'' ''
        rm "$storePath/v11/index.db"
        # SQLite 3.53.0 refactored code around the dump generation, that changed
        # BLOB data type representations from `X'...'` to `x'...'`, breaking existing hashes.
        # This change was made in http://github.com/sqlite/sqlite/commit/d2424338b05f2766034f91c03009c8f0d78bc937
        # and the following command reverts the dump to the old format:
        sed -i "s/,x'/,X'/g" "$storePath/v11/index.db.sql"
      '' prevAttrs.fixupPhase;
    });
})
