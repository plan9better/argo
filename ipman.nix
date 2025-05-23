{lib, ...}: {
  helm.releases.ipman = {
    chart = lib.helm.downloadHelmChart {
      repo = "https://dialohq.github.io/ipman";
      chart = "ipman";
      version = "0.0.2";
      chartHash = "sha256-qYOOBjvwna/1qLmew//hr/qp+Rw+wOYMIoPJtzs8OR8=";
    };
    values.Image.tag = "0.0.1-3";
  };
}
