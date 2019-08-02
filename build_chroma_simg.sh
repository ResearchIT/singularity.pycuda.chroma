#!/bin/bash

# build a base container with required packages installed by yum
sudo singularity build -s singularity-centos7.6-cuda9.1-x11-chroma.sandbox ./singularity-centos7.6-cuda9.1-x11.def

# install python packages
sudo singularity exec -w -B $PWB:/mnt singularity-centos7.6-cuda9.1-x11-chroma.sandbox bash /mnt/post_install_python_packages_chroma.sh

# convert the sandbox to image file.
sudo singularity build chroma.simg singularity-centos7.6-cuda9.1-x11-chroma.sandbox


