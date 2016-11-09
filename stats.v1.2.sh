#!/bin/bash
# To use this script:
#   $bash < <(curl http://scriptkiddie.tech/scripts/bash/stats.v1.2)
# Or
#   $wget http://scriptkiddie.tech/scripts/bash/stats.v1.2
# Referenced files
 HOST=$(echo "Hostname: ";hostname)
 OS=$(cat /etc/redhat-release|sed -r 's/^([^ ]+)\ [^0-9]+([0-9.]+).+$/\1\ \2/')
 CPV=$(echo "cPanel: ";cat /usr/local/cpanel/version)
 APV=$(httpd -v|head -n1|awk '{print$3}'|sed -r 's/\//\ /')
 EA3H=$(echo -n 'Handler: ';/usr/local/cpanel/bin/rebuild_phpconf --current|grep 'PHP5'|awk '{print$3}')
 EA4H=$(echo -n 'Primary Handler: '; def_handler=$(/usr/local/cpanel/bin/rebuild_phpconf --current|egrep '^DEFAULT'|awk '{print$NF}');/usr/local/cpanel/bin/rebuild_phpconf --current|egrep "^${def_handler}"|awk '{print$3}')
 MPM=$(httpd -V|egrep '^Server MPM'|sed -r 's/^[^M]+([^:]+:)[^a-zA-Z]+(.+)$/\1 \2/')
 PHPV=$(php -v|head -n1|awk '{print$1" "$2}')
 MSQV=$(mysql -V|sed -r 's/^([^ ]+)([^0-9.]+([0-9.]+)){2}.+$/\1\ \3/')
 CPUS=$(echo "CPU(s): ";grep --count ^processor /proc/cpuinfo)
 TMEM=$(echo "Total Mem: ";free -m|awk '{print$2}'|sed -n '2 p'|sed "s/$/MB/")
 KBUF=$(grep key_buffer /etc/my.cnf)
 IBUF=$(grep innodb_buffer_pool_size /etc/my.cnf)
 MEML=$(cat `php -i|grep "Loaded Configuration File"|awk '{print$5}'|head -1`| grep memory_limit)
 LCML=$(php -i|grep "Loaded Configuration File"|awk '{print$5}'|head -1)
 AGCF=$(cat /usr/local/apache/conf/includes/pre_virtualhost_global.conf)
 A1CF=$(cat /usr/local/apache/conf/includes/pre_virtualhost_1.conf)
 A2CF=$(cat /usr/local/apache/conf/includes/pre_virtualhost_2.conf)

# Font colors and formatting. You can change these to whatever colors you want. Check out http://misc.flogisoft.com/bash/tip_colors_and_formatting for a good list.
 LRED='\e[91m' #Light Red
 LCYA='\e[96m' #Light Cyan
 LYEL='\e[93m' #Light Yellow
 LGRE='\e[92m' #Light Green
 LMAG='\e[95m' #Light Magenta
 LBLU='\e[94m' #Light Blue
 BLUB='\e[44m' #Blue background
 BOLD='\e[1m'  #Bold Font
 NC='\e[0m'    #Reset to normal, uncolored font

# Checks for the hostname, the OS version, cPanel version, Easy Apache version, and whether it's EA3 or EA4.
 echo ""
 echo "Checking the current server configurations:"
 echo $HOST|column -t
 echo $OS|column -t
 echo $CPV|column -t
 echo $APV|column -t
 echo ""
   if [[ $(httpd -V|egrep "HTTPD_ROOT=\"\/etc\/apache2") ]];
      then echo -e "${BOLD} ${BLUB}--EasyApache 4 in use--${NC}"; echo $EA4H;
      else echo -e "${BOLD} ${BLUB}--EasyApache 3 in use--${NC}"; echo $EA3H;
   fi

# Checks for MPM, PHP version, CPU(s), total memory.
 echo $MPM|column -t
 echo $PHPV|column -t
 echo $CPUS|column -t
 echo $TMEM|column -t

