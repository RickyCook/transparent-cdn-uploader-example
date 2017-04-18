#!/bin/bash
IN=image-to-cdn-tranparent
CN=$IN
IMNAME=ruff.png
UPLOAD_DURATION=2
UPLOAD_WAIT=$(expr $UPLOAD_DURATION + $UPLOAD_DURATION)

NGINX_ROOT=/usr/share/nginx/html
HOST_ROOT=$NGINX_ROOT/images
CDN_ROOT=$NGINX_ROOT/mock_cdn

HOST_PATH=$HOST_ROOT/$IMNAME
CDN_PATH=$CDN_ROOT/$IMNAME

C_YELLOW="\033[1;33m"
C_GREEN="\033[1;32m"
C_RESET="\033[0m"

function green() {
  echo >&2
  printf "$C_GREEN$1$C_RESET\n" >&2
}
function yellow() {
  echo >&2
  printf "$C_YELLOW$1$C_RESET\n" >&2
}

function try_image() {
  yellow '---- Root'
  curl -$1 http://localhost:8000/images/$IMNAME
  yellow '---- CDN'
  curl -$2 http://localhost:8000/mock_cdn/$IMNAME
}

# Force cleanup
docker kill image-to-cdn-tranparent >/dev/null 2>&1

green '-- Building and running'
docker build -t $IN .
docker run --rm -i -p 8000:80 -e UPLOAD_DURATION=$UPLOAD_DURATION --name $CN $IN &

green '-- Waiting for nginx'
until curl http://localhost:8000 >/dev/null 2>&1 ; do
  sleep 1
done

###########
# Interesting stuff starts here!!!
###########

# Show that the image is a 301 on the host, and a 404 on the CDN. This results
# in an overall 404
#
# Expected output:
# ---- Root
# HTTP/1.1 301 Moved Permanently
# Location: http://localhost/mock_cdn/bark/ruff.png
# ...
# 
# ---- CDN
# HTTP/1.1 404 Not Found
green '-- Trying the image URL to start with'
try_image I I

# Simulates a user upload. The image will only start to be uploaded to the CDN
# when the file is closed, so only a complete file is ever uploaded
green '-- Adding the image (user upload)'
docker exec $CN sh -c "echo 'test @ $(date)' > $HOST_PATH"

# Show that the image is found on the host during the upload to the CDN, so
# viewing will always work. It's also 404 on the CDN, but this is not entirely
# relevant, as the 301 won't ever push the user here)
#
# Expected output:
# ---- Root
# HTTP/1.1 200 OK
# ...
# test @ Tue 18 Apr 2017 18:00:33 AEST
# ...
#
# ---- CDN
# HTTP/1.1 404 Not Found
green '-- Checking the image'
try_image i I

# Wait for 2x the upload time to make sure the file is done "uploading" before
# checking the image again. Here we see 301 on the host to the CDN, and a 200
# on the CDN with the correct content
#
# Expected output:
# ---- Root
# HTTP/1.1 301 Moved Permanently
# Location: http://localhost/mock_cdn/ruff.png
# ...
#
# ---- CDN
# HTTP/1.1 200 OK
# ...
# test @ Tue 18 Apr 2017 18:00:33 AEST
green "-- Waiting for upload ($UPLOAD_WAIT seconds)"
sleep $UPLOAD_WAIT
try_image I i

# Remove everything when we're done
green '-- Docker cleanup'
docker kill $CN
