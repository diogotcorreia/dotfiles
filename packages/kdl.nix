# Copied from open PR https://github.com/NixOS/nixpkgs/pull/295211
# TODO: remove when merged upstream
# The KDL document language (https://kdl.dev/)
{
  lib,
  callPackage,
}:
{ }:
{
  type =
    with lib.types;
    let
      # https://github.com/kdl-org/kdl/blob/main/SPEC.md#value
      untypedKdlValue =
        (nullOr (oneOf [
          str
          bool
          number
        ]))
        // {
          description = "KDL value";
        };
      kdlValue = either untypedKdlValue (
        (submodule {
          options = {
            type = lib.mkOption {
              type = nullOr str;
              default = null;
              description = ''
                [Type Annotation](https://github.com/kdl-org/kdl/blob/main/SPEC.md#type-annotation) of the value.
                Set to `null` to prevent generating a type annotation.
              '';
            };
            value = lib.mkOption {
              type = untypedKdlValue;
              description = ''
                The actual KDL value.
              '';
            };
          };
        })
        // {
          description = "submodule: { type = /* type annotation */; value = /* KDL value */; }";
        }
      );
      node = submoduleWith {
        modules = lib.toList {
          options = {
            name = lib.mkOption {
              type = str;
              description = ''
                Name of [KDL node](https://github.com/kdl-org/kdl/blob/main/SPEC.md#node).
              '';
            };
            type = lib.mkOption {
              type = nullOr str;
              default = null;
              description = ''
                [Type Annotation](https://github.com/kdl-org/kdl/blob/main/SPEC.md#type-annotation) of [KDL node](https://github.com/kdl-org/kdl/blob/main/SPEC.md#node).
                Set to `null` to prevent generating a type annotation.
              '';
            };
            arguments = lib.mkOption {
              type = listOf kdlValue;
              default = [ ];
              description = ''
                [Arguments](https://github.com/kdl-org/kdl/blob/main/SPEC.md#argument) of [KDL node](https://github.com/kdl-org/kdl/blob/main/SPEC.md#node).
              '';
            };
            properties = lib.mkOption {
              type = attrsOf kdlValue;
              default = { };
              description = ''
                [Properties](https://github.com/kdl-org/kdl/blob/main/SPEC.md#property) of [KDL node](https://github.com/kdl-org/kdl/blob/main/SPEC.md#node).
              '';
            };
            children = lib.mkOption {
              type = listOf (
                node
                // {
                  # Prevent Nix from trying to recurse into suboptions or submodules, as this leads to a stack overflow
                  getSubOptions = _prefix: { };
                  getSubModules = null;
                }
              );
              default = [ ];
              description = ''
                [Children](https://github.com/kdl-org/kdl/blob/main/SPEC.md#children-block) of [KDL node](https://github.com/kdl-org/kdl/blob/main/SPEC.md#node).
              '';
            };
          };
        };
        description = "KDL node";
      };
      valueType = listOf node;
    in
    valueType;

  lib = {
    /*
      *
      Helper function for generating attrsets expect by pkgs.formats.kdl
      # Example
      ```nix
      let
        settingsFormat = pkgs.formats.kdl { };
        inherit (settingsFormat.lib) node;
      in
      settingsFormat.generate "sample.kdl" [
        (node "foo" null [ ] { } [
          (node "bar" null [ "baz" ] { a = 1; } [ ])
        ])
      ]
      ```
      # Arguments
      name
      : The name of the node, represented by a string
      type
      : The type annotation of the node, represented by a string, or null to avoid generating a type annotation
      arguments
      : The arguments of the node, represented as a list of KDL values
      properties
      : The properties of the node, represented as an attrset of KDL values
      children
      : The children of the node, represented as a list of nodes
    */
    node = name: type: arguments: properties: children: {
      inherit
        name
        type
        arguments
        properties
        children
        ;
    };

    /*
      *
      Helper function for generting the format of a typed value as expected by pkgs.formats.kdl
      type
      : The type of the value, represented by a string
      value
      : The value itself
    */
    typed = type: value: { inherit type value; };
  };

  generate =
    name: value:
    callPackage (
      {
        runCommand,
        my,
      }:
      runCommand name
        {
          nativeBuildInputs = [ my.json2kdl ];
          value = builtins.toJSON value;
          passAsFile = [ "value" ];
        }
        ''
          json2kdl "$valuePath" "$out"
        ''
    ) { };
}
