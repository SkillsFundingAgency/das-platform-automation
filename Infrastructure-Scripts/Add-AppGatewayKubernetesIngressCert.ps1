[CmdletBinding()]
param(
    $AppGatewayName,
    $AppGatewayResourceGroup,
    $IngressManifestPath,
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

