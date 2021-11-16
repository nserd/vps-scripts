#!/bin/bash

function init-color-vars {
    cLightRedIt="\e[3;91m"
    cLightYelIt="\e[3;93m"
    cLightBluIt="\e[3;94m"
    cLightMgnIt="\e[3;95m"
    cLightCynIt="\e[3;96m"

    cRed="\e[31m"
    cRedB="\e[7;31m"
    cRedBr="\e[91m"
    cGrn="\e[32m"
    cGry="\e[37m"
    cCyn="\e[1;36m"
    cMgn="\e[35m"
    cEnd="\e[0m"
}

function get-distribution {
    echo "`cat /etc/*-release | grep PRETTY_NAME | awk -F '=' '{print $2}' | tr -d '"'`"
}

function get-panel {
    if [ -n "$VESTA" ]
    then
        echo -e " ${cLightYelIt}#VestaCP${cEnd}"
    elif [ `getent passwd bitrix | wc -l` -ne 0 ]
    then
        echo -e " ${cLightRedIt}#BitrixVM${cEnd}"
    elif [ `systemctl cat ihttpd 2>/dev/null | wc -l` -ne 0 ]
    then
        echo -e " ${cLightBluIt}#ISPManager${cEnd}"
    elif [ `systemctl cat nginxb 2>/dev/null | wc -l` -ne 0 ]
    then
        echo -e " ${cLightMgnIt}#Brainy${cEnd}"
    elif [ `systemctl cat fastpanel2 2>/dev/null | wc -l` -ne 0 ]
    then
        echo -e " ${cLightCynIt}#FastPanel${cEnd}"
    else
        echo
    fi
}

function print-failed-services {
    if systemctl | grep failed > /dev/null 2>&1
    then
        echo -en "${cRedB}There are failed services → ${cEnd} "
	systemctl | grep failed | awk '{print $2}' | tr '\n' ' ' | sed 's# #, #g' | sed 's#..$##' 
	echo
    fi
}

function print-oom-info {
    if [ `dmesg -l err | egrep -ic "oom|Out of memory"` -ne 0 ]
    then
        echo
        echo -e "${cRed}Some processes were killed by OOM Killer${cEnd}"
	    echo -e "  ${cGry}(use 'dmesg -Tl err' to more details)${cEnd}"
    fi
}

function print-conf-files {
    if which nginx > /dev/null 2>&1
    then
        echo
        echo -e "* ${cCyn}Nginx${cEnd} ${cGry}(nginx -T)${cEnd}"
        nginx -T 2>/dev/null | grep "# configuration file" | awk '{print $4}' | tr -d ':' | sed 's#^#  #'
    fi
    if which apache2 > /dev/null 2>&1 || which httpd > /dev/null 2>&1
    then
        echo
        echo -e "* ${cCyn}Apache${cEnd} ${cGry}(-t -D DUMP_VHOSTS)${cEnd}"
        sh -c "$apacheCmd" | egrep -v "VirtualHost" | sed 's#^         ##' | sed 's#^#  #'
    fi
}

function print-site-roots {
    nginxConfFiles=(`nginx -T 2>/dev/null | grep "# configuration file" | awk '{print $4}' | tr -d ':' | tr '\n' ' '`)
    apacheConfFiles=(`sh -c "$apacheCmd" | awk '{print $NF}' | grep "/" | tr -d "(|)" | awk -F ':' '{print $1}' | tr '\n' ' '`)
    allConf=(`echo ${nginxConfFiles[@]} && echo ${apacheConfFiles[@]}`)

    if [ ${#allConf[@]} -ne 0 ]
    then
	    echo
        echo -e "* ${cCyn}Site roots${cEnd}"
        for i in ${allConf[@]}
        do 
            egrep "root|DocumentRoot" $i | awk '{print $2}' | tr -d ';|"' | grep "^/" | sed 's#^#  #'
            grep 'set $root_path' $i | awk '{print $3}' | tr -d ';|"' | grep "^/" | sed 's#^#  #' # ISP site roots
        done | sort | uniq
    fi
}

function print-running-containers {
    if which docker > /dev/null 2>&1 && [ `docker ps -q 2>/dev/null | wc -l` -ne 0 ]
    then	
        echo
        echo -e "* ${cCyn}Running docker containers${cEnd}"
	    echo -e "`docker ps --format "[${cMgn}{{.ID}}${cEnd}] {{.Image}} {{.Ports}}" 2>/dev/null | sed 's#^#  #'`"  
    fi
}

function print-php-fpm {
    phpServices=(`systemctl list-unit-files | grep -Ei "php.*fpm" | awk '{print $1}' | tr '\n' ' '`)

    if [ ${#phpServices[@]} -ne 0 ]
    then
        echo
        echo -e "* ${cCyn}PHP-FPM${cEnd}"
        for i in ${phpServices[@]}
        do
            systemctl is-active $i 2>&1 >/dev/null
            [ `echo $?` -eq 0 ] && echo -e "$i [${cGrn}active${cEnd}]" | sed 's#^#  #' || echo -e "$i [${cRedBr}inactive${cEnd}]" | sed 's#^#  #'
        done
    fi
}

function print-pm2 {
    if which pm2 > /dev/null 2>&1
    then
	    echo
        echo -e "* ${cCyn}PM2${cEnd} ${cGry}(NodeJS proccess manager)${cEnd}"
	    export HOME='/root'
	    pm2 list | sed 's#^#  #' 
    fi
}

init-color-vars

distr=`get-distribution` && [ -z "$distr" ] && distr="Unknown"
[ -f /etc/apache2/envvars ] && source /etc/apache2/envvars && apacheCmd="apache2 -t -D DUMP_VHOSTS 2>/dev/null" || apacheCmd="httpd -t -D DUMP_VHOSTS 2>/dev/null"

echo
echo -en "${cGry}OS:${cEnd} \e[1m$distr\e[0m"; get-panel
echo -e "${cGry}`uptime | sed 's#^ ##'`${cEnd}"
print-failed-services
print-oom-info
print-conf-files
print-site-roots
print-php-fpm
print-pm2
print-running-containers
echo
