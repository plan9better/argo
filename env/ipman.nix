{lib, ...}: let
  affinityNotInNodes = nodes: {
    nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms = [
      {
        matchExpressions = [
          {
            key = "kubernetes.io/hostname";
            operator = "NotIn";
            values = nodes;
          }
          {
            key = "dialo.ai/virtualized";
            operator = "NotIn";
            values = ["true"];
          }
        ];
      }
    ];
  };
  # The rest are vms that have the right interface by default
  mappings = [
    {
      nodeName = "astor-0";
      interfaceName = "enp9s0f1np1";
    }
    {
      nodeName = "astor-1";
      interfaceName = "enp9s0f1np1";
    }
    {
      nodeName = "astor-2";
      interfaceName = "enp9s0f1np1";
    }
    {
      nodeName = "hgrai1-0";
      interfaceName = "vrack";
    }
    {
      nodeName = "hgrai1-1";
      interfaceName = "vrack";
    }
    {
      nodeName = "scalea6-0";
      interfaceName = "vrack";
    }
    {
      nodeName = "scalea6-1";
      interfaceName = "vrack";
    }
  ];
  image = "caddy:2.10.0-alpine";
  mkContainer = {
    name,
    values,
  }: let
    portStr = builtins.toString values.localPort;

    # accept self signed certs
    insecure = lib.strings.hasPrefix "https" values.remoteUrl;
    cmd = ["caddy" "reverse-proxy" "--from" ":${portStr}" "--to" "${values.remoteUrl}"];
  in {
    securityContext.allowPrivilegeEscalation = false;
    image = image;
    ports.${name} = {
      containerPort = values.localPort;
    };
    command =
      if insecure
      then cmd ++ ["--insecure"]
      else cmd;
  };

  containers = builtins.mapAttrs (name: values:
    mkContainer {
      name = name;
      values = values;
    }) {
    prod = {
      localPort = 80;
      remoteUrl = "https://10.93.74.5";
    };
    test = {
      localPort = 81;
      remoteUrl = "https://10.93.74.95";
    };
    env35a = {
      localPort = 82;
      remoteUrl = "http://10.93.74.7";
    };
    env27a = {
      localPort = 83;
      remoteUrl = "http://10.93.74.97";
    };
  };

  hgrai1-1 = {
    ip = "146.59.69.1";
    name = "hgrai1-1";
  };
  hgrai1-0 = {
    ip = "146.59.69.47";
    name = "hgrai1-0";
  };
  astor-0 = {
    ip = "57.128.210.45";
    name = "astor-0";
  };

  ipmanName = "scb";
  proxyPoolName = "proxy";
  childName = "scb";
  pools.scb = {
    "${proxyPoolName}" = [
      "10.93.74.129/32"
      "10.93.74.130/32"
      "10.93.74.131/32"
    ];
  };

  pools.best = {
    sip = [
      "10.170.14.115/32"
    ];
  };

  pools.ultimoBackup = {
    sip = [
      "10.140.14.103/32"
      "10.140.14.104/32"
    ];
  };

  pools.mbank-primary = {
    primary = [
      "192.168.104.220/32"
      "192.168.104.221/32"
    ];
  };
  pools.mbank-secondary = {
    secondary = [
      "192.168.112.220/32"
      "192.168.112.221/32"
    ];
  };

  namespace = "external-connections";

  scb-ipman-annotations = {
    "ipman.dialo.ai/childName" = childName;
    "ipman.dialo.ai/ipmanName" = ipmanName;
    "ipman.dialo.ai/poolName" = proxyPoolName;
  };
  secretKeys = {
    scb = "scb";
    ultimoBackup = "ultimoBackup";
    best = "best";
    mbank = "mbank";
    allegro = "allegro";
  };
  secretName = "ipsec-psks";

  mkProxyAllegro = suffix: vxlanIP: let
    labels = {
      "app.kubernetes.io/name" = "allegro-sftp-proxy-${suffix}";
      "dialo.ai/proxy-target" = "allegro";
    };
    ipman-annotations = {
      "ipman.dialo.ai/childName" = "sftp";
      "ipman.dialo.ai/ipmanName" = "allegro-${suffix}";
      "ipman.dialo.ai/poolName" = "primary";
    };
    prodIP =
      if suffix == "1"
      then "169.254.4.185"
      else "169.254.5.185";
    testIP =
      if suffix == "1"
      then "169.254.4.186"
      else "169.254.5.186";
  in {
    configMaps."allegro-sftp-proxy-${suffix}".data."nginx.conf" = ''
      events {}
      stream {
        upstream ssh_prod {
          server ${prodIP}:22;
        }
        server {
          listen 2222;
          proxy_bind ${builtins.head (lib.strings.splitString "/" vxlanIP)};
          proxy_pass ssh_prod;
        }

        upstream ssh_test {
          server ${testIP}:22;
        }
        server {
          listen 2223;
          proxy_bind ${builtins.head (lib.strings.splitString "/" vxlanIP)};
          proxy_pass ssh_test;
        }
      }
    '';
    deployments."allegro-sftp-proxy-${suffix}".spec = {
      replicas = 1;
      selector.matchLabels = labels;
      template = {
        metadata = {
          inherit labels;
          annotations = ipman-annotations;
        };
        spec = {
          containers = {
            production = {
              volumeMounts = [
                {
                  name = "nginx-config";
                  mountPath = "/etc/nginx/nginx.conf";
                  subPath = "nginx.conf";
                }
              ];
              livenessProbe = {
                failureThreshold = 3;
                tcpSocket.port = 2222;
                periodSeconds = 10;
                successThreshold = 1;
                timeoutSeconds = 1;
              };
              image = "nginx:1.29";
            };
          };
          volumes = [
            {
              name = "nginx-config";
              configMap.name = "allegro-sftp-proxy-${suffix}";
            }
          ];
        };
      };
    };
  };
  scbSipVlanIP = "10.93.80.130";
  scbSipVlanDeploymentName = "scb-sip";
  scbSipVlanNetworkName = "scb-sip-vlan";
  scbSipVlanPoolName = "primary";
