{lib, ...}: {
  helm.releases.ipman = {
    chart = lib.helm.downloadHelmChart {
      repo = "https://dialohq.github.io/ipman";
      chart = "ipman";
      version = "0.0.7-1";
      chartHash = "sha256-C+g4pvqfsmj/tyQHW1fagmlWo92Ty2KUTkJIVKU0Jh8=";
    };
  };
}
