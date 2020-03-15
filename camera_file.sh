#!/bin/bash


# Please read through this LICENSE and the rest of the script
# below.  The Notes section explains how to get rid of files that
# are either mistakes or you just don't want before you do any
# further processing/indexing of pictures.  The Local Configuration 
# items may need to be changed to suit your own local machine, 
# camera, backup device and desires.


# LICENSE:
#
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2020 Flowerbug <flowerbug@anthive.com>
#
#
# Copyright 2020 Flowerbug <flowerbug@anthive.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Notes:
#
# This script is designed to remove pictures from your camera
# and move them to your local machine.  If specified (below) it 
# will also make a backup copy to another device or directory.
#
# It is not meant to work until after it is configured because
# it is very unlikely you will have the exact same camera and
# directory structure or backup device that I have.
#
# The reason I need this script is because the camera resets the
# name/number of the files each time the pictures are removed so
# if I were to do a straight copy to only one directory it would
# mean I'm overwriting pictures in the destination folder.  This
# script then makes sure each time it is run and there are 
# pictures on the camera to move that the destination folder has 
# a unique name.
#
# If after you've run this script and looked at the pictures that
# were moved (and backed up if you asked for that to be done) and
# you don't want them it is a good idea to delete the pictures 
# and the last directory BEFORE YOU RUN THIS SCRIPT AGAIN.
# The reason for this is that this script uses the count of the 
# directories in the collection to determine the name of the 
# directory for the next run.  So you can conserve space and avoid 
# another directory by removing them.  Remember that if you do 
# this you should also remove the latest directory from your backup 
# or external device/directory.  I will probably make this an
# option in future versions of this script as my normal work flow
# of taking and then examining a batch of pictures to make sure 
# they are what I want before I do any further picture taking or
# editing.
#
# I plan on having another script for indexing the pictures and
# setting up the file names to make sure they are guaranteed to be
# unique before any further things happen to them (like using them
# for my website).  The current non-unique file names will be an
# issue for how I do things with my directories and organization 
# for the website - so I do need to figure this out before I get a
# lot more pictures taken and edited.


# Local Configuration
#
# The above CAMERA_NAME that is passed in via the command line
# will be shown when you plug in the camera and it gets automatically
# mounted.  gio is then used to unmount it later on because the
# automatic initial mount interferes with how I want to do things.
#
# If this script doesn't work for your camera, your local
# directory setups or your external device names the following
# should be changed as you'd like things to work.

# The prefix used in the front directory names in your collections.
DIR_PREFIX="D_"

# Used to pad the number and how many digits total
# if you think you'll ever have more than 10,000 directories in
# your collection you can increase these.
ZERO_PADDING="00000"
TOT_DIGITS="6"

# The prefix used in the front of the file names for the
# camera, if your camera uses a different prefix you will have to
# change this.  The below collection name is also based upon this
# prefix because I want the pictures organised by what camera I
# used.
CAMERA_PREFIX="DSC"

# base picture directory
PIC_BASE="${HOME}/pics"

# camera mount point
CAM_MOUNT="${PIC_BASE}/camera"

# directory on the camera (once it is mounted)
# you will need to examine the mount point after
# you have mounted the camera to discover the
# directory structure that fuser sets up to
# replace what is here.
CAM_DIR="$CAM_MOUNT/store_00010001/DCIM/100D3500"

# lsusb string to see if the camera is plugged in or not
# change this to match your camera.  plug it in and then
# run the lsusb command.
CAM_USB_STRING="ID 04b0:0445 Nikon Corp. NIKON DSC D3500"

# first place files are moved
STAGE="${PIC_BASE}/stage"

# the destination collection on the machine.
# remember to not delete the directories under
# this top directory as that determines the
# number of the next directory to make sure
# the name of the subdirectory and the extra 
# backup copy are uniquely named.
COLL="${PIC_BASE}/collection/${CAMERA_PREFIX}"

