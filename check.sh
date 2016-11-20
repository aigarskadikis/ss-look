#!/bin/sh

#git clone https://github.com/catonrug/ss-look.git && cd ss-look && chmod +x check.sh && ./check.sh

#check if script is located in /home direcotry
pwd | grep "^/home/" > /dev/null
if [ $? -ne 0 ]; then
  echo script must be located in /home direcotry
  return
fi

#it is highly recommended to place this directory in another directory
deep=$(pwd | sed "s/\//\n/g" | grep -v "^$" | wc -l)
if [ $deep -lt 4 ]; then
  echo please place this script in deeper directory
  return
fi

#set application name based on directory name
#this will be used for future temp directory, database name, google upload config, archiving
appname=$(pwd | sed "s/^.*\///g")

#set temp directory in variable based on application name
tmp=$(echo ../tmp/$appname)

#create temp directory
if [ ! -d "$tmp" ]; then
  mkdir -p "$tmp"
fi

#check if database directory has prepared 
if [ ! -d "../db" ]; then
  mkdir -p "../db"
fi

#set database variable
db=$(echo ../db/$appname.db)

#if database file do not exist then create one
if [ ! -f "$db" ]; then
  touch "$db"
fi

#check if google drive config directory has been made
#if the config file exists then use it to upload file in google drive
#if no config file is in the directory there no upload will happen
if [ ! -d "../gd" ]; then
  mkdir -p "../gd"
fi

if [ -f ~/uploader_credentials.txt ]; then
sed "s/folder = test/folder = `echo $appname`/" ../uploader.cfg > ../gd/$appname.cfg
else
echo google upload will not be used cause ~/uploader_credentials.txt do not exist
fi

#set url
name=$(echo "ss search")

#list mages to check
pages2check=$(cat <<EOF
https://www.ss.lv/lv/electronics/computers/today-5/
extra line
EOF
)

#take one page by page and look for all intems for sale
printf %s "$pages2check" | while IFS= read -r onepage
do {

#download one page
python ../html-downloader.py $onepage $tmp/product.log

#create a list of all items
items2check=$(sed "s/\d034/\n/g" $tmp/product.log | grep "^/msg" | sort | uniq | sed '$athis is last line')
echo "$items2check"

#take one item by item on compare it to database
printf %s "$items2check" | while IFS= read -r item
do {

grep "$item" $db > /dev/null
if [ $? -ne 0 ]; then
echo new = $item
#there is unchecked items on the internet

#extract the main text from div#msg_div_msg
msg_div_msg=$(wget -qO- www.ss.lv$item | sed "s/<div/\n<div/g" | grep -v "<div.*ads_sys_div_msg\|<script" | grep -A100 "msg_div_msg" | sed "s/<\/div>/\n<\/div>\n/g" | sed '/<\/div>/,$d' | sed -e "s/<[^>]*>//g")

echo "$msg_div_msg"
echo
echo

echo "$item">> $db
else 
#this item is already in database
echo old = $item
fi

} done
#end of item check

} done
#end of page check

#clean and remove whole temp direcotry
rm $tmp -rf > /dev/null
