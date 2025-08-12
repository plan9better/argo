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
    "ipman.dialo.ai.v1.CharonGroup" = {
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
          type = types.nullOr (submoduleOf "ipman.dialo.ai.v1.CharonGroupSpec");
        };
        "status" = mkOption {
          description = "";
          type = types.nullOr (submoduleOf "ipman.dialo.ai.v1.CharonGroupStatus");
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
    "ipman.dialo.ai.v1.CharonGroupSpec" = {
      options = {
        "charonExtraAnnotations" = mkOption {
          description = "";
          type = types.nullOr (types.attrsOf types.str);
        };
        "hostNetwork" = mkOption {
          description = "";
          type = types.bool;
        };
        "interfaceName" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "nodeName" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = {
        "charonExtraAnnotations" = mkOverride 1002 null;
        "interfaceName" = mkOverride 1002 null;
      };
    };
    "ipman.dialo.ai.v1.CharonGroupStatus" = {
      options = {};

      config = {};
    };
    "ipman.dialo.ai.v1.IPSecConnection" = {
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
          type = types.nullOr (submoduleOf "ipman.dialo.ai.v1.IPSecConnectionSpec");
        };
        "status" = mkOption {
          description = "";
          type = types.nullOr (submoduleOf "ipman.dialo.ai.v1.IPSecConnectionStatus");
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
    "ipman.dialo.ai.v1.IPSecConnectionSpec" = {
      options = {
        "children" = mkOption {
          description = "";
          type = types.attrsOf types.attrs;
        };
        "extra" = mkOption {
          description = "";
          type = types.nullOr (types.attrsOf types.str);
        };
        "groupRef" = mkOption {
          description = "";
          type = types.nullOr (submoduleOf "ipman.dialo.ai.v1.IPSecConnectionSpecGroupRef");
        };
        "localAddr" = mkOption {
          description = "";
          type = types.str;
        };
        "localId" = mkOption {
          description = "";
          type = types.str;
        };
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "remoteAddr" = mkOption {
          description = "";
          type = types.str;
        };
        "remoteId" = mkOption {
          description = "";
          type = types.str;
        };
        "secretRef" = mkOption {
          description = "";
          type = submoduleOf "ipman.dialo.ai.v1.IPSecConnectionSpecSecretRef";
        };
      };

      config = {
        "extra" = mkOverride 1002 null;
        "groupRef" = mkOverride 1002 null;
      };
    };
    "ipman.dialo.ai.v1.IPSecConnectionSpecGroupRef" = {
      options = {
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = {};
    };
    "ipman.dialo.ai.v1.IPSecConnectionSpecSecretRef" = {
      options = {
        "key" = mkOption {
          description = "";
          type = types.str;
        };
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = {};
    };
    "ipman.dialo.ai.v1.IPSecConnectionStatus" = {
      options = {
        "charonProxyIp" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "freeIps" = mkOption {
          description = "";
          type = types.nullOr (types.attrsOf types.attrs);
        };
        "pendingIps" = mkOption {
          description = "";
          type = types.nullOr (types.attrsOf types.str);
        };
        "xfrmGatewayIp" = mkOption {
          description = "";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "charonProxyIp" = mkOverride 1002 null;
        "freeIps" = mkOverride 1002 null;
        "pendingIps" = mkOverride 1002 null;
        "xfrmGatewayIp" = mkOverride 1002 null;
      };
    };
  };
in {
  # all resource versions
  options = {
    resources =
      {
        "ipman.dialo.ai"."v1"."CharonGroup" = mkOption {
          description = "";
          type = types.attrsOf (submoduleForDefinition "ipman.dialo.ai.v1.CharonGroup" "charongroups" "CharonGroup" "ipman.dialo.ai" "v1");
          default = {};
        };
        "ipman.dialo.ai"."v1"."IPSecConnection" = mkOption {
          description = "";
          type = types.attrsOf (submoduleForDefinition "ipman.dialo.ai.v1.IPSecConnection" "ipsecconnections" "IPSecConnection" "ipman.dialo.ai" "v1");
          default = {};
        };
      }
      // {
        "charonGroups" = mkOption {
          description = "";
          type = types.attrsOf (submoduleForDefinition "ipman.dialo.ai.v1.CharonGroup" "charongroups" "CharonGroup" "ipman.dialo.ai" "v1");
          default = {};
        };
        "ipSecConnections" = mkOption {
          description = "";
          type = types.attrsOf (submoduleForDefinition "ipman.dialo.ai.v1.IPSecConnection" "ipsecconnections" "IPSecConnection" "ipman.dialo.ai" "v1");
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
        name = "charongroups";
        group = "ipman.dialo.ai";
        version = "v1";
        kind = "CharonGroup";
        attrName = "charonGroups";
      }
      {
        name = "ipsecconnections";
        group = "ipman.dialo.ai";
        version = "v1";
        kind = "IPSecConnection";
        attrName = "ipSecConnections";
      }
    ];

    resources = {
      "ipman.dialo.ai"."v1"."CharonGroup" =
        mkAliasDefinitions options.resources."charonGroups";
      "ipman.dialo.ai"."v1"."IPSecConnection" =
        mkAliasDefinitions options.resources."ipSecConnections";
    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [
      {
        group = "ipman.dialo.ai";
        version = "v1";
        kind = "CharonGroup";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
    ];
  };
}
