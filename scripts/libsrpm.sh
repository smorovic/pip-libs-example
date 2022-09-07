#!/bin/bash -e

# set the RPM build architecture
BUILD_ARCH=x86_64
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RHEL_MAJOR=`cat /etc/redhat-release | cut -d' ' -f4 | cut -d'.' -f1`

echo "Checking if necessary build packages are installed..."
if [ "$RHEL_MAJOR" = "7" ]; then
  if ! rpm -q python3-devel libcap-devel rpm-build python36-six python3-setuptools python3-pip python36-virtualenv; then
    echo "\nPlease install missing packages.";
    exit 1;
  fi
else
  if ! rpm -q gcc redhat-rpm-config python36-devel libcap-devel rpm-build zlib-devel python3-six python3-setuptools python3-pip python3-virtualenv; then
    echo "\nPlease install missing packages.";
    exit 1;
  fi
fi
echo "...Build dependencies OK"
echo ""

cd $SCRIPTDIR/..
BASEDIR=$PWD

# create a build area

echo "removing old build area"
rm -rf /tmp/libs-build-tmp-area
echo "creating new build area"
mkdir  /tmp/libs-build-tmp-area
cd     /tmp/libs-build-tmp-area
pwd
TOPDIR=$PWD
cd $TOPDIR

if ! [ -z $1 ]; then
  rl=$1
  if ! [ -f /usr/bin/$rl ]; then
    echo "not found: $1"
    exit 1
  fi
else
  #default
  rl="python3.8"
fi 

pyexec=$rl
python_dir=$rl

if [ "$RHEL_MAJOR" = "7" ]; then
  pythonlink=$rl
  while ! [ "$pythonlink" = "" ]
  do
    pythonlinklast=$pythonlink
    readlink /usr/bin/$pythonlink > pytmp | true
    pythonlink=`cat pytmp`
    rm -rf pytmp
    #echo "running readlink /usr/bin/$pythonlinklast --> /usr/bin/$pythonlink"
  done
  pythonlinklast=`basename $pythonlinklast`
  echo "will compile packages for: $pythonlinklast"
  pyexec=$pythonlinklast
  python_dir=$pythonlinklast
fi

python_version=${python_dir:6}



pkgnamepre="mylibs"
pkgname=""
libprefix="python3"
pkgobsoletes=""

if [ $python_dir = "python3.6" ]; then
  if [ "$RHEL_MAJOR" = "7" ]; then
    libprefix="python36"
    pypkgprefix="python3"

    if ! rpm -q python3 python3-devel; then
      echo "Please install python3, python3-devel"
    fi

  elif [ "$RHEL_MAJOR" = "8" ]; then
    libprefix="python36"
    pypkgprefix="python36"
    if ! rpm -q python36 python36-devel; then
      echo "Please install python36, python36-devel"
    fi
  else
    echo "No compatible python version selected"
  fi

elif [ $python_dir = "python3.8" ]; then

  pypkgprefix="python38"
  if [ "$RHEL_MAJOR" = "7" ]; then
    echo "python 3.8 unavailable on CC7"
    exit 1
  fi
  if ! rpm -q python38 python38-devel; then
    echo "Please install python38, python38-devel"
  fi
  libprefix="python38"

else
  echo "No compatible python version selected"
  exit 0
fi
pkgname="${pkgnamepre}-${libprefix}"

echo "Building and moving files to their destination"

rm -rf venv

virtualenv-3 -p ${pyexec} venv
source venv/bin/activate

#pip3 install requests==2.25.0
pip3 install connexion==2.14.1

#pip3 install -r requirements.txt



#set up custom site-packages
mkdir -p opt/${pkgnamepre}/${python_dir}/
cp -R venv/lib/${python_dir}/site-packages ${TOPDIR}/opt/${pkgnamepre}/${python_dir}/site-packages

rm -rf venv usr
ls

echo "TOPDIR $TOPDIR `pwd`"
# we are done here, write the specs and make the fu***** rpm
cat > hltd-libs.spec <<EOF
Name: ${pkgname}
Version: 1.0.0
Release: 0%{?dist}
Summary: hlt daemon libraried ${python_dir}
License: lgpl
Group: CMS SUB
Packager: person
Source: none
%define _tmppath $TOPDIR/libs-build
BuildRoot: %{_tmppath}
BuildArch: $BUILD_ARCH
AutoReqProv: no
Requires:${pypkgprefix}, ${pypkgprefix}-libs

%global __python %{__${pythonver}}

%description
extra python libraries

%prep

%build

%install
rm -rf \$RPM_BUILD_ROOT
mkdir -p \$RPM_BUILD_ROOT
tar -C $TOPDIR -c opt | tar -xC \$RPM_BUILD_ROOT

%post

%files
%defattr(-, root, root, -)
/opt/${pkgnamepre}/${python_dir}/site-packages

EOF
mkdir -p RPMBUILD/{RPMS/{noarch},SPECS,BUILD,SOURCES,SRPMS}
rpmbuild --define "_topdir `pwd`/RPMBUILD" -bb hltd-libs.spec

echo "Produced RPM files located here /tmp/libs-build-tmp-area/RPMBUILD/RPMS/x86_64/ :"
ls -la /tmp/libs-build-tmp-area/RPMBUILD/RPMS/x86_64/
