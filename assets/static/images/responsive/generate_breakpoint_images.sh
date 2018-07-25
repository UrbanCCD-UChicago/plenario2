#!/usr/bin/env bash

fw=0
bg=0
retina=0
dynamic=0
min_w=320
max_w=1920
step=65536

# Process command line flags
while [[ $1 == --* ]]; do
  case $1 in
    # Generate exact breakpoint sizes for use in CSS background-image property
    # (by default generates generic resolutions for use with srcset)
    "--bootstrap-background" ) bg=1; shift;;
    "--bg"                   ) bg=1; shift;;
    # Generate background sizes suitable for full page width jumbotrons instead
    # of Bootstrap containers
    "--full-width" ) fw=1; shift;;
    "--fw"         ) fw=1; shift;;
    # Generate double-resolution versions of nominal sizes for display on HiDPI
    # screens. Generates exact doubles when used with --background flag; in
    # normal (srcset) mode, doubles range over which images are generated (i.e.
    # doubles largest nominal size)
    "--retina" ) retina=1; shift;;
    "--hidpi"  ) retina=1; shift;;
    "--2x"     ) retina=1; shift;;
    # Dynamically generate images based on a file size step, instead of specific
    # predefined sizes, for use with srcset
    "--dynamic") dynamic=1; shift;;
    # Define the nominal minimum width, nominal maximum width, and file size
    # step for dynamic (srcset) image generation
    "--min" ) min_w=$2; shift; shift;;
    "--max" ) max_w=$2; shift; shift;;
    "--step") step=$2; shift; shift;;
  esac
done