# if we are making a backup copy someplace else
# adjust the following for your local setup.
#
# change this to "No" if you don't want to make an
# extra backup to another device.  note this device is
# not automatically mounted or unmounted by this script
# so you have to mount and unmount it manually.  I 
# personally do not want devices turned on or mounted 
# unless I do that manually because most of the time I 
# don't use them, just once in a while.
EXTRA_BACKUP="Yes"
EXTRA_BASE="/mb/pictures"
EXTRA_COLL="${EXTRA_BASE}/collection/${CAMERA_PREFIX}"

#/etc/fstab or mount -l should tell you what to use
VOL_LABEL="VOL_01"  # use the label for the backup device


# End Local Configuration

#
# accepted options for the script
function usage_message () {
  echo -e "\n\nUsage: $0\n\n\
  [-h] | [--help]          this help\n\n\
  [-v] | [--verbose]       print out more as things happen\n\n\
  [-V] | [--Version]       give the version number\n\n\n
  CAMERA_NAME              the location given by gphoto2\n\n\n\
Example:\n\
$ camera_file.sh NIKON_NIKON_DSC_D3500_1234567890123\n\n\
" >&2
exit
}


# check options
help="0"
verbose="0"
version="0"
while test "$1" != "" ; do
  case "$1" in
    "-h")
        help="1"      # print some help text
        ;;
    "--help")
        help="1"      # print some help text
        ;;
    "-v")
        verbose="1"   # print what is happening
        ;;
    "--verbose")
        verbose="1"   # print what is happening
        ;;
    "-V")
        version="1"   # give the version
        ;;
    "--Version")
        version="1"   # give the version
        ;;
    *)
      leading_char=`echo $1 | cut -c 1`
      if test "${leading_char}" == "-" ; then
        echo -e "\nUnrecognized option $1 to $0\n\n"
        usage_message $0
      else
        CAMERA_NAME="$1"
      fi
        ;;
  esac
shift
done


# print the version if asked and then exit
if test "${version}" == "1" ; then
  echo "$0 Version 1.0.2"
  exit
fi


# print help if asked then exit
if test "${help}" == "1" ; then
  usage_message $0
fi


# save me a lot of typing
function printout ( ) {

  if test "${verbose}" == "1" ; then
    echo -e "$1"
  fi
  }

# camera fuser unmount
function camera_unmount ( ) {
  printout "Unmounting camera from ${CAM_MOUNT}\n"
  fusermount -u "${CAM_MOUNT}" >/dev/null 2>&1
# fusermount -u "${CAM_MOUNT}"
  umount "${CAM_MOUNT}" > /dev/null 2>&1
#  umount "${CAM_MOUNT}"
  sync
  }


# camera fuser mount
function camera_mount ( ) {
  printout "Mounting camera to ${CAM_MOUNT}\n"
  gphotofs ${CAM_MOUNT} >/dev/null 2>&1
#  gphotofs ${CAM_MOUNT}
  sync
  }


date


# first unmount the camera if it has already been mounted.
# on my system some automatic stuff is grabbing my camera 
# when I plug it in to the USB port and I haven't yet 
# figured out how to turn it off.
res_umount=`gio mount -u gphoto2://${CAMERA_NAME}/ 2>&1`
printout "\nStatus of gio unmount -->$?<--\n"
was_it_mounted=`echo ${res_umount} | grep "The specified location is not mounted" | wc -l`

# it's not really an error if it wasn't already mounted.
if test "${was_it_mounted}" == "0" ; then
  printout "First check for camera.  ${CAMERA_NAME} was mounted."
else
  printout "First check for camera.  ${CAMERA_NAME} was not mounted."
  printout "This may not be an error as some systems may not mount it.\n"
fi


# check to make sure all the needed directories exist and if they
# don't create them.


# the most basic one first
if test ! -d ${PIC_BASE} ; then
  echo -e "${PIC_BASE} doesn't exist.  Create it...\n"
  mkdir ${PIC_BASE}
