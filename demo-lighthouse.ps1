# Interactive demo:
# Onboard a customer to Azure Lighthouse, on a resource group
# Example delegation for Microsoft Sentinel
# References:
# https://docs.microsoft.com/en-us/azure/lighthouse/how-to/onboard-customer
# https://github.com/Azure/Azure-Lighthouse-samples (Resource Group Deployment)
# https://docs.microsoft.com/en-us/azure/lighthouse/how-to/manage-sentinel-workspaces

Write-Output "Don't run this as a script!"; Return

# *** begin here ***

# *** Connect to managing tenant ***
Disconnect-AzAccount
Connect-AzAccount
Get-AzContext | Format-List

# template parameters hash table *** to be customized ***
$params = @{
    mspOfferName        = "demo42 managed Sentinel Plan"    # offer name
    rgName              = "SOC-main"                        # target RG in the customer's subscription
    mspOfferDescription = "demo42 managed Sentinel Plan"    # offer description
    managedByTenantId   = (Get-AzContext).Tenant.Id         # managing tenant id
    authorizations      = (
        @{
            principalId = (Get-AzADGroup -DisplayName "SOC Security Analysts").Id               # managing tenant AAD group id
            roleDefinitionId = (Get-AzRoleDefinition -Name "Microsoft Sentinel Responder").Id   # Azure role id
            principalIdDisplayName =  "SOC Security Analysts - Microsoft Sentinel Responder"    # Assignment display name
        }, @{
            principalId = (Get-AzADGroup -DisplayName "SOC Security Analysts").Id
            roleDefinitionId = (Get-AzRoleDefinition -Name "Logic App Contributor").Id
            principalIdDisplayName =  "SOC Security Analysts - Logic App Contributor"
        }, @{
            principalId = (Get-AzADGroup -DisplayName "SOC Security Engineers").Id
            roleDefinitionId = (Get-AzRoleDefinition -Name "Microsoft Sentinel Contributor").Id
            principalIdDisplayName =  "SOC Security Engineers - Microsoft Sentinel Contributor"
        }, @{
            principalId = (Get-AzADGroup -DisplayName "SOC Security Engineers").Id
            roleDefinitionId = (Get-AzRoleDefinition -Name "Logic App Contributor").Id
            principalIdDisplayName =  "SOC Security Engineers - Logic App Contributor"
        }, @{
            principalId = (Get-AzADGroup -DisplayName "SOC Security Engineers").Id
            roleDefinitionId = (Get-AzRoleDefinition -Name "Reader").Id
            principalIdDisplayName =  "SOC Security Engineers - Reader"
        }, @{
            principalId = (Get-AzADGroup -DisplayName "SOC Security Engineers").Id
            roleDefinitionId = (Get-AzRoleDefinition -Name "Managed Services Registration assignment Delete Role").Id
            principalIdDisplayName =  "SOC Security Engineers - assignment delete"
        }
    )
}

# *** Connect to customer subscription/tenant ***
Disconnect-AzAccount
Connect-AzAccount

# deployment
New-AzDeployment `
    -Location "westeurope" `
    -TemplateUri "https://raw.githubusercontent.com/Azure/Azure-Lighthouse-samples/master/templates/delegated-resource-management/rg/rg.json" `
    -TemplateParameterObject $params `
    -Verbose

# list definitions and assignments
Get-Command -Module Az.ManagedServices
Get-AzManagedServicesDefinition | Format-List
Get-AzManagedServicesAssignment | Format-List
