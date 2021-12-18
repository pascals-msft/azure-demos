# Interactive demo:
# Using a VM's Managed Identity to access Azure resources
# You need az and a SSH key in ~/.ssh
#
# 1. create a VM with a system assigned managed identity
# 2. give the VM read access to the Azure subscription
# 3. in the VM:
#    demo 1: use Azure CLI with the VM's identity
#    demo 2: use Azure REST API with the VM's identity

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

# resource group
az group create -n $rgname -l $location -o yamlc
# VM (Ubuntu LTS, DS1 v2 by default) with managed identity
az vm create --image UbuntuLTS -g $rgname -n $vmname --assign-identity -o yamlc
vmpip=$(az vm show -g $rgname -n $vmname -d --query publicIps -o tsv)
echo VM public IP: $vmpip

# give the identity read access to the Azure subscription
spid=$(az vm show -n $vmname -g $rgname --query identity.principalId -o tsv)
echo Service Principal ID: $spid
subid=$(az account show --query id -o tsv)
#az role assignment create --assignee $spid --role 'Reader' --scope /subscriptions/$subid/resourceGroups/$rgname
az role assignment create --assignee $spid --role 'Reader' --scope /subscriptions/$subid -o yamlc

# connect to the vm
ssh -o StrictHostKeyChecking=no $vmpip

########## run the following _on the VM_ #########

# demo 1: Azure CLI authent
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login --identity -o yamlc
az group list -o table
az vm list -o table
az logout

# demo 2: get a token with curl -- can parse the token in https://jwt.ms
response=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -H Metadata:true -s)
token=$(echo $response | python -c 'import sys, json; print (json.load(sys.stdin)["access_token"])')
echo Access token: $token
# use Azure Instance Metadata Service (IMDS) to get the subscription Id
subid=$(curl -s -X GET -H "Metadata: true" http://169.254.169.254/metadata/instance?api-version=2019-06-01 | python -c 'import sys, json; print (json.load(sys.stdin)["compute"]["subscriptionId"])')
echo Subscription ID: $subid
# call the Azure REST API with curl (https://aka.ms/azurerestcurl) - list the resource groups
curl -X GET -H "Authorization: Bearer $token" -H "Content-Type: application/json" https://management.azure.com/subscriptions/$subid/resourcegroups?api-version=2019-07-01

logout

##################################################

# delete everything
az group delete -n $rgname -y --no-wait