fi

# the camera mount point
if test ! -d ${CAM_MOUNT} ; then
  echo -e "${CAM_MOUNT} doesn't exist.  Create it...\n"
  mkdir ${CAM_MOUNT}
fi

# ok let's see if we can mount the camera
# but first make sure it isn't already mounted (from a previous run perhaps).
camera_unmount
camera_mount
is_it_mounted=`lsusb | grep "${CAM_USB_STRING}" | wc -l`

# is it mounted
if test "${is_it_mounted}" == "1" ; then
  printout "${CAMERA_NAME} is mounted."
else
  echo -e "\n\nCamera ${CAMERA_NAME} was not mounted...  Exiting...\n\n"
  camera_unmount
  date
  exit
fi

# the picture stage directory
if test ! -d ${STAGE} ; then
  echo -e "${STAGE} doesn't exist.  Create it...\n"
  mkdir ${STAGE}
fi

# the picture collection directory
if test ! -d ${COLL} ; then
  echo -e "${COLL} doesn't exist.  Create it...\n"
  mkdir -p ${COLL}
fi


# only bother with the EXTRA stuff if wanted
# and the device is available.
if test "${EXTRA_BACKUP}" == "Yes" ; then

  # is ${VOL_01} mounted?
  #
  vl01=`mount -l | egrep "\[${VOL_LABEL}\]" | wc -l`

  if [ ${vl01} == "1" ]; then
    printout "Extra backup is requested and ${VOL_LABEL} is mounted.\n"
  else
    echo -e "Extra backup is requested but ${VOL_LABEL} is not mounted...  Exiting...\n\n"
    camera_unmount
    date
    exit
  fi

  # the backup device
  if test ! -d ${EXTRA_BASE} ; then
    echo -e "${EXTRA_BASE} doesn't exist.  create it...\n"
    mkdir ${EXTRA_BASE}
  fi
  
  # the backup collection
  if test ! -d ${EXTRA_COLL} ; then
    echo -e "${EXTRA_COLL} doesn't exist.  create it...\n"
    mkdir -p ${EXTRA_COLL}
  fi
  
fi


# make sure we have pictures to move and a place to move them
count_them=`find ${CAM_DIR} -type f -exec printf %.0s. {} + 2>/dev/null | wc -m`
printout "Files in camera ${count_them}\n"
if test ! -d "${STAGE}" ; then
  echo -e "Missing $STAGE directory...  Nothing done...\n\n"
  camera_unmount
  date
  exit
elif test "${count_them}" == "0" ; then
  echo -e "No files to move...  Nothing done...\n\n"
  camera_unmount
  date
  exit
