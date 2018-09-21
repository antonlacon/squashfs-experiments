#!/bin/bash

# run as root

# Set up environment
echo " * Setting up..."
TEMP_DIR=$(mktemp -d)
mkdir -p results
cp -R le-filesystem/. $TEMP_DIR

# Crunch
for COMPRESSION_TYPE in gzip lzo zstd; do
    echo " - Testing $COMPRESSION_TYPE"
    if [ "$COMPRESSION_TYPE" = "lzo" -o "$COMPRESSION_TYPE" = "gzip" ]; then
        COMPRESSION_LEVEL=(1 2 3 4 5 6 7 8 9)
    elif [ "$COMPRESSION_TYPE" = "zstd" ]; then
        COMPRESSION_LEVEL=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22)
    fi

    for COMPRESSION_STRENGTH in ${COMPRESSION_LEVEL[*]}; do
        for BLOCK_SIZE in 4096 8192 16384 32768 65536 131072 262144 524288 1048576; do
            FILENAME="results/squashfs-$COMPRESSION_TYPE-$COMPRESSION_STRENGTH-$BLOCK_SIZE.squashfs"
            echo "   * Running a squashfs using compression $COMPRESSION_TYPE level $COMPRESSION_STRENGTH, blocksize $BLOCK_SIZE"
            ( time mksquashfs $TEMP_DIR $FILENAME \
                -b $BLOCK_SIZE -comp $COMPRESSION_TYPE -Xcompression-level $COMPRESSION_STRENGTH -noappend ) \
                >  $FILENAME.results \
                2> $FILENAME.compress_time
        done
    done
done

echo " * Testing uncompressing times..."
for FILENAME in $(ls results/*.squashfs); do
    mkdir -p squashfs.extract
    echo "   * Reading $FILENAME..."
    # Catting things in /dev... not so great idea (and it's trivially small anyway)
    mount -t squashfs $FILENAME squashfs.extract
    (time $(find squashfs.extract | grep -v "/dev" | xargs cat - > /dev/null)) 2> $FILENAME.uncompress_time
    REALTIME=$(grep "real" $FILENAME.uncompress_time | \
               tail -n 1 | awk '{print $2}')
    echo $REALTIME > $FILENAME.uncompress_time
    sync
    umount squashfs.extract
    rmdir squashfs.extract
done

# Clean up
echo " * Cleaning up..."
rm -r $TEMP_DIR
