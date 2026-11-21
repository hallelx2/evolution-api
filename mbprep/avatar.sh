#!/bin/bash
# avatar.sh <out.jpg> <crest-image-or-empty> <short name>
# The MBPrep mark with the school as a badge at its lower right ("MBPrep, subscript school"), 640x640 for WhatsApp.
set -e
OUT=$1; CREST=$2; SHORT=$3
INK='#0d0d0d'
MARK=/home/hallelx2/dev/MBPrep/wt-6086/apps/web/public/brand/mark-white-1024.png
FONT=/home/hallelx2/.local/share/fonts/PlusJakartaSans-ExtraBold.ttf
T=$(mktemp -d)
magick -size 640x640 xc:"$INK" \
  \( "$MARK" -resize 330x \) -geometry +95+130 -composite \
  -fill "$INK" -draw "circle 452,452 452,312" \
  -fill white -draw "circle 452,452 452,326" \
  -type TrueColor PNG24:$T/base.png
if [ -n "$CREST" ] && [ -s "$CREST" ]; then
  magick -background none -density 300 "$CREST" -flatten -background white -alpha remove -trim +repage -resize 166x166 PNG32:$T/c.png
  magick $T/base.png $T/c.png -gravity NorthWest -geometry +$((452-$(magick identify -format %w $T/c.png)/2))+$((452-$(magick identify -format %h $T/c.png)/2)) -composite $T/out.png
else
  magick -background none -fill "$INK" -font "$FONT" -size 214x100 -gravity center label:"$SHORT" -trim +repage $T/t.png
  W=$(magick identify -format %w $T/t.png); H=$(magick identify -format %h $T/t.png)
  magick $T/base.png $T/t.png -geometry +$((452-W/2))+$((452-H/2)) -composite $T/out.png
fi
magick $T/out.png -type TrueColor -quality 92 "$OUT"
rm -rf $T
