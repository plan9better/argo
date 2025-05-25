{lib, ...}: {
  helm.releases.ipman = {
    chart = lib.helm.downloadHelmChart {
      repo = "https://dialohq.github.io/ipman";
      chart = "ipman";
      version = "0.0.5";
      chartHash = "sha256-NZ7xQrIFtJlCQa9c7b2s3cGCxYTY3bp7rnpfVF8UXqM=";
    };
  };
}
