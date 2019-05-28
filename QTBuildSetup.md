# Qt5 5.12.4 Build instructions

This document provides instructions for building Qt5 (5.12.4) including setting up build machines, building Qt5 via Jenkins and localtion of build artifacts.

## Links

[Building Qt5 from GIT](https://wiki.qt.io/Building_Qt_5_from_Git)


## Machine Setup

Since we didn't have time to create a separate Qt5 Ansible playbook where it will install only depedencies required for building Qt5 on a clean OS, we'll use Ansible Maya playbook instead [Maya 2020 Build Machines](./BuildMachineSetup.md) which may install more packages than we actually need but may also miss few dependecy packages that are required for Qt5 build.  Below are few additional packages that will need to install on specific OS.

### Windows 10

#### Install Ruby (QT)

- Download Ruby version 1.9.3 or higher from [here](http://rubyinstaller.org)
- Install Ruby using default selections
- From command line type `ruby -v` to make sure correct version is properly installed.

### Linux - CentOS 7.3

#### Install libxxkbcommon-devel (QT)

- sudo yum install libxkbcommon-devel

## Build

### Jenkins

- Login this [QT5.12.4 build](https://master-11.jenkins.autodesk.com/job/Maya-Qt5/job/qt5/job/adsk-contrib-maya-v5.12.4/)
- Select 'Build with Parameters' where you can specify the commit hash you want build or leave it blank which will build from the HEAD commit.

## Build artifacts 

Build artifacts will be uploaded [here](
https://art-bobcat.autodesk.com:443/artifactory/oss-stg-generic/Qt/5.12.4/Maya)
