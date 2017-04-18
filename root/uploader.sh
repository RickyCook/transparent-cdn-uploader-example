#!/bin/sh
UPLOAD_DURATION=${UPLOAD_DURATION:-20}

operation=$1
directory=$2
filename=$3

# Write handle closed operations only
[ $operation = 'w' ] || exit 0

echo "Uploading image '$filename' (will take $UPLOAD_DURATION seconds)" >&2
sleep $UPLOAD_DURATION
full_cdn_path=$(dirname $CDN_DIR/$filename)
mkdir -p $full_cdn_path
cp $directory/$filename $CDN_DIR/$filename

echo "Deleting image '$filename'" >&2
rm $directory/$filename
