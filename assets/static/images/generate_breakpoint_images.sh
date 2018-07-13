#!/usr/bin/env bash

fw=0
bg=0

# Process command line flags
while [[ $1 == --* ]]; do
  case $1 in
    # Generate exact breakpoint sizes for use in CSS background-image property
    # (by default generates generic resolutions for use with srcset)
    "--background") bg=1;;
    "--bg"        ) bg=1;;
    # Generate background sizes suitable for full page width jumbotrons instead
    # of Bootstrap container (does nothing when used without background option)
    "--full-width") fw=1;;
  esac
  shift
done

# Make sure we have at least one file to work on
if [ $# -lt 1 ]; then
  echo "You must specify at least one file to convert!"
  exit 1
fi

# Process each file in our list
while [ $# -gt 0 ]; do
  echo "Processing $1..."
  if [ $bg -eq 1 ]; then
    if [ $fw -eq 1 ]; then
      # These numbers may seem rather odd; it's because they need to accomodate
      # the largest posible viewport width for that breakpoint, and the next
      # breakpoint *starts* on the nice even number.
      # The width for the XL breakpoint is arbitrarily chosen, as it has no
      # maximum size. It might look bad if someone with a 4K monitor has their
      # browser fullscreen, but so will most sites.
      convert $1 -strip -sampling-factor 4:2:0 -quality 85 -interlace JPEG \
        -colorspace RGB -set option:filename:t "%t" \
        \( +clone -resize "575>"  -write "%[filename:t]-xs.jpg"    +delete \) \
        \( +clone -resize "1150>" -write "%[filename:t]-xs@2x.jpg" +delete \) \
        \( +clone -resize "767>"  -write "%[filename:t]-sm.jpg"    +delete \) \
        \( +clone -resize "1534>" -write "%[filename:t]-sm@2x.jpg" +delete \) \
        \( +clone -resize "991>"  -write "%[filename:t]-md.jpg"    +delete \) \
        \( +clone -resize "1982>" -write "%[filename:t]-md@2x.jpg" +delete \) \
        \( +clone -resize "1199>" -write "%[filename:t]-lg.jpg"    +delete \) \
        \( +clone -resize "2398>" -write "%[filename:t]-lg@2x.jpg" +delete \) \
        \( +clone -resize "1920>" -write "%[filename:t]-xl.jpg"    +delete \) \
                  -resize "3840>"        "%[filename:t]-xl@2x.jpg"
    else
      # Yes, it is strange that the XS image is larger than the small image.
      # These are the container widths directly from Bootstrap, so you'll have
      # to take it up with them.
      convert $1 -strip -sampling-factor 4:2:0 -quality 85 -interlace JPEG \
        -colorspace RGB -set option:filename:t "%t" \
        \( +clone -resize "545>"  -write "%[filename:t]-xs.jpg"    +delete \) \
        \( +clone -resize "1090>" -write "%[filename:t]-xs@2x.jpg" +delete \) \
        \( +clone -resize "540>"  -write "%[filename:t]-sm.jpg"    +delete \) \
        \( +clone -resize "1080>" -write "%[filename:t]-sm@2x.jpg" +delete \) \
        \( +clone -resize "720>"  -write "%[filename:t]-md.jpg"    +delete \) \
        \( +clone -resize "1440>" -write "%[filename:t]-md@2x.jpg" +delete \) \
        \( +clone -resize "960>"  -write "%[filename:t]-lg.jpg"    +delete \) \
        \( +clone -resize "1920>" -write "%[filename:t]-lg@2x.jpg" +delete \) \
        \( +clone -resize "1140>" -write "%[filename:t]-xl.jpg"    +delete \) \
                  -resize "2280>"        "%[filename:t]-xl@2x.jpg"
    fi
  else
    # TODO: investigate using this API: http://www.responsivebreakpoints.com
    # These sizes are losely based on the most common screen resolutions on the
    # internet, as of July 2018. Some are rounded off or combined, but since the
    # way <picture> and <img srcset=""> work is to select the smallest size
    # larger than the computed threshold it should gracefully move up. You may
    # notice that the resolutions are biased somewhat toward the larger sizes;
    # this is because the file size grows exponentially with resolution, so the
    # file size difference between 480w and 720w is much smaller than that
    # between 1440w and 1600w despite the same nominal difference in width.
    convert $1 -strip -sampling-factor 4:2:0 -quality 85 -interlace JPEG \
        -colorspace RGB -set option:filename:t "%t" \
        \( +clone -resize "320>"  -write "%[filename:t]-320.jpg"  +delete \) \
        \( +clone -resize "360>"  -write "%[filename:t]-360.jpg"  +delete \) \
        \( +clone -resize "480>"  -write "%[filename:t]-480.jpg"  +delete \) \
        \( +clone -resize "640>"  -write "%[filename:t]-640.jpg"  +delete \) \
        \( +clone -resize "768>"  -write "%[filename:t]-768.jpg"  +delete \) \
        \( +clone -resize "1280>" -write "%[filename:t]-1280.jpg" +delete \) \
        \( +clone -resize "1366>" -write "%[filename:t]-1366.jpg" +delete \) \
        \( +clone -resize "1440>" -write "%[filename:t]-1440.jpg" +delete \) \
        \( +clone -resize "1600>" -write "%[filename:t]-1600.jpg" +delete \) \
        \( +clone -resize "1920>" -write "%[filename:t]-1920.jpg" +delete \) \
                  -resize "2880>"        "%[filename:t]-2880.jpg"
  fi
  shift
done
