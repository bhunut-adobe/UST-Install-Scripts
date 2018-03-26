# Install Scripts for Adobe User Sync Tool
These scripts will help you install and configure Adobe's User Sync tool.  User Sync runs behind your enterprise firewall on a virtual machine 
and quietly keeps your named user accounts in sync with your local LDAP compliant directory!

Overview:
https://spark.adobe.com/page/E3hSsLq3G1iVz/<br/>
User Sync Tool:
https://github.com/adobe-apiplatform/user-sync.py


## Windows Powershell:
You should set the execution policy for powershell to allow your VM to run scripts temporarily

<code>Set-ExecutionPolicy Bypass -Scope Process;</code> 

<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vx8fh","${PWD}\inst.ps1"); .\inst.ps1; rm -Force .\inst.ps1;</code>

### Incudes:
<ul>
<li>Python 2.7 or 3.64</li>
<li>UST Application and configuration files</li>
<li>Open SSL for certificate/key generation</li>
<li>7-Zip portable version for extracting .tar.gz archives</li>
<li>Notepad++ portable version for better YAML editing </li>
</ul>

### Batch Files:
<b>Run_UST_Live.bat:</b> Runs UST in live mode with options -users mapped --process-groups<br/>
<b>Run_UST_Test.bat:</b> Runs UST in test mode with options -users mapped --process-groups<br/>
<b>Adobe_IO_Cert_Generation.bat:</b> Located in Utils/OpenSSL, generates a certificate-key pair for use with the UMAPI integration.  Places private.key and certificate.crt in the primary
install directory.<br/>
<b>Open_Config_Files.bat:</b> Conveniently opens all the .yml configuration files using the included portable Notepad++ instance.

### Arguments

<code>-py <2 | 3 | none></code>

You can choose which Python version to use by changing the -py flag
on the call. Values of 2 and 3 are allowed.  You can also choose none, if you wish to skip Python.

<code>-cleanpy</code>

This feature is useful! When used, the script will remove <b>all existing Python installations for all versions</b>, which
leaves the VM clean so that the correct versions can be used.  User Sync <b>requires</b> that the installed Python version be
64 bit! This flag helps to smooth and clean up the install process.

<code>-offline</code>

This option builds a complete UST package, and includes the appropriate Python installer as part of the archive.  You can use this
to generate install packages for VM's that are not able to run the script.  You can also use "-py none" to create a package
with no installer.

Example calls with flags:

<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vx8fh","${PWD}\inst.ps1"); .\inst.ps1 <b>-py 2</b>; rm -Force .\inst.ps1;</code>

<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vx8fh","${PWD}\inst.ps1"); .\inst.ps1 <b>-cleanpy</b>; rm -Force .\inst.ps1;</code>

### Ubuntu 12.04 + 
<b>This script is still under development, additional setup may be required!!</b>

For older versions (12.04), you may need to run this line first to enable the proper security protocols

<code>sudo sh -c 'apt-get update; apt-get install curl openssl libssl-dev -y;'</code>

The following will install User Sync and related packages (includes Python)

<code>sudo sh -c 'curl -s -L https://git.io/vx8JV > ins.sh; chmod 777 ins.sh; ./ins.sh; rm ins.sh;'</code>
