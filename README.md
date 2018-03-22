# Install Scripts for User Sync Tool
These scripts will help you install and configure Adobe's User Sync tool.  User Sync runs behind your enterprise firewall on a virtual machine 
and quietly keeps your named user accounts in sync with your local LDAP compliant directory!

Overview:
https://spark.adobe.com/page/E3hSsLq3G1iVz/

User Sync Tool:
https://github.com/adobe-apiplatform/user-sync.py


### Windows Powershell:
You should set the execution policy for powershell to allow your VM to run scripts temporarily

<code>Set-ExecutionPolicy Bypass -Scope Process;</code> 

<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vx8fh","${PWD}\inst.ps1"); .\inst.ps1; rm -Force .\inst.ps1;</code>


##### Arguments

<code>-py <2 | 3></code>

You can choose which Python version to use by changing the -py flag
on the call. Values of 2 and 3 are allowed.  Note that Adobe recommends using at least Python 3.6.3 for future
support.

<code>-cleanpy</code>

This feature is useful! When used, the script will remove <b>all existing Python installations for all versions</b>, which
leaves the VM clean so that the correct versions can be used.  User Sync <b>requires</b> that the installed Python version be
64 bit! This flag helps to smooth and clean up the install process.

Example calls with flags:

<code>(New-Object System.Net.WebClient).DownloadFile("url-here","${PWD}\inst.ps1"); .\inst.ps1 <b>-py 2</b>; rm -Force .\inst.ps1;</code>

<code>(New-Object System.Net.WebClient).DownloadFile("url-here","${PWD}\inst.ps1"); .\inst.ps1 <b>-cleanpy</b>; rm -Force .\inst.ps1;</code>

### Ubuntu 12.04 + 
<b>This script is still under development, additional setup may be required!!</b>

For older versions (12.04), you may need to run this line first to enable the proper security protocols

<code>sudo sh -c 'apt-get update; apt-get install curl openssl libssl-dev -y;'</code>

The following will install User Sync and related packages (includes Python)

<code>sudo sh -c 'curl -s -L https://git.io/vx8JV > ins.sh; chmod 777 ins.sh; ./ins.sh; rm ins.sh;'</code>
