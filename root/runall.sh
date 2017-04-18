#!/bin/sh
set -x

export ROOT_DIR=/usr/share/nginx/html
export IMAGES_DIR=$ROOT_DIR/images
export CDN_DIR=$ROOT_DIR/mock_cdn

# Debugging watches
inotifyd - $IMAGES_DIR &
inotifyd - $CDN_DIR &

# Send file events to uploader
inotifyd /uploader.sh $IMAGES_DIR &

# Run nginx
nginx -g 'daemon off;'
