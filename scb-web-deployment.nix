let
  scbIp = "193.22.252.93";
  node = {
    ip = "146.59.69.1";
    name = "hgrai1-1";
  };

  ipmanName = "scb";
  proxyPoolName = "proxy";
  childName = "scb";
  image = "caddy:2.10.0-alpine";
  deploymentLabels = {
    "app" = "scb-proxy";
  };

  pools = {
    "${proxyPoolName}" = [
      "10.93.74.129/32"
      "10.93.74.130/32"
      "10.93.74.131/32"
    ];
  };
  namespace = "external-apps";

  scb-ipman-annotations = {
    "ipman.dialo.ai/childName" = childName;
    "ipman.dialo.ai/ipmanName" = ipmanName;
    "ipman.dialo.ai/poolName" = proxyPoolName;
  };
  secretKey = "scb";
  secretName = "ipsec-psks";
in {
  ipmen.scb.metadata.namespace = namespace;
  ipmen.scb.spec = {
    name = "scb";
    remoteAddr = scbIp;
    remoteId = scbIp;
    localAddr = node.ip;
    localId = node.ip;
    secretRef = {
      name = "${secretName}";
      namespace = namespace;
      key = "${secretKey}";
    };
    nodeName = node.name;
    extra = {
      version = "2";
      proposals = "aes256-sha256-modp2048";
      rekey_time = "86400s";
      over_time = "180s";
      mobike = "no";
      dpd_delay = "30s";
      dpd_timeout = "150s";
      fragmentation = "yes";
      encap = "yes";
    };
    children.scb = {
      extra = {
        start_action = "start";
        close_action = "none";
        dpd_action = "restart";
        rekey_time = "1h";
        esp_proposals = "aes256-sha256-modp2048";
      };
      name = "scb";
      local_ips = ["10.93.74.128/25"];
      remote_ips = ["10.93.74.0/25"];
      xfrm_ip = "10.94.74.150/32";
      vxlan_ip = "10.94.74.151/32";
      if_id = 101;
      ip_pools = pools;
    };
  };
  deployments.scb.spec = {
    selector.matchLabels = deploymentLabels;
    template = {
      metadata = {
        labels = deploymentLabels;
        annotations = scb-ipman-annotations;
      };
      spec = {
        containers = {
          prod-proxy = {
            securityContext.allowPrivilegeEscalation = false;
            image = image;
            ports."prod" = {
              name = "prod";
              containerPort = 80;
            };
            command = ["caddy" "reverse-proxy" "--from" ":80" "--to" "https://10.93.74.5"];
          };
          test-proxy = {
            securityContext.allowPrivilegeEscalation = false;
            image = image;
            ports."test" = {
              name = "test";
              containerPort = 81;
            };
            command = ["caddy" "reverse-proxy" "--from" ":81" "--to" "https://10.93.74.95"];
          };
          env35a-proxy = {
            securityContext.allowPrivilegeEscalation = false;
            image = image;
            ports."env35a" = {
              name = "env35a";
              containerPort = 82;
            };
            command = ["caddy" "reverse-proxy" "--from" ":82" "--to" "http://10.93.74.7"];
          };
          env27a-proxy = {
            securityContext.allowPrivilegeEscalation = false;
            ports."env27a" = {
              name = "env27a";
              containerPort = 83;
            };
            image = image;
            command = ["caddy" "reverse-proxy" "--from" ":83" "--to" "http://10.93.74.97"];
          };
        };
      };
    };
  };
}
