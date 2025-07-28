{lib, ...}: {
  helm.releases.vlanman = {
    chart = ../vlanman-0.1.1.tgz;
    values.global.monitoring = {
      enabled = true;
      release = "kps";
    };
  };

  resources = {
    vlanNetworks.test-vlan2.spec = {
      localSubnet = ["10.0.1.0/24"];
      remoteSubnet = ["192.168.100.10/24"];
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
