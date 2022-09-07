pip-libs-example
====

Building:
On a CERN CentOS 7.6/7.8 build machine prerequisite packages need to be installed for python 3.6 build:
```
yum install -y python3-devel rpm-build python3-setuptools python3-pip python36-virtualenv
```

On a RHEL8 build machine prerequisite packages need to be installed (python3.8):
```
yum install -y gcc redhat-rpm-config python3-devel libcap-devel rpm-build python3-setuptools python38-pip python38-virtualenv
```


building RPM:
```
scripts/libsrpm.sh
```

Note: libraries are in a special directory
```
/opt/${pkgnamepre}/${libprefix}/site-packages
```

Appending to python path inside library (or extend PYTHON3PATH environment) - example:
```
special_dir="/opt/mylibs/python3.8/site-packages"
import sys
sys.path.append(special_dir)
```
