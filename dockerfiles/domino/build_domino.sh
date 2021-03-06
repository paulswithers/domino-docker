#!/bin/bash
############################################################################
# (C) Copyright IBM Corporation 2015, 2019                                 #
#                                                                          #
# Licensed under the Apache License, Version 2.0 (the "License");          #
# you may not use this file except in compliance with the License.         #
# You may obtain a copy of the License at                                  #
#                                                                          #
#      http://www.apache.org/licenses/LICENSE-2.0                          #
#                                                                          #
# Unless required by applicable law or agreed to in writing, software      #
# distributed under the License is distributed on an "AS IS" BASIS,        #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. #
# See the License for the specific language governing permissions and      #
# limitations under the License.                                           #
#                                                                          #
############################################################################

# Domino Docker Build Script
# Usage  : ./build.sh <URL for download repository>
# Example: ./build-image.sh http://192.168.1.1

# ---------------------------------------------------
# Optional Parameters in the following order
# ---------------------------------------------------
# Product Version
# Product Fixpack
# Product InterimsFix
# (use "" for no Fixpack)
# ---------------------------------------------------

SCRIPT_NAME=$0
DOWNLOAD_FROM=$1

# Select product to install (by default name is derived from filename)
#PROD_NAME=domino
#PROD_NAME=domino-ce

#DOCKER_TZ=Europe/Berlin

# Specify Version to install
# Can be overwritten on command-line

PROD_VER=10.0.1
PROD_FP=FP1
#PROD_HF=IF1
#PROD_HF=HF123

# ---------------------------------------------------

LARCH=`uname`

# If Timezone is not set use host's timezone

if [ -z $DOCKER_TZ ]; then

  if [ $LARCH = "Linux" ]; then
    DOCKER_TZ=$(readlink /etc/localtime | awk -F'/usr/share/zoneinfo/' '{print $2}')
  elif [ $LARCH = "Darwin" ]; then
    DOCKER_TZ=$(readlink /etc/localtime | awk -F'/usr/share/zoneinfo/' '{print $2}')
  else
    DOCKER_TZ=""
  fi

  echo
  echo "Using OS Timezone : [$DOCKER_TZ]"
  echo
else
  echo
  echo "Timezone configured: [$DOCKER_TZ]"
  echo
fi

# Get product name from file name
if [ -z $PROD_NAME ]; then
  PROD_NAME=`basename $0 | cut -f 2 -d"_" | cut -f 1 -d"."`
fi

CUSTOM_VER=`echo "$2" | awk '{print toupper($0)}'`
CUSTOM_FP=`echo "$3" | awk '{print toupper($0)}'`
CUSTOM_HF=`echo "$4" | awk '{print toupper($0)}'`

if [ ! -z "$CUSTOM_VER" ]; then
  PROD_VER=$CUSTOM_VER
  PROD_FP=$CUSTOM_FP
  PROD_HF=$CUSTOM_HF
fi

DOCKER_IMAGE_NAME="ibmcom/$PROD_NAME"
DOCKER_IMAGE_VERSION=$PROD_VER$PROD_FP$PROD_HF
DOCKER_FILE=dockerfile

# Latest Tag not set when specifying explicit version

if [ -z "$CUSTOM_VER" ]; then
  DOCKER_TAG_LATEST="$DOCKER_IMAGE_NAME:latest"
fi

usage ()
{
  echo
  echo "Usage: `basename $SCRIPT_NAME` <URL for download repository> [DOMINO-VERSION] [FP] [IF/HF] "
  echo
  return 0
}

print_runtime()
{
  echo
  
  # the following line does not work on OSX 
  # echo "Completed in" `date -d@$SECONDS -u +%T`
 
  hours=$((SECONDS / 3600))
  seconds=$((SECONDS % 3600))
  minutes=$((seconds / 60))
  seconds=$((seconds % 60))
  h=""; m=""; s=""
  if [ ! $hours =  "1" ] ; then h="s"; fi
  if [ ! $minutes =  "1" ] ; then m="s"; fi
  if [ ! $seconds =  "1" ] ; then s="s"; fi

  if [ ! $hours =  0 ] ; then echo "Completed in $hours hour$h, $minutes minute$m and $seconds second$s"
  elif [ ! $minutes = 0 ] ; then echo "Completed in $minutes minute$m and $seconds second$s"
  else echo "Completed in $seconds second$s"; fi
}

docker_build ()
{
  echo "Building Image : " $IMAGENAME
  
  if [ -z "$DOCKER_TAG_LATEST" ]; then
    DOCKER_IMAGE=$DOCKER_IMAGE_NAMEVERSION
    DOCKER_TAG_LATEST_CMD=""
  else
    DOCKER_IMAGE=$DOCKER_TAG_LATEST
    DOCKER_TAG_LATEST_CMD="-t $DOCKER_TAG_LATEST"
  fi

  # Get Build Time  
  BUILDTIME=`date +"%d.%m.%Y %H:%M:%S"`

  case "$PROD_NAME" in
    domino)
      DOCKER_DESCRIPTION="IBM Domino Enterprise Server"
      ;;

    domino-ce)
      DOCKER_DESCRIPTION="IBM Domino Community Edition Server"
      ;;

    *)
      echo "Unknown product [$PROD_NAME] - Terminating installation"
      exit 1
      ;;
  esac
  
  # Get build arguments
  DOCKER_IMAGE=$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_VERSION
  
  BUILD_ARG_PROD_NAME="--build-arg PROD_NAME=$PROD_NAME"
  BUILD_ARG_PROD_VER="--build-arg PROD_VER=$PROD_VER"
  BUILD_ARG_PROD_FP="--build-arg PROD_FP=$PROD_FP"
  BUILD_ARG_PROD_HF="--build-arg PROD_HF=$PROD_HF"
  BUILD_ARG_DOCKER_TZ="--build-arg DOCKER_TZ=$DOCKER_TZ"
  BUILD_ARG_DOWNLOAD_FROM="--build-arg DownloadFrom=$DOWNLOAD_FROM"

  # Switch to current directory and remember current directory
  pushd .
  CURRENT_DIR=`dirname $SCRIPT_NAME`
  cd $CURRENT_DIR

  # Finally build the image
  docker build --no-cache --label "DominoDocker.description"="$DOCKER_DESCRIPTION" \
    --label "DominoDocker.version"="$DOCKER_IMAGE_VERSION" \
    --label "DominoDocker.buildtime"="$BUILDTIME" \
    -t $DOCKER_IMAGE $DOCKER_TAG_LATEST_CMD \
    -f $DOCKER_FILE \
    $BUILD_ARG_DOWNLOAD_FROM $BUILD_ARG_PROD_NAME $BUILD_ARG_DOCKER_TZ \
    $BUILD_ARG_PROD_VER $BUILD_ARG_PROD_FP $BUILD_ARG_PROD_HF .

  popd
  echo
  # echo "Completed in" `date -d@$SECONDS -u +%T`
  # echo
  return 0
}

if [ -z "$DOWNLOAD_FROM" ]; then
  echo
  echo "No download location specified!"
  echo

  usage
  exit 0
fi

docker_build

echo
print_runtime
echo

exit 0

