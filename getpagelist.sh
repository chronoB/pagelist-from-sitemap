#!/bin/bash

filename="not set"
outputdir="data"
websitename="not set"

while getopts f:o:w: flag;
do
    case "${flag}" in
        f) filename=${OPTARG};;
        o) outputdir=${OPTARG};;
        w) websitename=${OPTARG};;
    esac
done

if [ "$filename" = "not set"  ] && [ "$websitename" = "not set"  ];
then
    echo -e "\e[31mfilename and websitename not set. abort. Use the -f and -w parameter \e[0m" >&2
    exit 1
fi
if [ "$filename" != "not set" ] && [ "$websitename" != "not set"  ];
then
    echo -e "\e[31mDo not set filename and websitename. if you have multiple websites save it to the file. aborting...\e[0m" >&2
    exit 1
fi

echo ""
echo "filename: $filename";
echo "websitename: $websitename";
echo "Exporting urls to: $outputdir/urls/"
echo ""


if [ "$filename" != "not set"  ];
then
    n=1
    while IFS= read -r line
    do
        CLEAN=${line//[^a-zA-Z0-9_.-]/}
        # reading each line
        echo "Line No. $n : $CLEAN"
        n=$((n+1))
        mkdir -p "$outputdir/urls/"
        direc="$outputdir/urls/"
        mkdir -p "$direc$CLEAN"
        wget -nd --spider --force-html -r -l3 $CLEAN 2>&1 | egrep -o 'https?://[^ ]+' | grep -v '\.\(css\|js\|png\|gif\|jpg\|svg\|xml\|otf\|ttf\|mp3\)$' | grep -v '\(oembed\|\?ver=\|\?v=\|eot\)' | grep '\/$' | sort | uniq > $outputdir/urls/$CLEAN/urls.txt
    done < $filename
fi

if [ "$websitename" != "not set"  ];
then

    CLEAN=${websitename//[^a-zA-Z0-9_.-]/}
    # reading each line
    echo "Crawling: $CLEAN"
    n=$((n+1))
    mkdir -p "$outputdir/urls/"
    direc="$outputdir/urls/"
    mkdir -p "$direc$CLEAN"
    wget -nd --spider --force-html -r -l3 $CLEAN 2>&1 | egrep -o 'https?://[^ ]+' | grep -v '\.\(css\|js\|png\|gif\|jpg\|svg\|xml\|otf\|ttf\|mp3\)$' | grep -v '\(oembed\|\?ver=\|\?v=\|eot\)' | grep '\/$' | sort | uniq > $outputdir/urls/$CLEAN/urls.txt

fi
exit 0
