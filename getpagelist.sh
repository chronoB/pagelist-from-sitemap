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

getURLs (){
    while read_dom; do
        if [[ $ENTITY = "sitemap" ]]; then
            curlPage "$CONTENT" "$1/$CONTENT"
            getURLs "$1/$CONTENT" "$3"
        fi
    done < $2

    while read_dom; do
        if [[ $ENTITY = "url" ]]; then
            echo $CONTENT
            exit
        fi
    done < $2 > $3
}

#function to parse the xml
# see https://stackoverflow.com/questions/893585/how-to-parse-xml-in-bash
read_dom () {
    local IFS=\>
    read -d \< ENTITY CONTENT
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

checkIfSitemapIsValid(){
    #ToDo: check if file has correct xml format
    exit 0
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
        $(checkIfSitemapIsValid "$directory")
        getURLs "$directory" "$directory/sitemap.xml" "$directory/urls.txt"
    fi

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