# Checks MySQL version and the key_buffer and innodb_buffer sizes, performace schema, and the MySQL storge engines:
 echo ""; echo "Checking MySQL and current buffers:"
 echo $MSQV|column -t
 mysql -V|grep '5.6' &> /dev/null
   if [ $? == 0 ];
      then
         cat /etc/my.cnf |grep perform;
   fi 
 echo ""
 echo "$KBUF"
 echo ""
 echo "$IBUF"
 echo ""
 echo "ENGINE DataMB IndexMB TotalMB NumTables" > sqlstorage.txt
 echo "Checking MySQL storage engines:"
 mysql -e "SELECT ENGINE,ROUND(SUM(data_length) /1024/1024, 1) AS 'Data MB', ROUND(SUM(index_length)/1024/1024, 1) AS 'Index MB', ROUND(SUM(data_length + index_length)/1024/1024, 1) AS 'Total MB', COUNT(*) 'Num Tables' FROM  INFORMATION_SCHEMA.TABLES WHERE  table_schema not in ('information_schema', 'performance_schema') GROUP BY ENGINE;" >> sqlstorage.txt|head -1 sqlstorage.txt > sqlstorage2.txt;tail -3 sqlstorage.txt >> sqlstorage2.txt; rm -f sqlstorage.txt; cat sqlstorage2.txt|column -t
 rm -f sqlstorage2.txt
 # echo "";grep ENGINE sqlstorage2.txt|awk '{print $1" ",$2" ",$3" ",$4" "}';grep 'InnoDB' sqlstorage2.txt |awk '{ print "\033[1;31m"$1" ",$2" ""\033[0m",$3" ",$4" "}';grep MEMORY sqlstorage2.txt|awk '{print $1" ",$2" ",$3" ",$4" "}'; grep MyISAM sqlstorage2.txt|awk '{ print "\033[0;32m"$1" ""\033[0m",$2" ","\033[0;32m"$3" ""\033[0m",$4" "}'|column

 echo ""; echo "Checking various memory_limit settings:"

# Checks for memory_limits based on the current loaded php.ini according to php -i and checks to see if there are any custom EA4 .local.ini files.
 echo -e "Current loaded php.ini file: `echo -e ${LMAG}$LCML`"
 echo -e $MEML${NC}
 echo ""

# For EA4 PHP 5.4
   if test -e /opt/cpanel/ea-php54/root/etc/php.ini; 
      then 
         (if test -e /opt/cpanel/ea-php54/root/etc/php.d/local.ini; 
            then echo -e "Limit in ${LRED}/opt/cpanel/ea-php54/root/etc/php.d/local.ini:";
         fi);
         (if test -e /opt/cpanel/ea-php54/root/etc/php.d/local.ini; 
            then grep -Hn memory_limit /opt/cpanel/ea-php54/root/etc/php.d/local.ini;
         fi);
      echo -e ${NC};
   fi

# For EA4 PHP 5.5
   if test -e /opt/cpanel/ea-php55/root/etc/php.ini;
      then 
         (if test -e /opt/cpanel/ea-php55/root/etc/php.d/local.ini; 
            then echo -e "Limit in ${LCYA}/opt/cpanel/ea-php55/root/etc/php.d/local.ini:";
         fi);
         (if test -e /opt/cpanel/ea-php55/root/etc/php.d/local.ini; 
            then grep memory_limit /opt/cpanel/ea-php55/root/etc/php.d/local.ini;
         fi);
      echo -e ${NC};
   fi

# For EA4 PHP 5.6
   if test -e /opt/cpanel/ea-php56/root/etc/php.ini;
      then 
         (if test -e /opt/cpanel/ea-php56/root/etc/php.d/local.ini; 
            then echo -e "Limit in ${LYEL}/opt/cpanel/ea-php56/root/etc/php.d/local.ini:";
         fi);
         (if test -e /opt/cpanel/ea-php56/root/etc/php.d/local.ini; 
            then grep memory_limit /opt/cpanel/ea-php56/root/etc/php.d/local.ini;
         fi);
      echo -e ${NC};
   fi

# For EA4 PHP 7.0
   if test -e /opt/cpanel/ea-php70/root/etc/php.ini;
      then 
         (if test -e /opt/cpanel/ea-php70/root/etc/php.d/local.ini;
            then echo -e "Limit in ${LGRE}/opt/cpanel/ea-php70/root/etc/php.d/local.ini:";fi);
         (if test -e /opt/cpanel/ea-php70/root/etc/php.d/local.ini;
            then grep memory_limit /opt/cpanel/ea-php70/root/etc/php.d/local.ini;fi);
      echo -e ${NC};
   fi

# Menu for pre_virtualhost_global.conf

function apache_confs
{
   echo "Do you want to see Apache configurations?"
   echo " (1) Yup"
   echo " (2) No thanks"
   read apache_menu_screen

case $apache_menu_screen in
   1)
      echo ""
   if [ -s /usr/local/apache/conf/includes/pre_virtualhost_global.conf ];
      then
         echo -e "Contents of $LBLU/usr/local/apache/conf/includes/pre_virtualhost_global.conf:"
         echo -e "$AGCF$NC"
      else
         :
   fi
   if [ -s /usr/local/apache/conf/includes/pre_virtualhost_1.conf ];
      then
         echo -e "Contents of $LRED/usr/local/apache/conf/includes/pre_virtualhost_1.conf:"
         echo -e "$A1CF$NC"
      else
         :
   fi
   if [ -s /usr/local/apache/conf/includes/pre_virtualhost_2.conf ];
      then
         echo -e "Contents of $LMAG/usr/local/apache/conf/includes/pre_virtualhost_2.conf:"
         echo -e "$A2CF$NC"
      else
         :
   fi
      ;;

   2)
      ;;

esac
}
apache_confs
