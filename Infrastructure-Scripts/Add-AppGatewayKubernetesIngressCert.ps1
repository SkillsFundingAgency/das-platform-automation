<#
.SYNOPSIS
Adds a certificate to an Application Gateway from a KeyVault based on configuration contained in a Kubernetes Ingress manifest.

.DESCRIPTION
Adds a certificate to an Application Gateway from a KeyVault based on configuration contained in a Kubernetes Ingress manifest.

.PARAMETER AppGatewayName
The name of the Application Gateway the certificate will be installed on.

.PARAMETER AppGatewayResourceGroup
The Application Gateway's resource group.

.PARAMETER IngressManifestPath
The path to the Kubernetes Ingress manifest.  The Ingress should include the appgw.ingress.kubernetes.io/appgw-ssl-certificate annotation.
Whilst the value of this annotation is arbritrary, in order for this script to work it should match the name of the certificate in the KeyVault.

.PARAMETER KeyVaultName
The name of the KeyVault that stores the certificate, must be in the same Azure subscription.

.EXAMPLE
./Add-AppGatewayKubernetesIngressCert.ps1 -AppGatewayName das-foo-ag -AppGatewayResourceGroup das-foo-rg -IngressManifestPath ./ingress.yml -KeyVaultName das-foo-kv

#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]    
    $AppGatewayName,
    [Parameter(Mandatory = $true)]
    $AppGatewayResourceGroup,
    [Parameter(Mandatory = $true)]
    $IngressManifestPath,
    [Parameter(Mandatory = $true)]
    $KeyVaultName
)

$IngressManifestContent = Get-Content -Path $IngressManifestPath
foreach ($Line in $IngressManifestContent) {
    $Match = $Line -match "appgw.ingress.kubernetes.io/appgw-ssl-certificate: (.*)"
    if ($Match) {
        Write-Verbose "Found certificate name in ingress manifest"
        $CertificateName = $Matches[1]
        break
    }
}

$AppGateway = Get-AzApplicationGateway -Name $AppGatewayName -ResourceGroupName $AppGatewayResourceGroup
if (!(Get-AzApplicationGatewaySslCertificate -Name $CertificateName -ApplicationGateway $AppGateway -ErrorAction SilentlyContinue)) {
    $KeyVaultCertificate = Get-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $CertificateName
    $VersionLessSecretId = $KeyVaultCertificate.SecretId -replace $KeyVaultCertificate.Id, ""
    Write-Verbose "Certificate versionless secret id is $VersionLessSecretId"

    Write-Verbose "Creating app gateway ssl certificate ..."
    $UpdatedAg = Add-AzApplicationGatewaySslCertificate -ApplicationGateway $AppGateway -Name $CertificateName -KeyVaultSecretId $VersionLessSecretId
    Set-AzApplicationGateway -ApplicationGateway $UpdatedAg
}
else {
    Write-Verbose "Certificate $CertficateName already exists, no action."
}