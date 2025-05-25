{lib, ...}: {
  helm.releases.ipman = {
    chart = lib.helm.downloadHelmChart {
      repo = "https://dialohq.github.io/ipman";
      chart = "ipman";
      version = "0.0.4";
      chartHash = "sha256-p+jMzmfhUvyIFN+7F2BaJchrB/Uvu0OqWEnh5LsgUT8=";
    };
  };
}
