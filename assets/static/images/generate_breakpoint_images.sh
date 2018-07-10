#!/usr/bin/env bash

if [ $# -lt 1 ]; then
  echo "You must specify at least one file to convert!"
  exit 1
fi

while [ $# -gt 0 ]; do
  echo "Converting $1..."
  convert $1 -sampling-factor 4:2:0 -strip -quality 85 -interlace JPEG -colorspace RGB -set option:filename:base "%t" \
    \( +clone -resize "575>"  -write "%[filename:base]-xs.jpg"    +delete \) \
    \( +clone -resize "1150>" -write "%[filename:base]-xs@2x.jpg" +delete \) \
    \( +clone -resize "767>"  -write "%[filename:base]-sm.jpg"    +delete \) \
    \( +clone -resize "1534>" -write "%[filename:base]-sm@2x.jpg" +delete \) \
    \( +clone -resize "991>"  -write "%[filename:base]-md.jpg"    +delete \) \
    \( +clone -resize "1982>" -write "%[filename:base]-md@2x.jpg" +delete \) \
    \( +clone -resize "1199>" -write "%[filename:base]-lg.jpg"    +delete \) \
    \( +clone -resize "2398>" -write "%[filename:base]-lg@2x.jpg" +delete \) \
    \( +clone -resize "1920>" -write "%[filename:base]-xl.jpg"    +delete \) \
              -resize "3840>" "%[filename:base]-xl@2x.jpg"
  shift
done