in {
  helm.releases.ipman = {
    chart = lib.helm.downloadHelmChart {
      repo = "https://dialohq.github.io/ipman";
      chart = "ipman";
      version = "0.1.14";
      chartHash = "sha256-oS20DGiIs8qpW+4mkx6+cLb3Tr7xW75ZpyhcGH5Fdbk=";
    };
    values = {
      controller.image = "plan9better/operator:latest-dev-test";
      restctl.image = "plan9better/restctl:latest-dev-test";
      xfrminjector.image = "plan9better/xfrminjector:latest-dev-test";
      vxlandlord.image = "plan9better/vxlandlord:latest-dev-test";
      xfrminion.image = "plan9better/xfrminion:latest-dev-test";
      charon.image = "plan9better/charon:latest-dev-test";
    };
    values.global.monitoring = {
      enabled = true;
      release = "kps";
    };
  };

  resources = {
    services.${scbSipVlanDeploymentName}.spec = {
      ports = [
        {
          name = "grpc";
          port = 8675;
          protocol = "TCP";
          targetPort = 8675;
        }
      ];
      selector."app.kubernetes.io/name" = scbSipVlanDeploymentName;
    };
    vlanNetworks.${scbSipVlanNetworkName}.spec = {
      vlanId = 100;
      mappings = mappings;
      managerAffinity = affinityNotInNodes [
        "hgrai1-1"
        "scalea6-0"
        "scalea6-1"
      ];
      pools = [
        {
          name = scbSipVlanPoolName;
          description = "Primary IP pool";
          addresses = [
            "${scbSipVlanIP}/24"
          ];
          routes = [
            {
              dest = "10.93.255.66/32";
              src = "self";
              scopeLink = true;
            }
            {
              dest = "10.93.148.23/32";
              via = "10.93.255.66";
              src = "none";
            }
          ];
        }
      ];
    };

    deployments.${scbSipVlanDeploymentName} = {
      spec = {
        replicas = 1;
        revisionHistoryLimit = 0;
        selector.matchLabels."app.kubernetes.io/name" = scbSipVlanDeploymentName;
        template.metadata.labels."app.kubernetes.io/name" = scbSipVlanDeploymentName;
        template.metadata.annotations = {
          "vlanman.dialo.ai/network" = scbSipVlanNetworkName;
          "vlanman.dialo.ai/pool" = scbSipVlanPoolName;
        };

        template = {
          spec = {
            containers = [
              {
                name = "traffic-controller";
                image = "ghcr.io/dialohq/native-apps:sha-43f3d8d";
                imagePullPolicy = "IfNotPresent";
                securityContext.capabilities.add = ["IPC_LOCK"];
                command = [
                  "/bin/sip-server-scb"
                  "--workers"
                  "1"
                  "--bookkeeper"
                  "http://scb-bookkeeper-pl-2.robot:50051"
                  "--robot"
                  "http://robot-scb-in:8765"
                  "--host"
                  "$(VLAN_IP)"
                  "--port"
                  "5060"
                  "--first_rtp_port"
                  "50000"
                  "--last_rtp_port"
                  "51000"
                  "--peer_trunk"
                  "sip:scb@10.93.148.23:5060"
                  "--verbosity=debug"
                  "--grpc_port"
                  "8675"
                  "--recordings"
                  "/recordings/rtp"
                ];
                env = [
                  {
                    name = "EIO_BACKEND";
                    value = "io-uring";
                  }
                ];
                volumeMounts = [
                  {
                    mountPath = "/recordings/wav";
                    name = "wav";
                  }
                  {
                    mountPath = "/recordings/rtp";
                    name = "rtp";
                  }
                ];
              }
              {
                image = "nginx";
                name = "recorder";
                volumeMounts = [
                  {
                    mountPath = "/recordings/wav";
                    name = "wav";
                  }
                  {
                    mountPath = "/recordings/rtp";
                    name = "rtp";
                  }
                ];
              }
            ];
            dnsPolicy = "ClusterFirst";
            terminationGracePeriodSeconds = 30;
            volumes = [
              {
                emptyDir = {};
                name = "wav";
              }
              {
                emptyDir = {};
                name = "rtp";
              }
            ];
          };
        };
      };
    };
    deployments.switch-proxy.spec = {
      replicas = 1;
      selector.matchLabels."app.kubernetes.io/name" = "switch-proxy";
      template.metadata.labels."app.kubernetes.io/name" = "switch-proxy";
      template.metadata.annotations = {
        "vlanman.dialo.ai/network" = "switch-proxy";
        "vlanman.dialo.ai/pool" = "primary";
      };
      template.spec = {
        containers = [
          {
            command = ["bash" "-c" "apt update -y && apt install -y socat && socat TCP4-LISTEN:22,fork,reuseaddr TCP4:192.168.100.10:22"];
            image = "ubuntu:latest";
            name = "switch-ssh-proxy";
            securityContext = {capabilities = {add = ["NET_RAW"];};};
          }
          {
            command = ["bash" "-c" "apt update -y && apt install -y socat && socat TCP4-LISTEN:80,fork,reuseaddr TCP4:192.168.100.10:80"];
            image = "ubuntu:latest";
            name = "switch-http-proxy";
            securityContext = {capabilities = {add = ["NET_RAW"];};};
          }
        ];
      };
    };

    vlanNetworks.switch-proxy.spec = {
      vlanId = 2;
      mappings = mappings;
      pools = [
        {
          name = "primary";
          description = "Primary IP pool";
          addresses = [
            "192.168.100.173/24"
          ];
          routes = [];
        }
      ];
    };

    charonGroups.astor-0-host.spec = {
      hostNetwork = true;
      nodeName = astor-0.name;
    };
    ipSecConnections.mbank-primary.spec = let
      remoteIp = "192.168.10.205";
    in {
      name = "mbank-primary";
      remoteAddr = remoteIp;
      remoteId = remoteIp;
      localAddr = astor-0.ip;
      localId = astor-0.ip;
      secretRef = {
        name = "${secretName}";
        namespace = namespace;
        key = "${secretKeys.mbank}";
      };
      groupRef = {
        name = "astor-0-host";
        namespace = "external-connections";
      };
      extra = {
        version = "2";
        rekey_time = "86400"; # 1440 minutes
        proposals = "aes256-sha384-modp2048";
      };
      children.primary = {
        extra = {
          start_action = "start";
          close_action = "none";
          dpd_action = "restart";
          esp_proposals = "aes256gcm16-aes256gcm12-aes256gcm8-modp2048"; # prefer aes256gcm16 over aes256gcm12 and that over  aes256gcm8 but accept all of them since they didn't specify exactly
        };
        name = "primary";
        local_ips = ["192.168.104.220/32" "192.168.104.221/32"];
        remote_ips = ["192.168.251.88/32" "192.168.251.89/32" "192.168.251.94/32" "192.168.251.95/32"];
        xfrm_ip = "192.168.104.219/32";
        vxlan_ip = "192.168.104.218/32";
        if_id = 106;
        ip_pools = pools.mbank-primary;
      };
    };

    charonGroups.hgrai1-0-host.spec = {
      hostNetwork = true;
      nodeName = hgrai1-0.name;
    };
    ipSecConnections.mbank-secondary.spec = let
      remoteIp = "192.168.10.204";
    in {
      name = "mbank-secondary";
      remoteAddr = remoteIp;
      remoteId = remoteIp;
      localAddr = hgrai1-0.ip;
      localId = hgrai1-0.ip;
      secretRef = {
        name = "${secretName}";
        namespace = namespace;
        key = "${secretKeys.mbank}";
      };
      groupRef = {
        name = "hgrai1-0-host";
        namespace = "external-connections";
      };
      extra = {
        version = "2";
        rekey_time = "86400"; # 1440 minutes
        proposals = "aes256-sha384-modp2048";
      };
      children.secondary = {
        extra = {
          start_action = "start";
          close_action = "none";
          dpd_action = "restart";
          esp_proposals = "aes256gcm16-aes256gcm12-aes256gcm8-modp2048"; # prefer aes256gcm16 over aes256gcm12 and that over  aes256gcm8 but accept all of them since they didn't specify exactly
        };
        name = "secondary";
        local_ips = ["192.168.112.220/32" "192.168.112.221/32"];
        remote_ips = ["192.168.252.88/32" "192.168.252.89/32" "192.168.252.94/32" "192.168.252.95/32"];
        xfrm_ip = "192.168.112.219/32";
        vxlan_ip = "192.168.112.218/32";
        if_id = 107;
        ip_pools = pools.mbank-secondary;
      };
    };

    services.traffic-controller-best.spec = {
      selector = {
        "app.kubernetes.io/name" = "traffic-controller-best";
      };
      ports = [
        {
          protocol = "TCP";
          port = 8765;
          targetPort = 8777;
        }
      ];
    };

    ipSecConnections.best.spec = let
      remoteIp = "192.168.10.204";
    in {
      name = "best";
      remoteAddr = remoteIp;
      remoteId = remoteIp;
      localAddr = astor-0.ip;
      localId = astor-0.ip;
      secretRef = {
        name = "${secretName}";
        namespace = namespace;
        key = "${secretKeys.best}";
      };
      groupRef = {
        name = "astor-0-host";
        namespace = "external-connections";
      };
      extra = {
        version = "2";
        proposals = "aes256-sha256-modp2048";
      };
      children.sip = {
        extra = {
          start_action = "start";
          close_action = "none";
          dpd_action = "restart";
          esp_proposals = "aes256-sha256-modp2048";
        };
        name = "sip";
        local_ips = ["10.170.14.115/32"];
        remote_ips = ["10.170.0.0/24"];
        xfrm_ip = "10.150.14.113/32";
        vxlan_ip = "10.150.14.114/32";
        if_id = 105;
        ip_pools = pools.best;
      };
    };
    deployments.traffic-controller-best.spec = {
      replicas = 1;
      revisionHistoryLimit = 0;
      selector.matchLabels."app.kubernetes.io/name" = "traffic-controller-best";
      strategy = {
        type = "Recreate";
      };
      template.metadata.labels."app.kubernetes.io/name" = "traffic-controller-best";
      template.metadata.annotations = {
        "ipman.dialo.ai/ipmanName" = "best";
        "ipman.dialo.ai/childName" = "sip";
        "ipman.dialo.ai/poolName" = "sip";
      };
      template.spec = {
        volumes = [
          {
            emptyDir = {};
            name = "recordings";
          }
        ];
        containers = [
          {
            env = [
              {
                name = "EIO_BACKEND";
                value = "io-uring";
              }
            ];
            image = "nginx";
            name = "traffic-controller";
            resources = {limits = {memory = "200M";};};
            securityContext = {capabilities = {add = ["IPC_LOCK"];};};

            volumeMounts = [
              {
                mountPath = "/recordings";
                name = "recordings";
              }
            ];
          }
        ];
      };
    };
    configMaps.load-tester-dialog = {
      data = {
        "test_dialog.json" = "dupa";
      };
    };
    services.fake-scheduler.spec = {
      selector = {
        "app.kubernetes.io/name" = "fake-scheduler";
      };
      ports = [
        {
          protocol = "TCP";
          port = 8766;
          targetPort = 8766;
        }
      ];
    };
    deployments.fake-scheduler.spec = {
      replicas = 1;
      selector.matchLabels."app.kubernetes.io/name" = "fake-scheduler";
      template.metadata.labels = {
        "app.kubernetes.io/name" = "fake-scheduler";
      };
      template.spec = {
        volumes = [
          {
            name = "dialog-volume";
            configMap = {
              name = "load-tester-dialog";
            };
          }
        ];
        containers = [
          {
            name = "load-tester";
            image = "nginx";
            ports = {
              robot.containerPort = 8765;
              scheduler.containerPort = 8766;
            };
            volumeMounts = [
              {
                name = "dialog-volume";
                mountPath = "/dialog/test_dialog.json";
                subPath = "test_dialog.json";
              }
            ];
          }
        ];
      };
    };

    deployments.traffic-controller-smartney.spec = {
      replicas = 1;
      revisionHistoryLimit = 0;
      selector.matchLabels."app.kubernetes.io/name" = "traffic-controller-smartney";
      strategy = {
        type = "Recreate";
      };
      template.metadata.labels."app.kubernetes.io/name" = "traffic-controller-smartney";
      template.metadata.annotations = {
        "ipman.dialo.ai/childName" = "smartney-sip";
        "ipman.dialo.ai/ipmanName" = "smartney-sip";
        "ipman.dialo.ai/poolName" = "sip";
      };
      template.spec = {
        volumes = [
          {
            emptyDir = {};
            name = "recordings";
          }
        ];
        containers = [
          {
            env = [
              {
                name = "EIO_BACKEND";
                value = "io-uring";
              }
            ];
            image = "nginx";
            name = "traffic-controller";
            resources = {limits = {memory = "200M";};};
            securityContext = {capabilities = {add = ["IPC_LOCK"];};};

            volumeMounts = [
              {
                mountPath = "/recordings";
                name = "recordings";
              }
            ];
          }
        ];
        dnsPolicy = "ClusterFirstWithHostNet";
      };
    };
    ipSecConnections.smartney-sip.metadata.namespace = namespace;
    ipSecConnections.smartney-sip.spec = {
      name = "smartney-sip";
      remoteAddr = "192.168.10.204";
      remoteId = "192.168.10.204";
      localAddr = astor-0.ip;
      localId = astor-0.ip;
      secretRef = {
        name = secretName;
        key = "smartneySIP";
        namespace = namespace;
      };
      groupRef = {
        name = "astor-0-host";
        namespace = "external-connections";
      };
      extra = {
        proposals = "aes256-sha256-modp1024";
        version = "2";
        rekey_time = "288000"; # 8h
      };
      children.smartney-sip = {
        extra = {
          start_action = "start";
          dpd_action = "restart";
          esp_proposals = "aes256-sha256-modp1024";
        };
        name = "smartney-sip";
        local_ips = ["10.7.107.56/29"];
        remote_ips = ["172.31.31.0/24"];
        xfrm_ip = "10.7.107.55/32";
        vxlan_ip = "10.7.107.54/32";
        if_id = 104;
        ip_pools = {
          sip = [
            "10.7.107.58/32"
          ];
        };
      };
    };

    ipSecConnections.ultimo-backup.metadata.namespace = namespace;
    ipSecConnections.ultimo-backup.spec = {
      name = "ultimo-backup";
      remoteAddr = "192.168.10.204";
      remoteId = "192.168.10.204";
      localAddr = astor-0.ip;
      localId = astor-0.ip;
      secretRef = {
        name = secretName;
        key = secretKeys.ultimoBackup;
        namespace = namespace;
      };
      groupRef = {
        name = "astor-0-host";
        namespace = "external-connections";
      };
      extra = {
        proposals = "aes256-sha2_256-modp1536";
        version = "2";
      };
      children.sip = {
        extra = {
          start_action = "start";
          dpd_action = "restart";
          esp_proposals = "aes128-sha1-modp1024";
        };
        name = "sip";
        local_ips = ["10.140.14.0/24"];
        remote_ips = ["10.10.13.0/24"];
        xfrm_ip = "10.140.14.10/32";
        vxlan_ip = "10.140.14.11/32";
        if_id = 102;
        ip_pools = pools.ultimoBackup;
      };
      children.api2 = {
        name = "api2";
        local_ips = ["10.140.14.0/24"];
        remote_ips = ["10.10.150.53/32"];
        xfrm_ip = "10.140.14.12/32";
        vxlan_ip = "10.140.14.13/32";
        ip_pools = pools.ultimoBackup;
        if_id = 103;
        extra = {
          start_action = "start";
          dpd_action = "restart";
          esp_proposals = "aes128-sha1-modp1024";
        };
      };
    };

    charonGroups.hgrai1-1-host.spec = {
      nodeName = hgrai1-1.name;
      hostNetwork = true;
    };
    ipSecConnections.scb.metadata.namespace = namespace;
    ipSecConnections.scb.spec = {
      name = "scb";
      remoteAddr = "192.168.10.205";
      remoteId = "192.168.10.205";
      localAddr = hgrai1-1.ip;
      localId = hgrai1-1.ip;
      secretRef = {
        name = "${secretName}";
        namespace = namespace;
        key = "${secretKeys.scb}";
      };
      groupRef = {
        name = "hgrai1-1-host";
        namespace = "external-connections";
      };
      extra = {
        version = "2";
        proposals = "aes256-sha256-modp2048";
        rekey_time = "86400";
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
          rekey_time = "3600"; # 1h
          esp_proposals = "aes256-sha256-modp2048";
        };
        name = "scb";
        local_ips = ["10.93.74.128/25"];
        remote_ips = ["10.93.74.0/25"];
        xfrm_ip = "10.94.74.150/32";
        vxlan_ip = "10.94.74.151/32";
        if_id = 101;
        ip_pools = pools.scb;
      };
    };
    deployments.traffic-controller-ultimo.spec = {
      replicas = 2;
      revisionHistoryLimit = 0;
      selector.matchLabels."app.kubernetes.io/name" = "traffic-controller-ultimo";
      strategy = {
        type = "Recreate";
      };
      template.metadata.labels."app.kubernetes.io/name" = "traffic-controller-ultimo";
      template.metadata.annotations = {
        "ipman.dialo.ai/childName" = "sip";
        "ipman.dialo.ai/ipmanName" = "ultimo-backup";
        "ipman.dialo.ai/poolName" = "sip";
      };
      template.spec = {
        volumes = [
          {
            emptyDir = {};
            name = "recordings";
          }
        ];
        containers = [
          {
            env = [
              {
                name = "EIO_BACKEND";
                value = "io-uring";
              }
            ];
            name = "traffic-controller";
            resources = {limits = {memory = "200M";};};
            securityContext = {capabilities = {add = ["IPC_LOCK"];};};
            image = "nginx";

            volumeMounts = [
              {
                mountPath = "/recordings";
                name = "recordings";
              }
            ];
          }
        ];
        dnsPolicy = "ClusterFirstWithHostNet";
      };
    };
    deployments.scb.spec = let
      labels = {
        "app" = "scb-proxy";
      };
    in {
      replicas = 2;
      selector.matchLabels = labels;
      template = {
        metadata = {
          inherit labels;
          annotations = scb-ipman-annotations;
        };
        spec = {
          containers = containers;
        };
      };
    };
    services.allegro-sftp.spec = {
      selector."dialo.ai/proxy-target" = "allegro";

      ports.production = {
        port = 22;
        protocol = "TCP";
        targetPort = 2222;
      };
      ports.test = {
        port = 23;
        protocol = "TCP";
        targetPort = 2223;
      };
    };
  };
  imports = [
    {
      resources = let
        remoteIp = "192.168.10.205";
        poolIP = "169.254.5.184/32";
      in ({
          ipSecConnections.allegro-2.spec = {
            name = "allegro-2";
            remoteAddr = remoteIp;
            remoteId = remoteIp;
            localAddr = astor-0.ip;
            localId = astor-0.ip;
            secretRef = {
              name = "${secretName}";
              namespace = namespace;
              key = "${secretKeys.allegro}";
            };
            groupRef = {
              name = "astor-0-host";
              namespace = "external-connections";
            };
            extra = {
              version = "2";
              proposals = "aes256-sha256-ecp384";
            };
            children.sftp = {
              extra = {
                start_action = "start";
                close_action = "none";
                dpd_action = "restart";
                esp_proposals = "aes256-sha1-ecp384";
              };
              name = "sftp";
              local_ips = ["169.254.5.184/32"];
              remote_ips = ["169.254.5.185/32" "169.254.5.186/32"];
              xfrm_ip = "169.254.5.183/32";
              vxlan_ip = "169.254.5.182/32";
              if_id = 109;
              ip_pools = {
                primary = [
                  poolIP
                ];
              };
            };
          };
        }
        // (mkProxyAllegro "2" poolIP));
    }
    {
      resources = let
        remoteIp = "192.168.10.205";
        poolIP = "169.254.4.184/32";
      in
        {
          ipSecConnections.allegro-1.spec = {
            name = "allegro-1";
            remoteAddr = remoteIp;
            remoteId = remoteIp;
            localAddr = astor-0.ip;
            localId = astor-0.ip;
            secretRef = {
              name = "${secretName}";
              namespace = namespace;
              key = "${secretKeys.allegro}";
            };
            groupRef = {
              name = "astor-0-host";
              namespace = "external-connections";
            };
            extra = {
              version = "2";
              proposals = "aes256-sha256-ecp384";
            };
            children.sftp = {
              extra = {
                start_action = "start";
                close_action = "none";
                dpd_action = "restart";
                esp_proposals = "aes256-sha1-ecp384";
              };
              name = "sftp";
              local_ips = ["169.254.4.184/32"];
              remote_ips = ["169.254.4.185/32" "169.254.4.186/32"];
              xfrm_ip = "169.254.4.183/32";
              vxlan_ip = "169.254.4.182/32";
              if_id = 108;
              ip_pools = {
                primary = [
                  poolIP
                ];
              };
            };
          };
        }
        // (mkProxyAllegro "1" poolIP);
    }
  ];
}
