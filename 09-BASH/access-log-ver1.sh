#!/bin/bash

variables=./variables.txt                 # файл для хранения значений времени последнего запуска и числа строк в логе при последнем запуске
accesslog=./access-4560-644067.log        # основной лог
message_mail=./message.txt                # файл который будем высылать на почту
lockfile=./mylockfile  			              # локфайл

# Устанавливаем опцию среды noclobber. Эта опция запрещает перезаписывать содержимое файла при перенаправлении.
if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null; then   

    # по сигналу завершения (ctrl-c) lockfile будет удалён  				   
    trap 'rm -f "$lockfile"; exit $?' TERM EXIT                      
     
  
  # проверка существует ли файл
  if [ -e $accesslog ]; then                                          
    
    # считываем из файла количество строк которое было в файле, дату прошлого запуска скрипта и определяем текущие
    line_counter=$(cat variables.txt | grep line_counter | awk -F"=" '{print $2}')  
    last_running_date=$(cat variables.txt | grep last_running_date | awk -F"=" '{print $2}')  
    line_counter_current=$(cat $accesslog | wc -l)    
    current_date=$(date '+%d-%m-%Y %H:%M:%S')         
           
    # перезаписываем в файл новые данные
    sed -i "s/line_counter=.*/line_counter=$line_counter_current/g" $variables               
    sed -i "s/last_running_date=.*/last_running_date=$current_date/g" $variables             

    # если число строк в новом логе больше чем было, т.е. он дописывался, то вычисляем строку с которой нужно анализировать файл  и анализируем с неё
    if [ $line_counter_current -gt $line_counter ]; then  
	       
      let "n=($line_counter_current - $line_counter)"
      echo "С момента последнего запуска скрипта с $last_running_date по $current_date" >> $message_mail
      echo "было дописано $n строк" >> $message_mail
	    echo "----------------------------------------------------------------------------------" >> $message_mail

      echo "IP адреса с наибольшим кол-вом запросов: " >> $message_mail
      tail -$n $accesslog | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 10 >> $message_mail

      echo "Список запрашиваемых URL с наибольшим кол-вом запросов: " >> $message_mail
	    tail -$n $accesslog | awk '{print $7}' | sort | uniq -c | sort -rn | head -n 10 >> $message_mail
      	   
      echo "Все ошибки со стороны клиента/сервера с  момента последнего запуска: " >> $message_mail
	    tail -$n $accesslog | awk '{print $9}' | grep -E  '^(4|5)([0-9][0-9])' | sort | uniq -c | sort -nr >> $message_mail
	
	    echo "Список всех кодов возврата с указанием их кол-ва с момента последнего запуска:" >> $message_mail
      tail -$n $accesslog | awk '{print $9}' | grep -E '[0-9]{3}' | sort | uniq -c | sort -rn >> $message_mail

    # анализ файла уменьшенного лога (всего) 
    else   
           	
	    echo "С момента последнего запуска скрипта лога с $last_running_date по $current_date лог был перезаписан" >> $message_mail
	    echo "----------------------------------------------------------------------------------" >> $message_mail
    
      echo "IP адреса с наибольшим кол-вом запросов: " >> $message_mail
	    cat $accesslog | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 10 >> $message_mail
 	
      echo "Список запрашиваемых URL с наибольшим кол-вом запросов: " >> $message_mail
	    cat $accesslog | awk '{print $7}' | sort | uniq -c | sort -rn | head -n 10 >> $message_mail
    
      echo "Все ошибки со стороны клиента/сервера с  момента последнего запуска: " >> $message_mail
	    cat $accesslog | awk '{print $9}' | grep -E  '^(4|5)([0-9][0-9])' | sort | uniq -c | sort -nr >> $message_mail
		       
      echo "Список всех кодов возврата с указанием их кол-ва с момента последнего запуска:" >> $message_mail
	    cat $accesslog | awk '{print $9}'| grep -E '[0-9]{3}' | sort | uniq -c | sort -rn >> $message_mail
    
    fi       
      
    mail -s "Анализ лога nginx" root@localhost < $message_mail    
    rm $message_mail  
      
    else 
     echo "The file accesslog does not exist"  >&2
     exit 1
  fi

    rm -f "$lockfile"

else
	echo "Failed to acquire lockfile: $lockfile."
	echo "Held by $(cat $lockfile)"
fi