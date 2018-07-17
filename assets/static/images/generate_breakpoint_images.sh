#!/usr/bin/env bash

fw=0
bg=0
retina=0
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
    # of Bootstrap containers (does nothing when used without background option)
    "--full-width" ) fw=1; shift;;
    "--fw"         ) fw=1; shift;;
    # Generate double-resolution versions of nominal sizes for display on HiDPI
    # screens. Generates exact doubles when used with --background flag; in
    # normal (srcset) mode, doubles range over which images are generated (i.e.
    # doubles largest nominal size)
    "--retina" ) retina=1; shift;;
    "--hidpi"  ) retina=1; shift;;
    "--2x"     ) retina=1; shift;;
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
  if [ $bg -eq 1 ]; then
    if [ $fw -eq 1 ]; then
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
    pct=$(echo "scale=2; $max_w * 100 / $src_w" | bc)

    while [ $target -gt $stop ]; do
      while [ $curr -gt $target ]; do
        convert $1 $iflags -resize "$pct%" $oflags "$bn-tmp.jpg"
        curr=$(cat "$bn-tmp.jpg" | wc -c)
        pct=$(echo "scale=2;$pct - 0.5" | bc)
      done
      w=$(identify -format "%w" "$bn-tmp.jpg")
      mv "$bn-tmp.jpg" "$bn-$w.jpg"
      target=$(( $target - $step ))
    done
    
  fi
  shift
done
