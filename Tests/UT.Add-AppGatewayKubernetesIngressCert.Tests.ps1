Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Add-AppGatewayKubernetesIngressCert unit tests" -Tag "Unit" {
    Mock Get-AzApplicationGateway -MockWith {
        return @{
            Name = "das-foo-ag"
        }
    }
    Mock Get-AzKeyVaultCertificate -MockWith {
        return @{
            SecretId = "https://foo-bar-shared-kv.vault.azure.net:443/secrets/foo-bar-gov-uk/1234567890a1234567b1c1d12efg12h1"
            Version = "1234567890a1234567b1c1d12efg12h1"
        }
    }
    Mock Add-AzApplicationGatewaySslCertificate -MockWith {
        return @{
            Name = "das-foo-ag"
        }
    }
    Mock Set-AzApplicationGateway

    $Params = @{
        AppGatewayName = "das-foo-ag"
        AppGatewayResourceGroup = "das-foo-rg"
        KeyVaultName = "das-foo-kv"
    }

    Context "Create a certificate from a valid manifest" {
        It "Should create a cert if the cert doesn't exist in the app gateway" {
            Mock Get-AzApplicationGatewaySslCertificate

            $Params["IngressManifestPath"] = "../Tests/Resources/mock-ingress.yml"

            ./Add-AppGatewayKubernetesIngressCert @Params

            Assert-MockCalled -CommandName 'Get-AzApplicationGateway' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzApplicationGatewaySslCertificate' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzKeyVaultCertificate' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Add-AzApplicationGatewaySslCertificate' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Set-AzApplicationGateway' -Times 1 -Scope It
        }

        It "Should do nothing if the cert does exist in the app gateway" {
            Mock Get-AzApplicationGatewaySslCertificate -MockWith {
                return @{
                    Name = "wildcard-foo-gov-uk"
                }
            }

            $Params["IngressManifestPath"] = "../Tests/Resources/mock-ingress.yml"

            ./Add-AppGatewayKubernetesIngressCert @Params

            Assert-MockCalled -CommandName 'Get-AzApplicationGateway' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzApplicationGatewaySslCertificate' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzKeyVaultCertificate' -Times 0 -Scope It
            Assert-MockCalled -CommandName 'Add-AzApplicationGatewaySslCertificate' -Times 0 -Scope It
            Assert-MockCalled -CommandName 'Set-AzApplicationGateway' -Times 0 -Scope It
        }
    }

    Context "Create a certificate from a valid manifest" {
        It "Should do nothing if the manifest doesn't include the correct annotation" {
            Mock Get-AzApplicationGatewaySslCertificate

            $Params["IngressManifestPath"] = "../Tests/Resources/mock-invalid-ingress.yml"

            { ./Add-AppGatewayKubernetesIngressCert @Params } | Should throw "appgw.ingress.kubernetes.io/appgw-ssl-certificate annotation not found in ingress manifest"

            Assert-MockCalled -CommandName 'Get-AzApplicationGateway' -Times 0 -Scope It
            Assert-MockCalled -CommandName 'Get-AzApplicationGatewaySslCertificate' -Times 0 -Scope It
            Assert-MockCalled -CommandName 'Get-AzKeyVaultCertificate' -Times 0 -Scope It
            Assert-MockCalled -CommandName 'Add-AzApplicationGatewaySslCertificate' -Times 0 -Scope It
            Assert-MockCalled -CommandName 'Set-AzApplicationGateway' -Times 0 -Scope It
        }
    }
}
