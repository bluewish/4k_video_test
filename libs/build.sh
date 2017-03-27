#!/bin/bash

TOP_DIR=$(dirname "$(readlink -f "$0")")

source ${TOP_DIR}/env.sh
echo "Build libva ..."
cd ${TOP_DIR}/libva
./autogen.sh --prefix=$VAAPI_PREFIX
make -j8
make install

echo "Build intel-driver ..."
cd ${TOP_DIR}/intel-vaapi-driver
./autogen.sh --prefix=$VAAPI_PREFIX
make -j8
make install

echo "Build ffmpeg ..."
cd ${TOP_DIR}/ffmpeg
./configure --prefix=\$VAAPI_PREFIX --enable-avformat
make -j8 
make install

echo "Build libyami ..."
cd ${TOP_DIR}/libyami
./autogen.sh --prefix=$VAAPI_PREFIX
make -j8
make install

echo "Build libyami-utils ..."
cd ${TOP_DIR}/libyami-utils
./autogen.sh --prefix=$VAAPI_PREFIX
make -j8
make install