{lib, ...}: {
  helm.releases.vlanman = {
    # chart = ../vlanman-0.1.4.tgz;
    chart = lib.helm.downloadHelmChart {
      repo = "https://dialohq.github.io/vlanman";
      chart = "vlanman";
      version = "v0.1.5";
      chartHash = "sha256-geB7pXkjATWP2ZvCC8TXzS9DfS83q/eqMZYuXNX7jbk=";
    };
    values = {
      global.monitoring = {
        enabled = true;
        release = "kps";
      };
      controller = {
        image = "plan9better/vlanman:dev";
        pullPolicy = "Always";
      };
      manager = {
        image = "plan9better/vlan-manager:dev";
        pullPolicy = "Always";
      };
      worker = {
        image = "plan9better/vlan-worker:dev";
        pullPolicy = "Always";
      };
      interface = {
        image = "plan9better/vlan-interface:dev";
        pullPolicy = "Always";
      };
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
            "10.1.7.3/24"
            "10.1.7.8/24"
          ];
          routes = [];
        }
      ];
    };
  };
}
