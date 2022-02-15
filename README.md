# azure-demos
Azure demos

| file | description |
| ---- | ----------- |
| [demo-aadsshloginforlinux.sh](demo-aadsshloginforlinux.sh) | Login to a Linux VM in Azure with Azure AD using openSSH certificate-based authentication |
| [demo-bastion.ps1](demo-bastion.ps1) | Native client connections to VMs with Azure Bastion |
| [demo-lighthouse.ps1](demo-lighthouse.ps1) | Onboard a customer to Azure Lighthouse, on a resource group |
| [demo-linuxvm.sh](demo-linuxvm.sh) | Create and connect to a linux VM in Azure |
| [demo-msi-az.sh](demo-msi-az.sh) | Using a VM's Managed Identity to access Azure resources |
| [demo-msi-kv.sh](demo-msi-kv.sh) | Using a VM's Managed Identity to access a secret in an Azure Key Vault |

Prerequisites:
* For shell-based demos (*.sh), [install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).
* For PowerShell-based demos (*.ps1), [install PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows) and then [install the Azure Az PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps).
* For all demos, consider using [Visual Studio Code](https://code.visualstudio.com/). Assign a keyboard shortcut (for instance: `F8`) to the `Terminal: Run Selected Text in Active Terminal` command. This way you will be able to run commands from the demos more easily.