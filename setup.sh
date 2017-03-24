#!/bin/bash
# @(#) This is xxxxxxxxxxxx.

# Checks unnecessary paramters
set -ue

# GLOBAL CONSTANTS
# ================
readonly UPDATE_APT="sudo apt-get update"
readonly INSTALL_APT="sudo apt-get install -y"
readonly INSTALL_PIP="sudo pip install --upgrade"
readonly GIT_CLONE="git clone --depth 1"

# GLOBAL VARIABLES
# ================
USE_GPU=1
USE_TESLAP100=0

# USAGE
# =====
function usage()
{
  cat <<EOF
Usage:
  $0

Description:
  This is setup script for deep learning PC.

Options:
  -h, --help    : Print usage
  --no-gpu      : without GPU support
  --tesla-p100  : with GPU as TESLA P100
EOF
  return 0
}

# FUNCTIONS
# =========
function install_base_packages()
{
  $UPDATE_APT
  $INSTALL_APT \
    ssh build-essential cmake git unzip pkg-config libopencv-dev \
    python-pip libopencv-dev libgtk-3-dev python-numpy python-pytest \
    python3-numpy libdc1394-22 libdc1394-22-dev libjpeg-dev \
    libpng12-dev libtiff5-dev libjasper-dev libavcodec-dev \
    libavformat-dev libswscale-dev libxine2-dev libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev libv4l-dev libtbb-dev \
    qtbase5-dev libfaac-dev libmp3lame-dev libopencore-amrnb-dev \
    libopencore-amrwb-dev libtheora-dev libvorbis-dev libxvidcore-dev \
    x264 v4l-utils
    $INSTALL_PIP numpy

  return 0
}

function install_tesla_driver()
{
  local drv_url=http://jp.download.nvidia.com/XFree86/Linux-x86_64/375.39/NVIDIA-Linux-x86_64-375.39.run
  wget $drv_url -O nvidia-driver.run
  chmod a+x nvidia-driver.run
  sudo ./nvidia-driver.run

  return 0
}

function install_cuda()
{
  # checks https://developer.nvidia.com/cuda-downloads
  local cuda_url=https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda-repo-ubuntu1604-8-0-local-ga2_8.0.61-1_amd64-deb

  wget $cuda_url -O cuda.deb
  sudo dpkg -i cuda.deb
  $UPDATE_APT
  $INSTALL_APT install cuda

  return 0
}

function install_cudnn()
{
  # get cudnn archive from https://developer.nvidia.com/cudnn
  local cudnn_archive=cudnn-8.0-linux-x64-v5.1.tgz

  tar xzf $cudnn_archive
  sudo cp -rf cuda/lib64/libcudnn* /usr/local/cuda/lib64/
  sudo cp -rf cuda/include/cudnn.h /usr/local/cuda/include/

  return 0
}

function install_caffe()
{
  $UPDATE_APT
  $INSTALL_APT libprotobuf-dev libleveldb-dev libsnappy-dev \
    libhdf5-serial-dev protobuf-compiler libatlas-base-dev \
    libgflags-dev libgoogle-glog-dev liblmdb-dev python-dev \
    python-skimage gfortran libboost-python-dev
  $INSTALL_APT --no-install-recommends libboost-all-dev

  rm -rf caffe
  $GIT_CLONE https://github.com/BVLC/caffe

  if [[ $USE_GPU -eq 1 ]]; then
    sed -e "s/# USE_CUDNN/USE_CUDNN/" caffe/Makefile.config.example > caffe/Makefile.config
    ( \
      mkdir -p caffe/build && cd caffe/build && \
      cmake .. && make -j all && \
      $INSTALL_PIP -r ../python/requirements.txt && make pycaffe \
    )
  else
    cp caffe/Makefile.config.example caffe/Makefile.config
    ( \
      mkdir -p caffe/build && cd caffe/build && \
      cmake -DCPU_ONLY=ON .. && make -j all && \
      $INSTALL_PIP -r ../python/requirements.txt && make pycaffe \
    )
  fi

  echo 'export PYTHONPATH='`pwd`'/../python/:$PYTHONPATH' >> ~/.bashrc

  return 0
}

function install_tensorflow()
{
  if [[ $USE_GPU -eq 1 ]]; then
    $UPDATE_APT
    $INSTALL_APT libcupti-dev
    $INSTALL_PIP tensorflow-gpu
  else
    $INSTALL_PIP tensorflow
  fi

  return 0
}

function install_chainer()
{
  if [[ $USE_GPU -eq 1 ]]; then
    CUDA_PATH=/usr/local/cuda $INSTALL_PIP chainer
    $INSTALL_PIP chainer-cuda-deps
  else
    $INSTALL_PIP chainer
  fi

  return 0
}

function run_chainer_example_mnist()
{
  rm -rf chainer
  $GIT_CLONE https://github.com/pfnet/chainer
  (cd chainer/examples/mnist && python train_mnist.py)

  return 0
}


# MAIN ROUTINE
# ============

while (( $# > 0 ))
do
  case "$1" in
    '-h'|'--help' )
      usage
      exit 0
      ;;
    '--no-gpu' )
      echo "USE_GPU=0"
      USE_GPU=0
      ;;
     '--with-tesla-p100' )
      echo "USE_TESLAP100=1"
      USE_TESLAP100=1
      ;;
    *)
      echo "[ERROR] invalid option $1 !!"
      ;;
  esac
  shift
done

install_base_packages

if [[ $USE_GPU -eq 1 ]]; then
  install_cuda
  install_cudnn
  if [[ $USE_TESLAP100 -eq 1 ]]; then
    install_tesla_driver
  fi
fi

install_chainer
install_tensorflow
install_caffe

run_chainer_example_mnist

exit 0
