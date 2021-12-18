# Interactive demo:
# Using a VM's Managed Identity to access a secret in an Azure Key Vault
# You need az and a SSH key in ~/.ssh
#
# 1. create a VM with a system assigned managed identity
# 2. create Key Vault
#    set access policy for the VM identity - secrets: get
#    add a secret in the vault
# 3. in the VM:
#    get an access token for Azure Key Vault
#    get the secret from the vault using the access token

echo "Don't run this as a script!" && exit

# Azure login
az login
# Check connection
az account show -o yamlc

# *** begin here ***
location=westeurope
demo=demo$RANDOM
rgname=${demo}
vmname=${demo}vm
kvname=${demo}kv
secretname=demosecret

# resource group
az group create -n $rgname -l $location -o yamlc
# VM (Ubuntu LTS, DS1 v2 by default) with managed identity
az vm create --image UbuntuLTS -g $rgname -n $vmname --assign-identity -o yamlc
vmpip=$(az vm show -g $rgname -n $vmname -d --query publicIps -o tsv)
echo VM public IP: $vmpip

# key vault
#az keyvault create -g $rgname -n $kvname -l $location --enable-rbac-authorization
az keyvault create -g $rgname -n $kvname -l $location -o yamlc
az keyvault secret set --vault-name $kvname --name $secretname --value "super_secret_password" -o yamlc

# key vault access policy
spid=$(az vm show -n $vmname -g $rgname --query identity.principalId -o tsv)
echo Service Principal ID: $spid
az keyvault set-policy -n $kvname --object-id $spid --secret-permissions get -o yamlc

# key vault permissions (RBAC)
#spid=$(az vm show -n $vmname -g $rgname --query identity.principalId -o tsv)
#SUB_ID=$(az account show --query id -o tsv)
#KV_ID=/subscriptions/$SUB_ID/resourceGroups/$rgname/providers/Microsoft.KeyVault/vaults/$kvname
#az role assignment create --assignee $spid --role 'Key Vault Secrets User (preview)' --scope $KV_ID

# connect to the vm
ssh $vmpip

########## run the following _on the VM_ #########

# use Azure Instance Metadata Service (IMDS) to get some info about the VM
response=$(curl -s -H Metadata:true http://169.254.169.254/metadata/instance?api-version=2019-06-01)
demo=$(echo $response | python -c 'import sys, json; print (json.load(sys.stdin)["compute"]["resourceGroupName"])')
kvname=${demo}kv && echo $kvname
secretname=demosecret

# get a token with curl -- can parse the token in https://jwt.ms
response=$(curl -s -H Metadata:true 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net')
token=$(echo $response | python -c 'import sys, json; print (json.load(sys.stdin)["access_token"])')
echo Access token: $token

# get the secret from the key vault
response=$(curl -s -H "Authorization: Bearer $token" https://$kvname.vault.azure.net/secrets/$secretname?api-version=2016-10-01)
echo $response
secretvalue=$(echo $response | python -c 'import sys, json; print (json.load(sys.stdin)["value"])')
echo Secret value: $secretvalue

logout

##################################################

# delete everything
az group delete -n $rgname -y --no-wait

