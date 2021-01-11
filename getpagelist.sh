#!/bin/bash

filename="not set"
outputdir="data"
websitename="not set"
test="not set"

while getopts f:o:w:t flag;
do
    case "${flag}" in
        f) filename=${OPTARG};;
        o) outputdir=${OPTARG};;
        w) websitename=${OPTARG};;
        t) test="set";;
    esac
done

if [ "$filename" = "not set"  ] && [ "$websitename" = "not set" ] && [ "$test" = "not set" ] ;
then
    echo -e "\e[31mfilename and websitename not set. abort. Use the -f and -w parameter \e[0m" >&2
    exit 1
fi
if [ "$filename" != "not set" ] && [ "$websitename" != "not set"  ];
then
    echo -e "\e[31mDo not set filename and websitename. if you have multiple websites save it to the file. aborting...\e[0m" >&2
    exit 1
fi

# ---------------------------------------------------------------

cleanWebsite(){
    strippedString=$1
    if [[ $1 =~ ^(http:) ]] || [[ $1 =~ ^(https:) ]];
    then
        strippedString=$(echo $1| cut -d'/' -f 3)
    fi
    CLEAN=${strippedString//[^a-zA-Z0-9_.-]/}
    echo $CLEAN
}

create_dir(){
    n=$((n+1))
    mkdir -p "$outputdir/urls/"
    direc="$outputdir/urls/$1"
    mkdir -p "$direc"
    echo $direc
}

curlSitemap(){
    err=$(curlPage "$1/sitemap.xml" "$2/sitemap.xml")
    exit $?
}

curlPage(){
    err=$(curl -m 60 -L "$1" -o "$2")
    exit $?
}

forceHttps(){
    echo "https://$1"
}


getSitemap (){
    cleanWebsite=$(cleanWebsite "$1")
    printf "Crawling: $cleanWebsite\n"

    httpsWebsitename=$(forceHttps "$cleanWebsite")

    printf "Crawling: $httpsWebsitename\n"
    #creating directory
    directory=$(create_dir "$cleanWebsite")

    $(curlSitemap "$httpsWebsitename" "$directory")
    err=$?
    if [[ $err -eq 1 ]]
    then
        echo -e "\e[31mError while fetching sitemap. Are you sure there is a sitemap?\e[0m" >&2
    elif [[ $err -eq 28 ]]
    then
        echo -e "\e[31mTimeout while fetching sitemap for $httpsWebsitename.\e[0m" >&2
    else
        rm $directory/urls.txt
        $(getURLs "$directory" "$directory/sitemap.xml")
    fi

}

getURLs (){
    $(checkIfSitemapIsInvalid "$2")
    err=$?
    if [[ $err -eq 1 ]];
    then
        endpoint=$(echo $1| cut -d'/' -f 3-)
        echo "https://$endpoint" > $1/urls.txt
        exit
    fi
    sitemaps=$(cat "$2" | sed 's/ xmlns=".*"//g' | xmlstarlet sel -t -v "//sitemap/loc")
    for item in $sitemaps
    do
        endpoint=$(echo $item| cut -d'/' -f 4-)
        $(curlPage "$item" "$1/$endpoint")
        err=$(getURLs "$1" "$1/$endpoint")
    done

    $(cat "$2" | sed 's/ xmlns=".*"//g' | xmlstarlet sel -t -v "//url/loc" >> $directory/urls.txt)
}

checkIfSitemapIsInvalid (){
    case `grep -F "!doctype html" "$1" >/dev/null; echo $?` in
        0)
            # code if found
            exit 1
            ;;
        1)
            # code if not found
            exit 0
            ;;
        *)
            # code if an error occurred
            exit 0
            ;;
    esac
}

# ---------------------------------------------------------------

echo ""
echo "filename: $filename";
echo "websitename: $websitename";
echo "Exporting urls to: $outputdir/urls/"
echo ""

#functionality if filename is used
if [ "$filename" != "not set"  ];
then
    n=1
    while IFS= read -r line
    do
        getSitemap $line
    done < $filename
fi

#Functionality if websitename is set
if [ "$websitename" != "not set"  ];
then
    getSitemap $websitename
fi

if [ "$test" != "not set" ];
then
    # Use this to test functions directly
    exit 1
fi

exit 0
