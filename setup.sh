#!/bin/bash

APT_UPDATE="sudo apt-get update"
APT_INSTALL="sudo apt-get install -y"
PIP_INSTALL="sudo pip install"

function install_base_packages()
{
  $APT_UPDATE
  $APT_INSATLL ssh build-essential cmake git unzip
  $APT_INSTALL ffmpeg libopencv-dev libgtk-3-dev python-numpy python3-numpy libdc1394-22 libdc1394-22-dev libjpeg-dev libpng12-dev
  $APT_INSTALL libtiff5-dev libjasper-dev libavcodec-dev libavformat-dev libswscale-dev libxine2-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libv4l-dev libtbb-dev qtbase5-dev libfaac-dev libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev libvorbis-dev libxvidcore-dev x264 v4l-utils
  $APT_INSTALL libopencv-dev
  $APT_INSTALL python-pip

  return 0
}

function install_cuda()
{
  cuda_url=https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda-repo-ubuntu1604-8-0-local-ga2_8.0.61-1_amd64-deb

  wget $cuda_url -o cuda.deb
  sudo dpkg -i cuda.deb
  $APT_UPDATE
  $APT_INSTALL install cuda

  return 0
}

function install_cudnn()
{
  # get cudnn archive from https://developer.nvidia.com/cudnn

  tar xzf cudnn-8.0-linux-x64-v5.1.tgz
  sudo cp -rf cuda/lib64/libcudnn* /usr/local/cuda/lib64/
  sudo cp -rf cuda/include/cudnn.h /usr/local/cuda/include/
  return 0
}

function install_caffe()
{
  $APT_UPDATE
  $APT_INSATLL build-essential cmake git pkg-config
  $APT_INSTALL libprotobuf-dev libleveldb-dev libsnappy-dev libhdf5-serial-dev protobuf-compiler
  $APT_INSTALL libatlas-base-dev
  $APT_INSTALL --no-install-recommends libboost-all-dev
  $APT_INSTALL libgflags-dev libgoogle-glog-dev liblmdb-dev
  $APT_INSTALL python-pip
  $APT_INSTALL python-dev python-pip python-numpy python-skimage gfortran
  git clone https://github.com/BVLC/caffe.git
  sed -e "s/# USE_CUDNN/USE_CUDNN/" caffe/Makefile.config.example > caffe/Makefile.config
  ( \
    cd caffe/build \
    cmake .. \
    make -j all \
    $PIP_INSTALL -r ../python/requirements.txt \
    make pycaffe \
  )
  echo 'export PYTHONPATH=`pwd`/..//python/:$PYTHONPATH' >> ~/.bashrc

  return 0
}

function install_tensorflow()
{
  $APT_UPDATE
  $APT_INSTALL libcupti-dev
  $PIP_INSTALL tensorflow-gpu

  return 0
}

function install_chainer()
{
  $APT_UPDATE
  CUDA_PATH=/usr/local/cuda $PIP_INSTALL chainer

  return 0
}


install_base_packages
install_cuda
install_cudnn
install_chainer
install_tensorflow
install_caffe


exit 0