else

  # make sure stage is empty
  count_stage=`find ${STAGE} -type f -exec printf %.0s. {} + 2>/dev/null | wc -m`
  printout "Files in stage ${count_stage}\n"
  if test "${count_stage}" != "0" ; then
    echo -e "$STAGE directory should be empty...  Nothing done...\n\n"
    camera_unmount
    date
    exit
  else
    echo -e "Moving ${CAM_DIR}'s ${count_stage} files to $STAGE.\n"
    mv ${CAM_DIR}/* ${STAGE}
  fi
fi

# ok, now we should have files to move from stage to the collection.

# the last file in the list will be used to set the date and time
# for the new directory in the collection.
ref_file=`find ${STAGE} -type f -exec basename {} \; | tail -1`
printout "Reference File ${ref_file}\n"

# count how many directories there are already in the
# collection.
# remember find gives you the first directory too so this 
# count is off by one too many.
#count_coll=`find ${COLL} -maxdepth 1 -type d -print | wc -l`
count_coll=`find ${COLL} -maxdepth 1 -type d -print 2>/dev/null | wc -l`
printout "Count of collection directories ${count_coll}\n"

a_new_dir_name=`echo "${ZERO_PADDING}${count_coll}" | rev | cut -c1-"${TOT_DIGITS}" | rev`
printout "A New Dir Name ${a_new_dir_name}\n"
new_dir_name=`echo "${DIR_PREFIX}${a_new_dir_name}"`
printout "New Dir Name ${new_dir_name}\n"

printout "${COLL}\n"
printout "${COLL}/${new_dir_name}\n"

# let us keep track of how many we move
counter_stage="0"
counter_extra="0"

# make sure it doesn't already exist
if test -d "${COLL}/${new_dir_name}" ; then
  echo -e "Directory ${COLL}/${new_dir_name} already exists... Exiting...\n\n"
  camera_unmount
  date
  exit
else

  # make sure the permissions are what we want
  chmod 600 ${STAGE}/*

  # ok finally we get to move some files, yay
  echo -e "Creating ${COLL}/${new_dir_name}.\n"
  mkdir "${COLL}/${new_dir_name}"

  # make sure it actually got created
  if test ! -d "${COLL}/${new_dir_name}" ; then
    echo -e "${COLL}/${new_dir_name} didn't get created...  Exiting...\n\n"
    camera_unmount
    date
    exit
  fi

  echo -e "Moving ${count_stage} files from ${STAGE} to ${COLL}/${new_dir_name}.\n"
  listing=`find ${STAGE} -maxdepth 1 -type f -exec basename {} \; 2>/dev/null`
  printout "List of files to move:\n$listing\n"
  for fname in ${listing}; do
    printout "  mv ${STAGE}/${fname} ${COLL}/${new_dir_name}"
    mv ${STAGE}/${fname} ${COLL}/${new_dir_name}
    counter_stage=$(($counter_stage+1))
  done
  sync
  touch -r "${COLL}/${new_dir_name}/${ref_file}" "${COLL}/${new_dir_name}"
  sync

  # do the extra backup if requested
  if test "${EXTRA_BACKUP}" == "Yes" ; then

    # make sure it doesn't already exist
    if test -d "${EXTRA_COLL}/${new_dir_name}" ; then
      echo -e "Directory ${EXTRA_COLL}/${new_dir_name} already exists... Exiting...\n\n"
      camera_unmount
      date
      exit
    fi

    mkdir -p ${EXTRA_COLL}/${new_dir_name}

    # make sure it actually got created
    if test ! -d "${EXTRA_COLL}/${new_dir_name}" ; then
      echo -e "${EXTRA_COLL}/${new_dir_name} didn't get created...  Exiting...\n\n"
      camera_unmount
      date
      exit
    fi

    echo -e "\n\nBacking up ${counter_stage} files from ${COLL} to ${EXTRA_COLL}...\n"
    for fname in ${listing}; do
      printout "  cp -av ${COLL}/${new_dir_name}/${fname} ${EXTRA_COLL}/${new_dir_name}/${fname}"
      cp -av "${COLL}/${new_dir_name}/${fname}" "${EXTRA_COLL}/${new_dir_name}/${fname}"
      counter_extra=$(($counter_extra+1))
    done
    sync
    touch -r "${COLL}/${new_dir_name}/${ref_file}" "${EXTRA_COLL}/${new_dir_name}"
    sync
  fi
fi


# say how many we moved
if test "${EXTRA_BACKUP}" == "Yes" ; then
  if test "${counter_stage}" == "${counter_extra}" ; then
    echo -e "\n\nMoved ${counter_stage} file(s) and backed up ${counter_extra} file(s).\n\n"
  else
    echo -e "\n\nMoved ${counter_stage} file(s) and backed up ${counter_extra} file(s).\n\n"
    echo -e "SOMETHING VERY STRANGE HAPPENED!  These numbers should be the same!\n\n"
  fi
else
  echo -e "\n\nMoved ${counter_stage} file(s).\n\n"
fi


# make sure it is unmounted
camera_unmount
echo -e "\n\n"
date
