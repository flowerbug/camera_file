Mon 26 May 2025 16:43:42 PM EDT


# General Information

  WARNING!  This script will remove files from your camera, that is what it is designed to do.

  BEFORE running this script for the first time you will have to edit it to change the parameters for the camera and the locations of the collections you wish to use.  Look for the section starting with "Local Configuration".  It may take some time and testing to set it up but as a framework it should save some time instead of having to write it all yourself.

  camera_file.sh is a bash script which will move files from a camera to selected places.  I need it because my camera resets the file name if I remove pictures from the directory on the memory card (a straight copy from the camera to a fixed directory would then overwrite previously transferred pictures).  This is an issue with my camera and may not be a problem for other cameras.

  I only use one directory on the camera.

  The only options the script takes are [-h]|[--help], [-v]|[--verbose] or [-V]|[--Version] CAMERA_NAME

  The script must be passed the name of the camera or the camera location that shows up when you plug the camera in, because this information sometimes can contain sensitive information I am not hard-coding it in the script.


Example:

$ camera_file.sh NIKON_NIKON_DSC_D3500_1234567890123


  Each run (if there are files to be moved) will create a new directory in the collections with a unique name.

  CAMERA_NAME is set from what is given to the script, it is a required parameter.

  At the end of the run the stage should be empty and all files should be in their proper locations in the collections.  The collections are organized by camera prefix.  Each directory for a camera will have it's own sequence number for the directories within it.  DO NOT delete directories (but you can delete files in them) as the total number of directories is how I determine what the next sequence number should be.  You can delete the last directory if it is a bunch of files you don't really want (or you can completely erase the collection if this is something you are just testing out before you go into regular production).

  My normal work flow is to take a batch of pictures, move them to the computer and edit or delete what I don't want.  If the entire batch is bad I'll delete it from the computer and my external backup device before running the script again so there won't be any extra stuff stored on the computer or the backup device that I'm not actually going to use.

  As a safety check the collection directory where files are being copied to should not already exist and no files should be over written, both of these are considered fatal errors as something strange must be happening (like deleting one directory but not another).

  Read through the script it is largely meant to be self evident and self documented.  The LICENSE file is provided to make sure you have the full text of that.


# To Install for a Linux/Posix Type System

  camera_file.sh has various linux/posix/unix type tools used within it so if you are trying to use it on any other type system then those you will either have to figure out what is different and fix it or work around it.

  Some of the dependencies are: libglib2.0, gphotofs, mount, find, rev, cut, lsusb and I'm sure some others.

  To run the script it needs to be in the ${PATH} as an executable.  It should run from anywhere.  The directories this script operates on are specified using ${HOME} and if you desire a backup copy to be made to another location use ${EXTRA_BACKUP}.


# Other Notes

  When I first plug in the camera it shows up as:

gphoto2://CAMERA_NAME/

which I don't want so I have to unmount it before remounting
it where I want it to be mounted on ${HOME}/pics/camera

gio mount -u gphoto2://CAMERA_NAME/

  Mounting and unmounting using gphotofs

       mounting
           gphotofs <mountpoint>

       unmounting
           fusermount -u <mountpoint>

  The local mount point set up under ${HOME} would give the 
full path for my camera as:

${HOME}/pics/camera/store_00010001/DCIM/100D3500


# Bug Reporting

  Please use the issue tracker on github for this project.


