# This file was generated with nixidy CRD generator, do not edit.
{
  lib,
  options,
  config,
  ...
}:
with lib; let
  hasAttrNotNull = attr: set: hasAttr attr set && set.${attr} != null;

  attrsToList = values:
    if values != null
    then
      sort (
        a: b:
          if (hasAttrNotNull "_priority" a && hasAttrNotNull "_priority" b)
          then a._priority < b._priority
          else false
      ) (mapAttrsToList (n: v: v) values)
    else values;

  getDefaults = resource: group: version: kind:
    catAttrs "default" (filter (
        default:
          (default.resource == null || default.resource == resource)
          && (default.group == null || default.group == group)
          && (default.version == null || default.version == version)
          && (default.kind == null || default.kind == kind)
      )
      config.defaults);

  types =
    lib.types
    // rec {
      str = mkOptionType {
        name = "str";
        description = "string";
        check = isString;
        merge = mergeEqualOption;
      };

      # Either value of type `finalType` or `coercedType`, the latter is
      # converted to `finalType` using `coerceFunc`.
      coercedTo = coercedType: coerceFunc: finalType:
        mkOptionType rec {
          inherit (finalType) getSubOptions getSubModules;

          name = "coercedTo";
          description = "${finalType.description} or ${coercedType.description}";
          check = x: finalType.check x || coercedType.check x;
          merge = loc: defs: let
            coerceVal = val:
              if finalType.check val
              then val
              else let
                coerced = coerceFunc val;
              in
                assert finalType.check coerced; coerced;
          in
            finalType.merge loc (map (def: def // {value = coerceVal def.value;}) defs);
          substSubModules = m: coercedTo coercedType coerceFunc (finalType.substSubModules m);
          typeMerge = t1: t2: null;
          functor = (defaultFunctor name) // {wrapped = finalType;};
        };
    };

  mkOptionDefault = mkOverride 1001;

  mergeValuesByKey = attrMergeKey: listMergeKeys: values:
    listToAttrs (imap0
      (i: value:
        nameValuePair (
          if hasAttr attrMergeKey value
          then
            if isAttrs value.${attrMergeKey}
            then toString value.${attrMergeKey}.content
            else (toString value.${attrMergeKey})
          else
            # generate merge key for list elements if it's not present
            "__kubenix_list_merge_key_"
            + (concatStringsSep "" (map (
                key:
                  if isAttrs value.${key}
                  then toString value.${key}.content
                  else (toString value.${key})
              )
              listMergeKeys))
        ) (value // {_priority = i;}))
      values);

  submoduleOf = ref:
    types.submodule ({name, ...}: {
      options = definitions."${ref}".options or {};
      config = definitions."${ref}".config or {};
    });

  globalSubmoduleOf = ref:
    types.submodule ({name, ...}: {
      options = config.definitions."${ref}".options or {};
      config = config.definitions."${ref}".config or {};
    });

  submoduleWithMergeOf = ref: mergeKey:
    types.submodule ({name, ...}: let
      convertName = name:
        if definitions."${ref}".options.${mergeKey}.type == types.int
        then toInt name
        else name;
    in {
      options =
        definitions."${ref}".options
        // {
          # position in original array
          _priority = mkOption {
            type = types.nullOr types.int;
            default = null;
          };
        };
      config =
        definitions."${ref}".config
        // {
          ${mergeKey} = mkOverride 1002 (
            # use name as mergeKey only if it is not coming from mergeValuesByKey
            if (!hasPrefix "__kubenix_list_merge_key_" name)
            then convertName name
            else null
          );
        };
    });

  submoduleForDefinition = ref: resource: kind: group: version: let
    apiVersion =
      if group == "core"
      then version
      else "${group}/${version}";
  in
    types.submodule ({name, ...}: {
      inherit (definitions."${ref}") options;

      imports = getDefaults resource group version kind;
      config = mkMerge [
        definitions."${ref}".config
        {
          kind = mkOptionDefault kind;
          apiVersion = mkOptionDefault apiVersion;

          # metdata.name cannot use option default, due deep config
          metadata.name = mkOptionDefault name;
        }
      ];
    });

  coerceAttrsOfSubmodulesToListByKey = ref: attrMergeKey: listMergeKeys: (
    types.coercedTo
    (types.listOf (submoduleOf ref))
    (mergeValuesByKey attrMergeKey listMergeKeys)
    (types.attrsOf (submoduleWithMergeOf ref attrMergeKey))
  );

  definitions = {
    "vlanman.dialo.ai.v1.VlanNetwork" = {
      options = {
        "apiVersion" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpec");
        };
        "status" = mkOption {
          description = "";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpec" = {
      options = {
        "excludedNodes" = mkOption {
          description = "";
          type = types.nullOr (types.listOf types.str);
        };
        "localGatewayIp" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "localSubnet" = mkOption {
          description = "";
          type = types.listOf types.str;
        };
        "pools" = mkOption {
          description = "";
          type = types.nullOr (coerceAttrsOfSubmodulesToListByKey "vlanman.dialo.ai.v1.VlanNetworkSpecPools" "name" []);
          apply = attrsToList;
        };
        "remoteGatewayIp" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "remoteSubnet" = mkOption {
          description = "";
          type = types.listOf types.str;
        };
        "vlanId" = mkOption {
          description = "";
          type = types.int;
        };
      };

      config = {
        "excludedNodes" = mkOverride 1002 null;
        "localGatewayIp" = mkOverride 1002 null;
        "pools" = mkOverride 1002 null;
        "remoteGatewayIp" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecPools" = {
      options = {
        "addresses" = mkOption {
          description = "";
          type = types.nullOr (types.listOf types.str);
        };
        "description" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
      };

      config = {
        "addresses" = mkOverride 1002 null;
        "description" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkStatus" = {
      options = {
        "freeIPs" = mkOption {
          description = "";
          type = types.nullOr (types.loaOf types.str);
        };
        "pendingIPs" = mkOption {
          description = "";
          type = types.nullOr (types.attrsOf types.attrs);
        };
      };

      config = {
        "freeIPs" = mkOverride 1002 null;
        "pendingIPs" = mkOverride 1002 null;
      };
    };
  };
in {
  # all resource versions
  options = {
    resources =
      {
        "vlanman.dialo.ai"."v1"."VlanNetwork" = mkOption {
          description = "";
          type = types.attrsOf (submoduleForDefinition "vlanman.dialo.ai.v1.VlanNetwork" "vlannetworks" "VlanNetwork" "vlanman.dialo.ai" "v1");
          default = {};
        };
      }
      // {
        "vlanNetworks" = mkOption {
          description = "";
          type = types.attrsOf (submoduleForDefinition "vlanman.dialo.ai.v1.VlanNetwork" "vlannetworks" "VlanNetwork" "vlanman.dialo.ai" "v1");
          default = {};
        };
      };
  };

  config = {
    # expose resource definitions
    inherit definitions;

    # register resource types
    types = [
      {
        name = "vlannetworks";
        group = "vlanman.dialo.ai";
        version = "v1";
        kind = "VlanNetwork";
        attrName = "vlanNetworks";
      }
    ];

    resources = {
      "vlanman.dialo.ai"."v1"."VlanNetwork" =
        mkAliasDefinitions options.resources."vlanNetworks";
    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [];
  };
}
