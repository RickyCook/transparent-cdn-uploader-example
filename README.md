# Transparent CDN uploader example

Super quick POC for a transparent way to upload and use images on a CDN.

Doesn't actually upload to a CDN (but could easily). For the purposes of not
needing a CDN somewhere, we are simply using a different local directory to
serve as our mock CDN.

## How it works

- When you request a file in nginx, it first checks it's local images dir, and
  serves up any file it finds. This is so that while an image is being uploaded
  to the CDN, it's still accessible to everyone
- An inotify script is running in the background, watching the uploads
  directory for new files. When it detects that a file handle has been closed
  (user upload, or modification is done):
  - It starts uploading the file to the "CDN" (in this case, a `sleep`
    followed by a `cp`)
  - When the upload is done, it deletes the file from the disk. This means that
    nginx will now not find the file, and fall through to the next step
- When nginx can't find the file on the disk, it will issue a 301 redirect to
  the CDN. This will be transparently handled by clients, so there's nothing
  else to do here; everything will work as it does currently

## Example

The `example.sh` file requires that Docker and `curl` be installed. It will
build an image, create a server container, and run some `curl` commands so that
request headers and content can be inspected to make sure they match.

This file is documented with a lot of expected output, so it shouldn't really
need to be run even. Skip down about half way to the "interesting" part.
