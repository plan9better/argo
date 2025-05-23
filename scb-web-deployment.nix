let
  ipmanName = "scb-web";
  proxyPoolName = "proxy";
  childName = "scb-web";
  image = "nginx:stable";
  deploymentLabels = {
    "app" = "scb-web-proxy";
  };

  pools = {
    "${proxyPoolName}" = [
      "10.93.74.128/32"
      "10.93.74.129/32"
      "10.93.74.130/32"
    ];
  };
  scbIp = "193.22.252.93";
  node = {
    ip = "146.59.69.1";
    name = "nixos";
  };
  namespace = "scb-web";

  scb-web-ipman-annotations = {
    "ipman.dialo.ai/childName" = childName;
    "ipman.dialo.ai/ipmanName" = ipmanName;
    "ipman.dialo.ai/poolName" = proxyPoolName;
  };
  secretKey = "ike-scb-web";
  secretName = "ike-scb-web";
in {
  namespaces."${namespace}".metadata.labels = {
    "pod-security.kubernetes.io/enforce" = "privileged";
    "pod-security.kubernetes.io/enforce-version" = "latest";
  };
  secrets."${secretName}".data."${secretKey}" = "testtest";
  ipmen.scb-web.metadata.namespace = namespace;
  ipmen.scb-web.spec = {
    name = "scb-web";
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
    children.scb-web = {
      extra = {
        start_action = "start";
        close_action = "none";
        dpd_action = "restart";
        rekey_time = "1h";
        esp_proposals = "aes256-sha256-modp2048";
      };
      name = "scb-web";
      local_ips = ["10.93.74.128/25"];
      remote_ips = ["10.93.74.0/25"];
      xfrm_ip = "10.94.74.150/32";
      vxlan_ip = "10.94.74.151/32";
      if_id = 101;
      ip_pools = pools;
    };
  };
  # deployments.scb-web.spec = {
  #   selector.matchLabels = deploymentLabels;
  #   template = {
  #     metadata = {
  #       labels = deploymentLabels;
  #       annotations = scb-web-ipman-annotations;
  #     };
  #     spec = {
  #       containers.proxy = {
  #         securityContext = {
  #           allowPrivilegeEscalation = false;
  #           capabilities.add = ["NET_ADMIN" "NET_RAW"];
  #         };
  #         image = image;
  #         volumeMounts = {
  #           "/etc/nginx".name = "nginx-config";
  #         };
  #       };
  #       volumes = {
  #         nginx-config = {
  #           configMap.name = "nginx-config";
  #         };
  #       };
  #     };
  #   };
  # };
  pods.scb-web = {
    metadata.namespace = "scb-web";
    spec = {
      restartPolicy = "Never";
      containers.proxy = {
        securityContext = {
          allowPrivilegeEscalation = false;
          capabilities.add = ["NET_ADMIN" "NET_RAW"];
        };
        image = image;
        volumeMounts = {
          "/etc/nginx".name = "nginx-config";
        };
      };
      volumes = {
        nginx-config = {
          configMap.name = "nginx-config";
        };
      };
    };
  };
  configMaps = {
    nginx-config.data."nginx.conf" = ''
      events {}
      http {
          server {
              listen 80;

              location /prod {
                  proxy_pass https://10.93.74.5;
              }
              location /test {
                  proxy_pass https://10.93.74.95;
              }
              location /env35a {
                  proxy_pass https://10.93.74.7;
              }
              location /env27a {
                  proxy_pass https://10.93.74.97;
              }
          }
      }
    '';
  };
}
