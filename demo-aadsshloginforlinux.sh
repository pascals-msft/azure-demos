# Interactive demo:
# Login to a Linux VM in Azure with Azure AD using openSSH certificate-based authentication
# https://docs.microsoft.com/en-us/azure/active-directory/devices/howto-vm-sign-in-azure-ad-linux
# prerequisite: az extension add --name ssh

echo "Don't run this as a script!" && exit

# Azure login
az login
# Check connection
az account show -o yamlc

# *** begin here ***
demo=demo$RANDOM
rgname=${demo}
vmname=${demo}vm

# VM and extension
az group create -l westeurope -n $rgname
az vm create --image UbuntuLTS -g $rgname -n $vmname --assign-identity
az vm extension set \
    --publisher Microsoft.Azure.ActiveDirectory \
    --name AADSSHLoginForLinux \
    --resource-group $rgname \
    --vm-name $vmname

# RBAC role
username=$(az account show --query user.name -o tsv)
vm=$(az vm show -g $rgname -n $vmname --query id -o tsv)
az role assignment create \
    --role "Virtual Machine Administrator Login" \
    --assignee $username \
    --scope $vm

# *** login with az ssh ***
az ssh vm -n $vmname -g $rgname
# try some commands, look at /var/log/auth.log... and logout

# *** login with ssh ***
pip=$(az vm show -g $rgname -n $vmname -d --query publicIps -o tsv)
az ssh config -f ~/.ssh/config_${demo} -n $vmname -g $rgname
cat ~/.ssh/config_${demo}
ssh -F ~/.ssh/config_${demo} $pip
# try some commands, look at /var/log/auth.log... and logout
# cleanup:
rm ~/.ssh/${demo}config
rm ~/.ssh/config_${demo}
rm -rf ~/.ssh/az_ssh_config/

# *** delete everything ***
az group delete -g $rgname -y --no-wait
