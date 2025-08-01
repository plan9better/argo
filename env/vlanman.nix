{lib, ...}: {
  helm.releases.vlanman = {
    # chart = ../vlanman-0.1.3.tgz;
    chart = lib.helm.downloadHelmChart {
      repo = "https://dialohq.github.io/vlanman";
      chart = "vlanman";
      version = "0.1.3";
      chartHash = "sha256-C3l4hfzX6G4JaU0bcdXHkb3fqDyySP9VRKEzYJx4EWE=";
    };
    values.global.monitoring = {
      enabled = true;
      release = "kps";
    };
  };

  resources = {
    deployments.switch-ssh.spec = {
      replicas = 1;
      selector.matchLabels."app.kubernetes.io/name" = "switch-ssh";
      template.metadata.labels."app.kubernetes.io/name" = "switch-ssh";
      template.metadata.annotations = {
        "vlanman.dialo.ai/network" = "test-vlan2";
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
        ];
      };
    };
    vlanNetworks.test-vlan2.spec = {
      localSubnet = ["10.0.1.0/24"];
      remoteSubnet = ["192.168.100.10/24"];
      mappings = [
        {
          nodeName = "k3s-1";
          interfaceName = "d0";
        }
      ];
      vlanId = 2;
      pools = [
        {
          name = "primary";
          description = "dupa";
          addresses = [
            "10.0.1.100/24"
          ];
        }
      ];
    };
  };
}
