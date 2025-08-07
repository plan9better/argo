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
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
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
        "gateways" = mkOption {
          description = "";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecGateways"));
        };
        "managerAffinity" = mkOption {
          description = "ManagerAffinity defines node affinity rules for the VLAN manager pods";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinity");
        };
        "mappings" = mkOption {
          description = "Mappings defines the node-to-interface mappings for this VLAN network";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecMappings"));
        };
        "pools" = mkOption {
          description = "Pools defines the IP address pools available for allocation in this VLAN network";
          type = coerceAttrsOfSubmodulesToListByKey "vlanman.dialo.ai.v1.VlanNetworkSpecPools" "name" [];
          apply = attrsToList;
        };
        "vlanId" = mkOption {
          description = "VlanID specifies the VLAN identifier (1-4094)";
          type = types.int;
        };
      };

      config = {
        "gateways" = mkOverride 1002 null;
        "managerAffinity" = mkOverride 1002 null;
        "mappings" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecGateways" = {
      options = {
        "address" = mkOption {
          description = "";
          type = types.str;
        };
        "routes" = mkOption {
          description = "";
          type = types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecGatewaysRoutes");
        };
      };

      config = {};
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecGatewaysRoutes" = {
      options = {
        "dest" = mkOption {
          description = "Destination specifies the target subnet for the route, in CIDR format. For example: \"10.0.0.0/24\", you can omit the subnet mask, in that case '/32' will be chosen. 10.0.0.0 -> 10.0.0.0/32";
          type = types.str;
        };
        "scopeLink" = mkOption {
          description = "ScopeLink determines whether the scope of the route will be set to 'LINK', for routes to the gateway it is required.";
          type = types.nullOr types.bool;
        };
        "src" = mkOption {
          description = "Source determines how the source IP is selected for this route. Allowed values: \"self\": use an IP assigned from the current VLAN pool, \"none\": no source IP (use default behavior)";
          type = types.str;
        };
        "via" = mkOption {
          description = "Via specifies the next-hop IP address for the route. If omitted, the route is assumed to be directly connected.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "scopeLink" = mkOverride 1002 null;
        "via" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinity" = {
      options = {
        "nodeAffinity" = mkOption {
          description = "Describes node affinity scheduling rules for the pod.";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinity");
        };
        "podAffinity" = mkOption {
          description = "Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s)).";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinity");
        };
        "podAntiAffinity" = mkOption {
          description = "Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s)).";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinity");
        };
      };

      config = {
        "nodeAffinity" = mkOverride 1002 null;
        "podAffinity" = mkOverride 1002 null;
        "podAntiAffinity" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinity" = {
      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node matches the corresponding matchExpressions; the\nnode(s) with the highest sum are the most preferred.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"));
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to an update), the system\nmay or may not try to eventually evict the pod from its node.";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution");
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" = {
      options = {
        "preference" = mkOption {
          description = "A node selector term, associated with the corresponding weight.";
          type = submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference";
        };
        "weight" = mkOption {
          description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
          type = types.int;
        };
      };

      config = {};
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" = {
      options = {
        "matchExpressions" = mkOption {
          description = "A list of node selector requirements by node's labels.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"));
        };
        "matchFields" = mkOption {
          description = "A list of node selector requirements by node's fields.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"));
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchFields" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" = {
      options = {
        "key" = mkOption {
          description = "The label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
          type = types.str;
        };
        "values" = mkOption {
          description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" = {
      options = {
        "key" = mkOption {
          description = "The label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
          type = types.str;
        };
        "values" = mkOption {
          description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" = {
      options = {
        "nodeSelectorTerms" = mkOption {
          description = "Required. A list of node selector terms. The terms are ORed.";
          type = types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms");
        };
      };

      config = {};
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" = {
      options = {
        "matchExpressions" = mkOption {
          description = "A list of node selector requirements by node's labels.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"));
        };
        "matchFields" = mkOption {
          description = "A list of node selector requirements by node's fields.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"));
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchFields" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" = {
      options = {
        "key" = mkOption {
          description = "The label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
          type = types.str;
        };
        "values" = mkOption {
          description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" = {
      options = {
        "key" = mkOption {
          description = "The label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
          type = types.str;
        };
        "values" = mkOption {
          description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinity" = {
      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"));
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"));
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" = {
      options = {
        "podAffinityTerm" = mkOption {
          description = "Required. A pod affinity term, associated with the corresponding weight.";
          type = submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm";
        };
        "weight" = mkOption {
          description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
          type = types.int;
        };
      };

      config = {};
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" = {
      options = {
        "labelSelector" = mkOption {
          description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector");
        };
        "matchLabelKeys" = mkOption {
          description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
          type = types.nullOr (types.listOf types.str);
        };
        "mismatchLabelKeys" = mkOption {
          description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
          type = types.nullOr (types.listOf types.str);
        };
        "namespaceSelector" = mkOption {
          description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector");
        };
        "namespaces" = mkOption {
          description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
          type = types.nullOr (types.listOf types.str);
        };
        "topologyKey" = mkOption {
          description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
          type = types.str;
        };
      };

      config = {
        "labelSelector" = mkOverride 1002 null;
        "matchLabelKeys" = mkOverride 1002 null;
        "mismatchLabelKeys" = mkOverride 1002 null;
        "namespaceSelector" = mkOverride 1002 null;
        "namespaces" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" = {
      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"));
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" = {
      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" = {
      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"));
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" = {
      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" = {
      options = {
        "labelSelector" = mkOption {
          description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector");
        };
        "matchLabelKeys" = mkOption {
          description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
          type = types.nullOr (types.listOf types.str);
        };
        "mismatchLabelKeys" = mkOption {
          description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
          type = types.nullOr (types.listOf types.str);
        };
        "namespaceSelector" = mkOption {
          description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector");
        };
        "namespaces" = mkOption {
          description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
          type = types.nullOr (types.listOf types.str);
        };
        "topologyKey" = mkOption {
          description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
          type = types.str;
        };
      };

      config = {
        "labelSelector" = mkOverride 1002 null;
        "matchLabelKeys" = mkOverride 1002 null;
        "mismatchLabelKeys" = mkOverride 1002 null;
        "namespaceSelector" = mkOverride 1002 null;
        "namespaces" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" = {
      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"));
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" = {
      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" = {
      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"));
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" = {
      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinity" = {
      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe anti-affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling anti-affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"));
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the anti-affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the anti-affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"));
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" = {
      options = {
        "podAffinityTerm" = mkOption {
          description = "Required. A pod affinity term, associated with the corresponding weight.";
          type = submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm";
        };
        "weight" = mkOption {
          description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
          type = types.int;
        };
      };

      config = {};
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" = {
      options = {
        "labelSelector" = mkOption {
          description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector");
        };
        "matchLabelKeys" = mkOption {
          description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
          type = types.nullOr (types.listOf types.str);
        };
        "mismatchLabelKeys" = mkOption {
          description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
          type = types.nullOr (types.listOf types.str);
        };
        "namespaceSelector" = mkOption {
          description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector");
        };
        "namespaces" = mkOption {
          description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
          type = types.nullOr (types.listOf types.str);
        };
        "topologyKey" = mkOption {
          description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
          type = types.str;
        };
      };

      config = {
        "labelSelector" = mkOverride 1002 null;
        "matchLabelKeys" = mkOverride 1002 null;
        "mismatchLabelKeys" = mkOverride 1002 null;
        "namespaceSelector" = mkOverride 1002 null;
        "namespaces" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" = {
      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"));
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" = {
      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" = {
      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"));
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" = {
      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" = {
      options = {
        "labelSelector" = mkOption {
          description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector");
        };
        "matchLabelKeys" = mkOption {
          description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
          type = types.nullOr (types.listOf types.str);
        };
        "mismatchLabelKeys" = mkOption {
          description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
          type = types.nullOr (types.listOf types.str);
        };
        "namespaceSelector" = mkOption {
          description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
          type = types.nullOr (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector");
        };
        "namespaces" = mkOption {
          description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
          type = types.nullOr (types.listOf types.str);
        };
        "topologyKey" = mkOption {
          description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
          type = types.str;
        };
      };

      config = {
        "labelSelector" = mkOverride 1002 null;
        "matchLabelKeys" = mkOverride 1002 null;
        "mismatchLabelKeys" = mkOverride 1002 null;
        "namespaceSelector" = mkOverride 1002 null;
        "namespaces" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" = {
      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"));
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" = {
      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" = {
      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = types.nullOr (types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"));
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecManagerAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" = {
      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecMappings" = {
      options = {
        "interfaceName" = mkOption {
          description = "Interface specifies the network interface name on the node";
          type = types.str;
        };
        "nodeName" = mkOption {
          description = "NodeName specifies the name of the Kubernetes node";
          type = types.str;
        };
      };

      config = {};
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecPools" = {
      options = {
        "addresses" = mkOption {
          description = "Addresses contains the list of IP addresses or CIDR blocks in this pool";
          type = types.listOf types.str;
        };
        "description" = mkOption {
          description = "Description provides a human-readable description of the IP pool";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the unique identifier for this IP pool";
          type = types.str;
        };
        "routes" = mkOption {
          description = "";
          type = types.listOf (submoduleOf "vlanman.dialo.ai.v1.VlanNetworkSpecPoolsRoutes");
        };
      };

      config = {
        "description" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkSpecPoolsRoutes" = {
      options = {
        "dest" = mkOption {
          description = "Destination specifies the target subnet for the route, in CIDR format. For example: \"10.0.0.0/24\", you can omit the subnet mask, in that case '/32' will be chosen. 10.0.0.0 -> 10.0.0.0/32";
          type = types.str;
        };
        "scopeLink" = mkOption {
          description = "ScopeLink determines whether the scope of the route will be set to 'LINK', for routes to the gateway it is required.";
          type = types.nullOr types.bool;
        };
        "src" = mkOption {
          description = "Source determines how the source IP is selected for this route. Allowed values: \"self\": use an IP assigned from the current VLAN pool, \"none\": no source IP (use default behavior)";
          type = types.str;
        };
        "via" = mkOption {
          description = "Via specifies the next-hop IP address for the route. If omitted, the route is assumed to be directly connected.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "scopeLink" = mkOverride 1002 null;
        "via" = mkOverride 1002 null;
      };
    };
    "vlanman.dialo.ai.v1.VlanNetworkStatus" = {
      options = {
        "freeIPs" = mkOption {
          description = "FreeIPs contains available IP addresses grouped by pool name";
          type = types.loaOf types.str;
        };
        "pendingIPs" = mkOption {
          description = "PendingIPs contains IP addresses that are pending allocation, grouped by pool and request";
          type = types.attrsOf types.attrs;
        };
      };

      config = {};
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
