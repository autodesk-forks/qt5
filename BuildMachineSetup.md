# Maya 2020 Build Systems (Not for developer use)

Summary of the Maya setup instructions for Maya 2020 build systems. Developers should rely on the developer docs for the branch they are working on. This document does not have everything a developer would need.

## Links

[Ansible Playbooks](https://git.autodesk.com/maya3d/maya-pipeline/tree/master/ansible)

[Maya build Infrastructure](https://wiki.autodesk.com/pages/viewpage.action?spaceKey=meecs&title=Maya+Build+Infrastructure)

[maya-build - Ask for help on Slack](https://autodesk.slack.com/messages/C1S3YQY48)

## Setup

### Windows 10

#### Ansible Setup

Windows Maya build systems are configured via Ansible. The Ansible playbook installs all software required for PF, CI, DI and Mastering. Details can be found in the [Ansible Readme](https://git.autodesk.com/maya3d/maya-pipeline/blob/master/ansible/Readme.md)

#### Manual Setup

Note that the Ansible playbook [maya2020_build_windows.yml](https://git.autodesk.com/maya3d/maya-pipeline/blob/master/ansible/maya2020_build_windows.yml) is the original source for these instructions. There are more settings and configuration items in the Ansible playbook, but these should allow a build to run.

- Open 'Disk Manager' and initialize the data disk as an S:\ drive
  - Use the disk initialization defaults, except for drive letter (S) and name (S).
- Make the temp folder `C:\Temp`
- Create/set system environment variables `TEMP` and `TMP` to point to `C:\Temp`
- Make the folder `C:\tmp` . Signing uses this folder and it has to exist.
- Setup the system to automatically login with the 'administrator' user
- Write * credential into Windows Credential Manager
  - `cmdkey.exe /add:* /user:ads\svc_p_meci_maya /pass:<password>`
- [Install WinRar](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/WinRar/winrar-x64-550.exe)
  - Add WinRar to system PATH `C:\Program Files\WinRAR`
- [Install 7-Zip](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/7-Zip/7z1805-x64.exe)
  - Add 7-zip to system PATH `C:\Program Files\7-Zip`
- [Install WiX](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/WiX/wix37.exe)
  - Add WiX to system PATH `C:\Program Files (x86)\WiX Toolset v3.7\bin`
- [Install NotePad++](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/Notepad%2B%2B/npp.7.5.6.Installer.x64.exe)
- [Install Chrome standalone](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/chrome/68/googlechromestandaloneenterprise64.msi)
- [Extract PathVerify.zip on S:\ drive](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/PathVerify/PathVerify.zip)
  - Creates `S:\PathVerify\PathVerify.exe`
- [Install TightVNC](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/tightvnc/tightvnc-2.8.11-gpl-setup-64bit.msi)
- [Install Visual Studio 2015 Update 3](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/VisualStudio/2015/VS2015PRO.zip)
- [Install Visual Studio 2015 Update 3 patch](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/VisualStudio/2015/vs14-kb3165756-vs2016-u3-update.exe)
  - Add signtool.exe to PATH `C:\Program Files (x86)\Windows Kits\10\bin\x64`
- [Install Visual Studio 2017](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/VisualStudio/2017/latest/vs2017offline.zip)
  - Add signtool.exe to PATH `C:\Program Files (x86)\Windows Kits\10\bin\10.0.17763.0\x64`
- [Install Visual Studio 2012 redist](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/VisualStudio/2012/vs2012_update4_vcredist_x64.exe)
  - VS2012 Debug DLLs are required, but no redist exists for them. Copy and rename the [DLLs from here](https://git.autodesk.com/maya3d/maya-pipeline/tree/master/ansible/roles/visual_studio_2012_redist/files) to the `C:\Windows\System32` folder
- Install .NET Framework v3.5. Use the 'Windows Features' applet or commandline (Reqiuires internet access) 
  - `DISM /Online /Enable-Feature /FeatureName:NetFx3 /All`
- [Install Git Adsk](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/Git/ADSK/v2.0.6/install.bat)
  - `git adsk setup`
  - `git adsk setup maya`
  - `git adsk install-apps`
  - `git lfs install`
  - Make sure the git and mingw64 folders are in the system PATH
    - `C:\Program Files\Git\cmd`
    - `C:\Program Files\Git\usr\bin`
    - `C:\Program Files\Git\mingw64\bin`
    - `C:\Program Files\Git\bin`
  - Rename the signtool.exe installed with install-apps. It will not work with Maya builds.
    - `mv "C:\Program Files\Git\mingw64\bin\signtool.exe" "C:\Program Files\Git\mingw64\bin\signtool_mingw64.exe"`
  - Associate .py file extension with the python istalled with install-apps
    - If the .py extension has been associated with an application by a user, remove this registry key manually
      - `HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.py`
    - Run these commands in an elevated command prompt:
    - `assoc .py=pyfile`
    - `ftype pyfile="C:\Program Files\Git\mingw64\bin\python.exe" "%1" %*`
- [Install Electric Commander agent](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/ElectricCommander/ElectricFlow-8.0.3.125753/windows/ElectricFlowAgent-x64-8.0.3.125753.exe)
  - `ElectricFlowAgent-x64-8.0.3.125753.exe --mode silent --installAgent --agentPort 7800 --windowsAgentUser administrator --windowsAgentPassword "<password>" --remoteServer ecserver.autodesk.com`
  - Modify `C:\ProgramData\Electric Cloud\ElectricCommander\conf\agent\wrapper.conf`
    - `wrapper.java.initmemory=1024`
    - `wrapper.java.maxmemory=2048`
  - Stop and disable the EC agent service `CommanderAgent`
  - Make a shortcut in the Windows Startup folder
    - `C:\Program Files\Electric Cloud\ElectricCommander\bin\runAgent.bat` -> `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\runAgent.bat.lnk`
  - Make sure EC bin is in the PATH `C:\Program Files\Electric Cloud\ElectricCommander\bin`
- [Extract StoreBoxClient Zip into C:](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/StoreBox/StoreBoxClientWindows.zip)
- [Install Java for Jenkins agents](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/java/jre/jre-8u171-windows-x64.exe)
- Veryify that all utilities are in the system PATH, in the right order:
  - 'C:\Program Files (x86)\Windows Kits\10\bin\10.0.17763.0\x64'
  - 'C:\Program Files (x86)\Windows Kits\10\bin\x64'
  - 'C:\Program Files\Git\cmd'
  - 'C:\Program Files\Git\usr\bin'
  - 'C:\Program Files\Git\mingw64\bin'
  - 'C:\Program Files\Git\bin'
  - 'C:\StoreBoxClientWindows'
  - 'C:\Program Files\Electric Cloud\ElectricCommander\bin'
  - 'C:\Program Files\WinRAR'
  - 'C:\Program Files\7-Zip'
- Reboot

### Linux - CentOS 7.3

#### Ansible Setup

Linux Maya build systems are configured via Ansible. The Ansible playbook installs all software required for PF, CI, DI and Mastering. Details can be found in the [Ansible Readme](https://git.autodesk.com/maya3d/maya-pipeline/blob/master/ansible/Readme.md)

#### Manual Setup

Note that the Ansible playbook [maya2020_build_linux.yml](https://git.autodesk.com/maya3d/maya-pipeline/blob/master/ansible/maya2020_build_linux.yml) is the original source for these instructions. There are more settings and configuration items in the Ansible playbook, but these should allow a build to run.

- Change data drive mount ownership: `sudo chown -R administrator:administrator /local/S`
- Install utulity packages: `sudo yum install vim mlocate unzip`
- The ECS CentOS base images often have some hardening that must be be removed.
  - Edit `/etc/profile`, change `umask 077` to `umask 022` 
  - Edit `/etc/bashrc`, change `umask 077` to `umask 022`
  - Edit `/etc/bashrc`, set vi as default editor by adding this line `set -o vi`
  - Edit `/etc/fstab`, remove `noexec` option
- Install software for auto-mount network shares: `sudo yum install autofs cifs-utils`
- Create credential files for svc_p_meci_maya, svc_p_meci_mayaio and svc_p_meci_mayalt.
  - /root/cred
  - /root/cred_mayaio
  - /root/cred_mayalt
- Example credential file (`/root/cred`) content for svc_p_meci_maya:

```bash
domain=ads
username=svc_p_meci_maya
password=<password>
```

- Edit `/etc/auto.master`, 
  - Comment out this line: `#+auto.master`
  - Create this line: `/local/net /etc/auto.ecnet`
- Create this file `/etc/auto.ecnet`, with these contents:

```bash
metools -fstype=cifs,credentials=/root/cred,uid=502,forceuid,gid=502,forcegid,noperm,ro ://viola.autodesk.com/metools
meci_maya -fstype=cifs,credentials=/root/cred,uid=502,forceuid,gid=502,forcegid,noperm ://viola.autodesk.com/meci_maya
meci_maya_pf -fstype=cifs,credentials=/root/cred,uid=502,forceuid,gid=502,forcegid,noperm ://viola.autodesk.com/meci_maya_pf
meci_mayalt -fstype=cifs,credentials=/root/cred_mayalt,uid=502,forceuid,gid=502,forcegid,noperm ://viola.autodesk.com/meci_mayalt
meci_mayalt_pf -fstype=cifs,credentials=/root/cred_mayalt,uid=502,forceuid,gid=502,forcegid,noperm ://viola.autodesk.com/meci_mayalt_pf
meci_mayaio -fstype=cifs,credentials=/root/cred_mayaio,uid=502,forceuid,gid=502,forcegid,noperm ://viola.autodesk.com/meci_mayaio
meci_mayaio_pf -fstype=cifs,credentials=/root/cred_mayaio,uid=502,forceuid,gid=502,forcegid,noperm ://viola.autodesk.com/meci_mayaio_pf
marmotte -fstype=cifs,credentials=/root/cred,uid=502,forceuid,gid=502,forcegid,noperm ://marmotte.autodesk.com/ENGOPS_BUILDS
ecplugins -fstype=cifs,guest,uid=502,forceuid,gid=502,forcegid,_netdev,ro ://ecserver.autodesk.com/ecplugins
caribou -fstype=cifs,credentials=/root/cred,uid=502,forceuid,gid=502,forcegid,noperm ://caribou.autodesk.com/ENGOPS_BUILDS
```

- Enable `autofs` service
- Restart `autofs` service
- Wait until `/local/net/meci_maya` directory is available. 
- To enable GPU on CentOS 7.3, [this workaround has to be performed](https://wiki.autodesk.com/pages/viewpage.action?pageId=399499057). Do not do this on any other version. We do this on every CentOS 7.3 system, even the ones without GPUs.
  - Edit `/opt/ecs/bin/params`, add/modify this line `GPU_VERSION=8`
  - Edit `/etc/yum.repos.d/CentOS-Base.repo`
    - Comment out all mirrorlists: `#mirrorlist`
    - Change all baseurl: `baseurl=http://vault.centos.org/7.3.1611`
  - Run Yum clean all command `sudo yum clean all` 
  - Run Yum update `sudo yum update`
  - Reboot
  - Remove old kernel packages. The latest is kept and the command fails, as expected.: `sudo yum remove kernel`
- Install git-adsk `https://pages.git.autodesk.com/github-solutions/`
- Install mastering requirements: `sudo yum install rpm-build PyYAML`
- Make sure the system can connect one of these directories:
  - `/local/net/caribou/me_builds`
  - `/local/net/marmotte/me_builds`
- Edit `~/.rpmacros`, make sure this line exists: `%_tmppath %{_topdir}/tmp`
- Create a directory owned by administrator: `/local/opt/StoreBoxClient`
  - Extract the contents into the directory: `https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/StoreBox/StoreBoxClientLinux.zip`
  - There should be two files: `post2storebox.pl` and `uploader.pl`
- Install Electric Commander requirements `sudo yum install libstdc++.x86_64 libstdc++.i686`
- [Download Electric Commander agent installer](https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/ElectricCommander/ElectricFlow-8.0.3.125753/Linux/ElectricFlowAgent-x64-8.0.3.125753)
  - Run with options: `./ElectricFlowAgent-x64-8.0.3.125753 --mode silent --installAgent --agentPort 7800 --unixAgentUser administrator --unixAgentGroup administrator --remoteServer ecserver.autodesk.com`
  - Modify `/opt/electriccloud/electriccommander/conf/agent/wrapper.conf`
    - `wrapper.java.initmemory=1024`
    - `wrapper.java.maxmemory=2048`
- Optionally install java for Jenkins agent connection: `sudo yum install java-1.8.0-openjdk`
- Install Devtoolset-6
  - `sudo yum install centos-release-scl`
  - `sudo yum install devtoolset-6`
- Reboot
- Attach GPU in ECS Vapor if required

### Mac - OSX 10.14.3

#### MacPro

#### Ansible Setup

MacPro and Mac VM Maya build systems are configured via Ansible. The Ansible playbook installs all software required for PF, CI, DI and Mastering. Details can be found in the [Ansible Readme](https://git.autodesk.com/maya3d/maya-pipeline/blob/master/ansible/Readme.md)

#### Manual Setup

Note that the Ansible playbook [maya2020_build_macos_10_14.yml](https://git.autodesk.com/maya3d/maya-pipeline/blob/master/ansible/maya2020_build_macos_10_14.yml) is the original source for these instructions. There are more settings and configuration items in the Ansible playbook, but these should allow a build to run.

- Connect via SSH
  - Login to system and check that the `Administrator` user exists, uses the default password, and is an `admin` user.
  - Partition, mount and format the data drive.

```bash
whoami
sudo visudo
  ##
  ## User privilege specification
  ##
  root ALL=(ALL) ALL
  %admin  ALL=(ALL) ALL
  administrator ALL=(ALL) NOPASSWD: ALL
  Administrator ALL=(ALL) NOPASSWD: ALL
```

- Enable VNC and set the password

```bash
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -configure -allowAccessFor -allUsers -configure -clientopts -setvnclegacy -vnclegacy yes -configure -privs -all -configure -clientopts -setvncpw -vncpw "<admin password>" -restart -agent
```

- Set Autologon option on

```bash
sudo defaults write /library/preferences/com.apple.loginwindow autoLoginUser administrator
```

- Add the `ll` terminal alias

```bash
sudo vim /etc/bashrc
  alias ll="ls -laph"
```

- Add the `locate` command. This will run in the background and not be available until it finishes it's first index.

```bash
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist
```

- Make mount dirs

```bash
sudo mkdir /local
sudo chown administrator:staff /local
chmod -R 755 /local

sudo mkdir -p /local/net
sudo chown root:wheel /local/net
chmod -R 755 /local/net

mkdir -p /local/S
chown administrator:staff /local/S
chmod -R 755 /local/S
```

- Do the next parts in the Downloads directory

```bash
cd ~/Downloads
```

- Modify fstab to mount drives. Make sure an existing fstab does not exist. Modify the new fstab to mount any ECS data drives correctly.

```bash
curl -u user:pass -O https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/Mac/Misc/fstab.zip
unzip -P "<administrator password>" fstab.zip
sudo cp fstab /etc/fstab
sudo chown root:wheel /etc/fstab
sudo chmod 644 /etc/fstab
# If using an ECS VM with a data drive, uncomment and modify the drive line to mount the correct volumne
sudo vim /etc/fstab
sudo automount -vc
```

- Import the signing cert

```bash
curl -u user:pass -O https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/Mac/Misc/misc_2018_09_04.zip
unzip -P "<administrator password>" misc_2018_09_04.zip
security unlock-keychain -p "<administrator password>" login.keychain
security import ./CertificatesForOps.p12 -P <cert password> -k login.keychain -A
security set-key-partition-list -k "<administrator password>" -S apple-tool:,apple:,codesign: -s /Users/Administrator/Library/Keychains/login.keychain-db
```

- Install Command Line Tools 
  - Do this before Git ADSK. The install.sh script will install Command Line Tools otherwise.

```bash
curl -u user:pass -O https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/Mac/command_line_tools/Command_Line_Tools_macOS_10.14_for_Xcode_10.1.dmg
sudo hdiutil attach Command_Line_Tools_macOS_10.14_for_Xcode_10.1.dmg
sudo installer -pkg /Volumes/Command\ Line\ Developer\ Tools/Command\ Line\ Tools\ \(macOS\ High\ Sierra\ version\ 10.14\).pkg -target /
sudo hdiutil detach /Volumes/Command\ Line\ Developer\ Tools/
```

- Install Git ADSK
  - Note this step will prompt for credentials. Use `svc_p_mescm`
  - This step installs git into `/usr/local/bin/git`
  - The system may also have a default git in `/usr/bin/git`
  - Git ADSK will be availabe to both versions, but we want to use the one in `/usr/local/bin/git`

```bash
curl -u user:pass -O https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/Git/ADSK/v2.0.6/install.sh
chmod 755 install.sh
./install.sh
git adsk setup
git adsk setup maya
git adsk install-apps
git lfs install
```

- Make sure the new git is first in the path.

```bash
which git
git --version
echo $PATH
sudo vim /etc/paths
    /usr/local/bin
    /bin
    /usr/sbin
    /sbin
```

- Install Xcode
  - Do this after installing Git ADSK. This step uses brew.

```bash
curl -u user:pass -O https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/Mac/xcode/10.1/Xcode_10.1.xip
mkdir xcode
mv Xcode_10.1.xip xcode/
cd xcode
# https://github.com/thii/Unxip
brew install thii/unxip/unxip
unxip Xcode_10.1.xip
sudo mv Xcode.app /Applications/
cd ~/Downloads
```

- Configure Xcode 10.1

```bash
sudo /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -license accept
sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/MobileDevice.pkg -target /
sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/MobileDeviceDevelopment.pkg -target /
sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/XcodeSystemResources.pkg -target /
```

- Install Python 2.7.15
  - Note that the `Update Shell Profile.command` will fail when logging in via SSH. Login via VNC and run from a local terminal.

```bash
curl -u user:pass -O https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/Python/2.7.15/Mac/python-2.7.15-macosx10.9.pkg
sudo installer -pkg python-2.7.15-macosx10.9.pkg -target /
sudo /Applications/Python\ 2.7/Update\ Shell\ Profile.command
sudo /Applications/Python\ 2.7/Install\ Certificates.command
pip install PyYAML pyobjc
```

- Install StoreBoxClient scripts

```bash
curl -u user:pass -O https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/StoreBox/StoreBoxClientLinux.zip
mkdir -p /local/opt/StoreBoxClient
unzip StoreBoxClientLinux.zip -d /local/opt/StoreBoxClient/
```

- Install Electric Commander agent

```bash
curl -u user:pass -O https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/ElectricCommander/ElectricFlow-8.0.3.125753/mac/commander_i386_Darwin.bin
vim config
    EC_INSTALL_TYPE=agent
    DESTINATION_DIR=/opt
    AGENT_USER_TO_RUN_AS=administrator
    AGENT_GROUP_TO_RUN_AS=staff
    EC_AGENT_PORT=7800
chmod 755 commander_i386_Darwin.bin
sudo ./commander_i386_Darwin.bin -q -f --config config
cp /usr/local/bin/git /opt/electriccloud/electriccommander/bin
cp /usr/local/bin/git-lfs /opt/electriccloud/electriccommander/bin
```

- Install BBEdit

```bash
curl -u user:pass -O https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/BBEdit/BBEdit_12.1.5.dmg
sudo hdiutil attach BBEdit_12.1.5.dmg
cp -R /Volumes/BBEdit\ 12.1.5/BBEdit.app /Applications/
sudo hdiutil detach /Volumes/BBEdit\ 12.1.5
```

- Install Dock Utility
  - https://github.com/kcrawford/dockutil
  - This utility allow us to manipulate shortcuts in the Dock

```bash  
curl -u user:pass -O https://art-bobcat.autodesk.com:443/artifactory/team-maya-generic/BuildTools/Mac/docutil/dockutil-2.0.5.pkg
sudo installer -pkg dockutil-2.0.5.pkg -target /
```

- Remove Shortcuts from the Dock
  - These command don't seem to have the same problems as the --add command

```bash
dockutil --remove Books
dockutil --remove Calendar
dockutil --remove Contacts
dockutil --remove FaceTime
dockutil --remove iBooks
dockutil --remove iTunes
dockutil --remove Keynote
dockutil --remove Mail
dockutil --remove Maps
dockutil --remove Messages
dockutil --remove News
dockutil --remove Notes
dockutil --remove Numbers
dockutil --remove Pages
dockutil --remove "Photo Booth"
dockutil --remove Photos
dockutil --remove Reminders
dockutil --remove Siri
dockutil --remove Terminal
```

- Add Shortcuts to the Dock
  - These commands can fail when they are run in a script or too close together. Double-check the shortcuts

```bash
dockutil --add /Applications/Utilities/Terminal.app
dockutil --add /Applications/BBEdit.app
dockutil --add /Applications/Xcode.app
```

- Cleanup
```bash
rm -rf ~/Downloads/*
```

- Reboot

```bash
sudo reboot
```
