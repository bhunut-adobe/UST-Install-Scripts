# Install Scripts for UST and Dev
You should set the execution policy for powershell to allow your VM to run scripts temporarily

<code>Set-ExecutionPolicy Bypass -Scope Process;</code> 

### Install UST / Python Only:
<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vABrB","${PWD}\inst.ps1"); .\inst.ps1; rm -Force .\inst.ps1;</code>

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

