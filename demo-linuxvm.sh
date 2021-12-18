# Interactive demo:
# Create and connect to a linux VM in Azure
# You need az and a SSH key in ~/.ssh

echo "Don't run this as a script!" && exit

demo=demo$RANDOM
rgname=${demo}
vmname=${demo}vm
location=westeurope

az group create -l $location -n $rgname -o yamlc
az vm create --image UbuntuLTS -g $rgname -n $vmname -o yamlc
pip=$(az vm show -g $rgname -n $vmname -d --query publicIps -o tsv)

ssh $pip

# delete everything
az group delete -g $rgname -y --no-wait