# Make sure we have at least one file to work on
if [ $# -lt 1 ]; then
  echo "You must specify at least one file to convert!"
  exit 1
fi

iflags="-strip -sampling-factor 4:2:0 -quality 85 -interlace JPEG -colorspace RGB"
oflags="-unsharp 1.5x1+0.7+0.02 -modulate 100,105 -colorspace sRGB"
if [ $retina -eq 1 ]; then
  max_w=$(( $max_w * 2 ))
fi

# Process each file in our list
while [ $# -gt 0 ]; do
  echo "Processing $1..."
  if [ $bg -gt 0 ]; then
    if [ $fw -gt 0 ]; then
      # These numbers may seem rather odd; it's because they need to accomodate
      # the largest posible viewport width for that breakpoint, and the next
      # breakpoint *starts* on the nice even number.
      # The width for the XL breakpoint is arbitrarily chosen, as that
      # breakpoint has no maximum size. It might look bad if someone with a 4K
      # monitor has their browser fullscreen, but so will most sites.
      convert $1 $iflags -set option:filename:t "%t" \
        \( +clone -resize "575>"  $oflags -write "%[filename:t]-xs.jpg" +delete \) \
        \( +clone -resize "767>"  $oflags -write "%[filename:t]-sm.jpg" +delete \) \
        \( +clone -resize "991>"  $oflags -write "%[filename:t]-md.jpg" +delete \) \
        \( +clone -resize "1199>" $oflags -write "%[filename:t]-lg.jpg" +delete \) \
                  -resize "1920>" $oflags        "%[filename:t]-xl.jpg"
                  
      if [ $retina -gt 0 ]; then
        convert $1 $iflags -set option:filename:t "%t" \
          \( +clone -resize "1150>" $oflags -write "%[filename:t]-xs@2x.jpg" +delete \) \
          \( +clone -resize "1534>" $oflags -write "%[filename:t]-sm@2x.jpg" +delete \) \
          \( +clone -resize "1982>" $oflags -write "%[filename:t]-md@2x.jpg" +delete \) \
          \( +clone -resize "2398>" $oflags -write "%[filename:t]-lg@2x.jpg" +delete \) \
                    -resize "3840>" $oflags        "%[filename:t]-xl@2x.jpg"
      fi
    else
      # Yes, it is strange that the XS image is larger than the small image.
      # These are the container widths directly from Bootstrap, so you'll have
      # to take it up with them.
      convert $1 $iflags -set option:filename:t "%t" \
        \( +clone -resize "545>"  $oflags -write "%[filename:t]-xs.jpg" +delete \) \
        \( +clone -resize "540>"  $oflags -write "%[filename:t]-sm.jpg" +delete \) \
        \( +clone -resize "720>"  $oflags -write "%[filename:t]-md.jpg" +delete \) \
        \( +clone -resize "960>"  $oflags -write "%[filename:t]-lg.jpg" +delete \) \
                  -resize "1140>" $oflags        "%[filename:t]-xl.jpg"
        
      if [ $retina -gt 0 ]; then
        convert $1 $iflags -set option:filename:t "%t" \
          \( +clone -resize "1090>" $oflags -write "%[filename:t]-xs@2x.jpg" +delete \) \
          \( +clone -resize "1080>" $oflags -write "%[filename:t]-sm@2x.jpg" +delete \) \
          \( +clone -resize "1440>" $oflags -write "%[filename:t]-md@2x.jpg" +delete \) \
          \( +clone -resize "1920>" $oflags -write "%[filename:t]-lg@2x.jpg" +delete \) \
                    -resize "2280>" $oflags        "%[filename:t]-xl@2x.jpg"
      fi
    fi
  else
    if [ $dynamic -gt 0 ]; then
      bn=${1%.*}

      max_fs=$(( $(convert $1 $iflags -resize "$max_w>" $oflags -write "$bn-$max_w.jpg" \
        jpeg:- | wc -c) ))
      min_fs=$(( $(convert $1 $iflags -resize "$min_w>" $oflags -write "$bn-$min_w.jpg" \
        jpeg:- | wc -c) ))

      src_w=$(( $(identify -format "%w" $1) ))

      # This avoids generating a breakpoint only slightly bigger than the min size
      stop=$(( $(echo "$min_fs + (0.85 * $step) / 1" | bc) ))
      target=$(( $max_fs - $step ))
      curr=$max_fs
      pct=$(echo "$max_w * 100 / $src_w" | bc)

      while [ $target -gt $stop ]; do
        while [ $curr -gt $target ]; do
          convert $1 $iflags -resize "$pct%" $oflags "$bn-tmp.jpg"
          curr=$(cat "$bn-tmp.jpg" | wc -c)
          pct=$(( $pct - 1 ))
        done
        w=$(identify -format "%w" "$bn-tmp.jpg")
        mv "$bn-tmp.jpg" "$bn-$w.jpg"
        target=$(( $target - $step ))
      done
    else
      # These are the common sizes for fluid images displayed in bootstrap
      # columns (4, 6, 8, and 12)
      convert $1 $iflags -set option:filename:t "%t" \
        \( +clone -resize "150>"  $oflags -write "%[filename:t]-150.jpg" +delete \) \
        \( +clone -resize "162>"  $oflags -write "%[filename:t]-162.jpg" +delete \) \
        \( +clone -resize "210>"  $oflags -write "%[filename:t]-210.jpg" +delete \) \
        \( +clone -resize "240>"  $oflags -write "%[filename:t]-240.jpg" +delete \) \
        \( +clone -resize "258>"  $oflags -write "%[filename:t]-258.jpg" +delete \) \
        \( +clone -resize "290>"  $oflags -write "%[filename:t]-290.jpg" +delete \) \
        \( +clone -resize "330>"  $oflags -write "%[filename:t]-330.jpg" +delete \) \
        \( +clone -resize "350>"  $oflags -write "%[filename:t]-350.jpg" +delete \) \
        \( +clone -resize "353>"  $oflags -write "%[filename:t]-353.jpg" +delete \) \
        \( +clone -resize "450>"  $oflags -write "%[filename:t]-450.jpg" +delete \) \
        \( +clone -resize "510>"  $oflags -write "%[filename:t]-510.jpg" +delete \) \
        \( +clone -resize "540>"  $oflags -write "%[filename:t]-540.jpg" +delete \) \
        \( +clone -resize "545>"  $oflags -write "%[filename:t]-545.jpg" +delete \) \
        \( +clone -resize "610>"  $oflags -write "%[filename:t]-610.jpg" +delete \) \
        \( +clone -resize "690>"  $oflags -write "%[filename:t]-690.jpg" +delete \) \
        \( +clone -resize "730>"  $oflags -write "%[filename:t]-730.jpg" +delete \) \
        \( +clone -resize "930>"  $oflags -write "%[filename:t]-930.jpg" +delete \) \
                  -resize "1110>" $oflags        "%[filename:t]-1110.jpg"

      if [ $retina -gt 0 ]; then
        convert $1 $iflags -set option:filename:t "%t" \
          \( +clone -resize "300>"  $oflags -write "%[filename:t]-300.jpg" +delete \) \
          \( +clone -resize "324>"  $oflags -write "%[filename:t]-324.jpg" +delete \) \
          \( +clone -resize "420>"  $oflags -write "%[filename:t]-420.jpg" +delete \) \
          \( +clone -resize "480>"  $oflags -write "%[filename:t]-480.jpg" +delete \) \
          \( +clone -resize "516>"  $oflags -write "%[filename:t]-516.jpg" +delete \) \
          \( +clone -resize "580>"  $oflags -write "%[filename:t]-580.jpg" +delete \) \
          \( +clone -resize "660>"  $oflags -write "%[filename:t]-660.jpg" +delete \) \
          \( +clone -resize "700>"  $oflags -write "%[filename:t]-700.jpg" +delete \) \
          \( +clone -resize "706>"  $oflags -write "%[filename:t]-706.jpg" +delete \) \
          \( +clone -resize "900>"  $oflags -write "%[filename:t]-900.jpg" +delete \) \
          \( +clone -resize "1020>" $oflags -write "%[filename:t]-1020.jpg" +delete \) \
          \( +clone -resize "1080>" $oflags -write "%[filename:t]-1080.jpg" +delete \) \
          \( +clone -resize "1090>" $oflags -write "%[filename:t]-1090.jpg" +delete \) \
          \( +clone -resize "1220>" $oflags -write "%[filename:t]-1220.jpg" +delete \) \
          \( +clone -resize "1380>" $oflags -write "%[filename:t]-1380.jpg" +delete \) \
          \( +clone -resize "1460>" $oflags -write "%[filename:t]-1460.jpg" +delete \) \
          \( +clone -resize "1860>" $oflags -write "%[filename:t]-1860.jpg" +delete \) \
                    -resize "2220>" $oflags        "%[filename:t]-2220.jpg"
      fi
    fi
  fi
  shift
done
