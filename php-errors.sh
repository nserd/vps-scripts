#!/bin/bash

! [ -f ".htaccess" ] && echo -e "\e[7;31m .htaccess not found \e[0m\n Run script in site directory.\n" && exit 1

[ -f ".htaccess_origin" ] && echo -e "\e[7;31m .htaccess_origin found \e[0m\n Remove this file before run script.\n" && exit 1

tempFile="temp_`date +%s`"

echo "php_flag display_startup_errors off"      >> $tempFile
echo "php_flag display_errors off"              >> $tempFile
echo "php_flag html_errors off"                 >> $tempFile
echo "php_flag log_errors on"                   >> $tempFile
echo "php_flag ignore_repeated_errors off"      >> $tempFile
echo "php_flag ignore_repeated_source off"      >> $tempFile
echo "php_flag report_memleaks on"              >> $tempFile
echo "php_flag track_errors on"                 >> $tempFile
echo "php_value docref_root 0"                  >> $tempFile
echo "php_value docref_ext 0"                   >> $tempFile
echo "php_value error_log `pwd`/PHP_errors.log" >> $tempFile
echo "php_value error_reporting 2047"           >> $tempFile
echo "php_value log_errors_max_len 0"           >> $tempFile
echo ""                                         >> $tempFile
echo "<Files PHP_errors.log>"                   >> $tempFile
echo "    Deny from all"                        >> $tempFile
echo "    Satisfy All"                          >> $tempFile
echo "</Files>"                                 >> $tempFile
echo ""                                         >> $tempFile

cat .htaccess >> $tempFile

mv .htaccess .htaccess_origin && mv $tempFile .htaccess
chown `stat --format="%U" .htaccess_origin`:`stat --format="%G" .htaccess_origin` .htaccess
echo -e "\e[1mDone!\e[0m"
echo -e "The original file is saved →  \e[36m.htaccess_origin\e[0m"
echo
