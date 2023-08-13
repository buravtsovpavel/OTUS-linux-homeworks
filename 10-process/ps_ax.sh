#!/bin/bash

echo -e 'USER\tPID\tUID\tSTAT\tTTY\tCOMMAND'

for pid in $(ls /proc | grep -E "^[0-9]+$" | sort -n)
 do   
    if [[ -f /proc/$pid/status ]] 
     
     then  
       
      PID=$pid
         
      STAT=$(cat /proc/$PID/status | awk '/State/{print $2}' 2>/dev/null)

      Uid=$(awk '/Uid/{print $2}' /proc/$PID/status 2>/dev/null)
      
      if [[ $Uid -ne 0 ]]
       then 
        User=$(grep $Uid /etc/passwd | awk -F ":" '{print $1}' 2>/dev/null)
      else
        User='root'
      fi
       
      tty=$(ls -l /proc/$pid/fd/ | grep -E '\/dev\/tty|pts' | cut -d\/ -f3,4 | uniq)
	       
      TTY=$(awk '{ if ($7 == 0) { printf "?"} 
                    else { printf "'"$tty"'" }}' /proc/$pid/stat 2>/dev/null)
      
      COMMAND=$(awk -F " " '{print $2}' /proc/$PID/stat 2>/dev/null)

    echo -e "$User"'\t'"$PID"'\t'"$Uid"'\t'"$STAT"'\t'"$TTY"'\t'"$COMMAND"
      
    fi
 done