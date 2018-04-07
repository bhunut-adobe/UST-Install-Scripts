# Install Scripts for Adobe User Sync Tool
These scripts will help you install and configure Adobe's User Sync tool.  User Sync runs behind your enterprise firewall on a virtual machine 
and quietly keeps your named user accounts in sync with your local LDAP compliant directory!

Overview:
https://spark.adobe.com/page/E3hSsLq3G1iVz/<br/>
User Sync Tool:
https://github.com/adobe-apiplatform/user-sync.py


## Windows Powershell:
You should set the execution policy for powershell to allow your VM to run scripts temporarily:

<code>Set-ExecutionPolicy Bypass -Scope Process;</code> 

Run the install script:

<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vx8fh","inst.ps1"); .\inst.ps1; rm -Force .\inst.ps1;</code>

### Incudes:
<ul>
<li>python 2.7 or 3.64</li>
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

You can choose which python version to use by changing the -py flag
on the call. Values of 2 and 3 are allowed.  You can also choose none, if you wish to skip python.

<code>-cleanpy</code>

This feature is useful! When used, the script will remove <b>all existing python installations for all versions</b>, which
leaves the VM clean so that the correct versions can be used.  User Sync <b>requires</b> that the installed python version be
64 bit! This flag helps to smooth and clean up the install process.

<code>-offline</code>

This option builds a complete UST package, and includes the appropriate python installer as part of the archive.  You can use this
to generate install packages for VM's that are not able to run the script.  You can also use "-py none" to create a package
with no installer.

Example calls with flags:

<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vx8fh","inst.ps1"); .\inst.ps1 <b>-py 2</b>; rm -Force .\inst.ps1;</code>

<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vx8fh","inst.ps1"); .\inst.ps1 <b>-cleanpy</b>; rm -Force .\inst.ps1;</code>

### Ubuntu 12.04 + 
<b>This script is still under development - additional setup may be required!!</b>

The following will install User Sync and related packages (includes python if desired)

<code>sudo sh -c 'wget -O ins.sh https://git.io/vx8JV; chmod 777 ins.sh; ./ins.sh; rm ins.sh;'</code>

For older versions (12.04), you may need to run this line first to enable the proper security protocols

<code>sudo sh -c 'apt-get update; apt-get install wget openssl libssl-dev -y -qq;' &> /dev/null</code>

### Arguments

<code>--ust-Version <2.2.2 | 2.3></code>

Specify which version of UST you want to install.  The recommended version at this time is 2.2.2, since 2.3 is currently 2.3rc4. By default, 2.2.2 will be installed.
The version of UST to be used along with your host Ubuntu version determine which python version shoudl be used, and fetches the appropriate user-sync package.

<code>--install-python</code>

By default, python is neither installed nor updated.  The script will determine which version of the user-sync tool to fetch based on which python versions are native to your
host Ubuntu version.  If you add the <b/>--install-python</b> flag, the script will determine the highest possible python version that can be installed on your host to work with
the selected UST version, and install/update that python version before downloading the tool.  This command can also be used in conjunction with the --offline flag to build
deployment archives for a target host and optimal python version.  The general behavior is: find which version of python 3 the UST version requires.  If that version is available, install it.
Otherwise, revert to python 2.7.

<code>--offline</code>

This option builds a complete UST package in .tar.gz format on your local machine. You can use this
to deploy the tool to VM's that are not able to run the script. Use this in combination with the above commands
to produce a target UST/python version package for your host.

Example calls with flags:

<code>sudo sh -c 'wget -O ins.sh https://git.io/vx8JV; chmod 777 ins.sh; ./ins.sh --install-python; rm ins.sh;'</code>

<code>sudo sh -c 'wget -O ins.sh https://git.io/vx8JV; chmod 777 ins.sh; ./ins.sh --install-python --ust-version 2.3; rm ins.sh;'</code>

### Release Notes
https://github.com/janssenda-adobe/UST-Install-Scripts/releases/tag/2.0

This release introduces smart versioning. The script will choose which python build of the User Sync tool to download, depending on your host Ubuntu version and the User Sync version you have selected. Running the script with no arguments will automatically fetch the latest release version of User Sync (currently 2.2.2), and check your system to determine which build to get. User Sync version can be specified by --ust-version. The default version is 2.2.2, but 2.3rc4 can be fetched by using --ust-version 2.3.

Python install has moved to a command line argument of --install-python. When specified, versioning is affected. The script will calculate the maximum supported python version for your host that corresponds to the max python version of the user-sync executable for the chosen UST version. The script install or update that version of python during the process. This is now the recommended option, but is intentionally left out of default. The script can correctly map versioning for Ubuntu 12.04 - 18.04. All LTS (even) releases are fully supported. Intermediate (odd) releases are supported, but special cases are required for some. The user will be prompted for those options during install.

Version 2.0 also incorporates packaging. Using the --offline flag along with --ust-version and --install-python, you can build a .tar.gz archive of the fully configured UST instance for any of the supported Ubuntu distributions and any of their supported python/user-sync combinations. Leave off --install-python to build a compatible package for any distro that will not require any python modification.

