{lib, ...}: {
  helm.releases.ipman = {
    chart = lib.helm.downloadHelmChart {
      repo = "https://dialohq.github.io/ipman";
      chart = "ipman";
      version = "0.0.6";
      chartHash = "sha256-vgzh1oGfIo0P+QZ+EWLgYOPO5bN05p2s3+K9D6zO2O8=";
    };
  };
}
