#!/bin/bash

filename="not set"
outputdir="data"
websitename="not set"
test="not set"
saveSitemaps="not set"

while getopts f:o:w:ts flag;
do
    case "${flag}" in
        f) filename=${OPTARG};;
        o) outputdir=${OPTARG};;
        w) websitename=${OPTARG};;
        t) test="set";;
        s) saveSitemaps="set";;
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

# removes http(s) because we will enforce https later on
# strips linebreaks etc from the file input
cleanWebsite(){
    strippedString=$1
    if [[ $1 =~ ^(http:) ]] || [[ $1 =~ ^(https:) ]];
    then
        strippedString=$(echo $1| cut -d'/' -f 3)
    fi
    CLEAN=${strippedString//[^a-zA-Z0-9_.-]/}
    echo $CLEAN
}

#create the directory were the data will be stored for the specific website
create_dir(){
    n=$((n+1))
    mkdir -p "$outputdir/urls/"
    direc="$outputdir/urls/$1"
    mkdir -p "$direc"
    echo $direc
}

#curl specified page
curlPage(){
    #timeout after 60 sec. follow redirects. output to $2
    err=$(curl -m 60 -L "$1" -o "$2")
    exit $?
}

#add https:// to the url. possible because cleanWebsite removes every protocol
forceHttps(){
    echo "https://$1"
}

#functionality to grab the sitemap of the given url and retrieve all urls from it
getSitemap (){

    cleanWebsite=$(cleanWebsite "$1")
    printf "Crawling: $cleanWebsite\n"

    httpsWebsitename=$(forceHttps "$cleanWebsite")

    printf "Crawling: $httpsWebsitename\n"
    #creating directory
    directory=$(create_dir "$cleanWebsite")

    $(curlPage "$httpsWebsitename/sitemap.xml" "$directory/sitemap.xml")
    err=$?
    if [[ $err -eq 1 ]]
    then
        echo -e "\e[31mError while fetching sitemap. Are you sure there is a sitemap?\e[0m" >&2
    elif [[ $err -eq 28 ]]
    then
        echo -e "\e[31mTimeout while fetching sitemap for $httpsWebsitename.\e[0m" >&2
    else
        rm $directory/tmp.txt
        rm $directory/urls.txt
        $(getURLs "$directory" "$directory/sitemap.xml")
    fi
    #remove all duplicate urls
    $(sort $directory/tmp.txt | uniq > $directory/urls.txt )
    #remove empty first line
    $(sed -i 1d $directory/urls.txt)

}

#recursivly going through the sitemaps and getting all the urls
getURLs (){
    $(checkIfSitemapIsInvalid "$2")
    err=$?
    if [[ $err -eq 1 ]];
    then
        #if the sitemap link fetches the index page, only save the indexpage and exit afterwards
        endpoint=$(echo $1| cut -d'/' -f 3-)
        echo "https://$endpoint" > $1/urls.txt
        exit
    fi
    #remove the namespace from the xml file because xmlstarlet won't output anything otherwise
    #the namespace is not important for us
    #fetching all the sitemaps (if there are any) and recursivly calling this function with the new sitemap
    sitemaps=$(cat "$2" | sed 's/ xmlns=".*"//g' | xmlstarlet sel -t -v "//sitemap/loc")
    for item in $sitemaps
    do
        endpoint=$(echo $item | rev | cut -d'/' -f 1 | rev)
        $(curlPage "$item" "$1/$endpoint")
        err=$(getURLs "$1" "$1/$endpoint")
    done

    #get all the urls in a sitemap and append them to the urls.txt file
    $(cat "$2" | sed 's/ xmlns=".*"//g' | xmlstarlet sel -t -v "//url/loc" >> $directory/tmp.txt)
    $(echo "" >> $directory/tmp.txt)
    if [ "$saveSitemaps" == "not set" ];
    then
        $(rm "$2")
    fi
}

# if the doctype html is found it is not a xml file (suprise)
# if the sitemap.xml was not found the curl command will get the index page of the website, so this will prevent errors
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
