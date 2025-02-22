{ lib, fetchFromGitHub, buildGoModule }:

buildGoModule rec {
  pname = "azure-storage-azcopy";
  version = "10.15.0";

  src = fetchFromGitHub {
    owner = "Azure";
    repo = "azure-storage-azcopy";
    rev = "v${version}";
    sha256 = "sha256-iXMkvrBANuOIyyVyQ11YQ1DWRQf4JAtu+1Ou3aQrhlc=";
  };

  subPackages = [ "." ];

  vendorSha256 = "sha256-OlsNFhduilo8fJs/mynrAiwuXcfCZERdaJk3VcAUCJw=";

  doCheck = false;

  postInstall = ''
    ln -rs "$out/bin/azure-storage-azcopy" "$out/bin/azcopy"
  '';

  meta = with lib; {
    maintainers = with maintainers; [ colemickens ];
    license = licenses.mit;
    description = "The new Azure Storage data transfer utility - AzCopy v10";
  };
}
