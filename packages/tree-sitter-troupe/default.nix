# Troupe tree-sitter based on SML's
{
  tree-sitter,
  fetchFromGitHub,
  ...
}:
tree-sitter.buildGrammar {
  language = "troupe";
  version = "unstable-2022-07-29";
  src = fetchFromGitHub {
    owner = "MatthewFluet";
    repo = "tree-sitter-sml";
    rev = "340dbd3a3b72d5e71ecd0853add2c482cb914275";
    hash = "sha256-zXBxaUWwzQjnjrCHSA8oqmwbMfvuY2gEh7hKLasEMbs=";
  };
  location = null;
  generate = true;

  patches = [
    ./0001-rename-sml-to-troupe.diff
    ./0002-add-troup-highlighting.diff
  ];
}
