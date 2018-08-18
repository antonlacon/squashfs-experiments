#!/bin/bash

# Place test squashfs images in ./results/

echo " * Testing uncompressing times..."
for FILENAME in $(ls ./results/*.squashfs); do
    mkdir -p squashfs.extract
    echo "   * Reading $FILENAME..."
    # Catting things in /dev... not so great idea (and it's trivially small anyway)
    mount -t squashfs $FILENAME squashfs.extract
    (time cat $(find squashfs.extract | grep -v "/dev" ) > /dev/null) 2> $FILENAME.uncompress_time
    REALTIME=$(grep "real" $FILENAME.uncompress_time | \
               cut -f 2 | tr -d ' ')
    echo $REALTIME > $FILENAME.uncompress_time
    sync
    umount squashfs.extract
    rmdir squashfs.extract
done
