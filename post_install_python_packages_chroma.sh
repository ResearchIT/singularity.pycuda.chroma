#!/bin/bash

# Install legacy pycuda application chroma(https://chroma.bitbucket.io)
# Ref: Chroma Common Installation Guide: https://chroma.bitbucket.io/install/overview.html#common-installation-guide.
#
# The guide suggested to use the shrinkwrap package to install ALL legacy chroma-dependent packages, 
# but we break the installation into three steps, and test installation in each step. and use pip to resolve the package dependency. 
# we will use chroma-deps to do the final dependency check-up before installing chroma. 
# 1. Install legacy dependent packages from source provided by chroma repo.
# 2. pip install legacy pycuda and pygame, and test.
# 3. pip install other dependent packages, and check chroma-deps
# 4. install chroma from source.
# 5. patch grid.py to fix the error when calling numpy. 
#
#% post

# create virtualenv chroma_env in /opt for installing chroma-related packages.
pip install --upgrade pip
pip install virtualenv 

cd /opt
virtualenv chroma_env
source /opt/chroma_env/bin/activate

# Follow Installation Guide to create ~/.aksetup-default.py
echo -e "import os\nvirtual_env = os.environ['VIRTUAL_ENV']\nBOOST_INC_DIR = [os.path.join(virtual_env, 'include')]\nBOOST_LIB_DIR = [os.path.join(virtual_env, 'lib')]\nBOOST_PYTHON_LIBNAME = ['boost_python']" > ~/.aksetup-defaults.py
export PIP_EXTRA_INDEX_URL=https://chroma.bitbucket.io/chroma_pkgs/

# Iinstall dependent legacy packages from source provided in https://chroma.bitbucket.io/chroma_pkgs/
# boost( 1.51.0, 1.65.1), geant4(4.9.5.p01, 4.9.5.post1)
# g4py_chroma_4.9.5_post1, root(5.34.01, 5.34.36.11, 5.34.36)

mkdir -p /opt/chroma_env/env.d
mkdir -p /opt/chroma_env/src
m_src_dir=/opt/chroma_env/src

cd $m_src_dir
wget  https://chroma.bitbucket.io/chroma_pkgs/boost/boost-1.65.1.tar.gz
tar zxvf boost-1.65.1.tar.gz
cd ./boost-1.65.1
python setup.py install
export BOOST_LIB_DIR=/opt/chroma_env/lib
export BOOST_INC_DIR=/opt/chroma_env/include/boost
export BOOST_PYTHON_LIBNAME=boost_python


cd $m_src_dir
wget https://chroma.bitbucket.io/chroma_pkgs/geant4/geant4-4.9.5.post1.tar.gz
tar zxvf geant4-4.9.5.post1.tar.gz
cd ./geant4-4.9.5.post1
python setup.py install
source /opt/chroma_env/bin/geant4.sh

cd $m_src_dir
wget https://chroma.bitbucket.io/chroma_pkgs/g4py-chroma/g4py-chroma-4.9.5.post1.tar.gz
tar zxvf g4py-chroma-4.9.5.post1.tar.gz
cd ./g4py-chroma-4.9.5.post1
python setup.py install

cd $m_src_dir
wget https://chroma.bitbucket.io/chroma_pkgs/root/root-5.34.36.tar.gz
tar zxvf root-5.34.36.tar.gz
cd ./root-5.34.36
python setup.py install
source /opt/chroma_env/env.d/root.sh

# install pycuda and pygame first with the selected versions
# let pip resolve numpy's version while installing pycuda==2018.1
pip install pycuda==2018.1  
pip install pygame==1.9.4

# Now let pip resove the versions of other required packages listed in chroma setup.py
# setup_requires = ['pyublas']
# install_requires = ['uncertainties','pyzmq-static','spnav', 'pycuda', 
#                     'numpy>=1.6', 'pygame', 'nose', 'sphinx', 'unittest2'],
pip install pyublas uncertainties pyzmq-static spnav nose sphinx unittest2 shrinkwrap

# check chroma-dependency before installing chroma
pip install chroma-deps

# Install chroma
source $VIRTUAL_ENV/bin/activate
cd $VIRTUAL_ENV/src
hg clone https://bitbucket.org/chroma/chroma
cd chroma
python setup.py develop

# grid.py.patch should be in /mnt as -B $PWD:/mnt.
f_patch=""
if test -f "/mnt/grid.py.patch"; then
  f_patch="/mnt/grid.py.patch"
elif test -f "$HOME/grid.py.patch"; then
  f_patch="$HOME/grid.py.patch"
fi

# patch grid.py
if test -f "$f_patch"; then
  cd  $VIRTUAL_ENV/src/chroma/chroma/bvh
  echo "patch grid.py $f_patch"
  patch grid.py $f_patch
fi


# Write all env in to /.singularity.d/env/999-rit.sh
m_env_file=/.singularity.d/env/999-rit.sh
cat <<EOT >$m_env_file
#!/bin/bash
export SDL_AUDIODRIVER=disk
export VIRTUAL_ENV=/opt/chroma_env
export BOOST_LIB_DIR=/opt/chroma_env/lib
export BOOST_INC_DIR=/opt/chroma_env/include/boost
export BOOST_PYTHON_LIBNAME=boost_python

source /opt/chroma_env/bin/geant4.sh
source /opt/chroma_env/env.d/root.sh
source /opt/chroma_env/bin/activate
EOT
chmod a+xr $m_env_file
