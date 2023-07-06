#!/bin/bash
# This code will read an maillog file for an postfix server, I used for files with 10K lines, plesase split 
# the file if is neccesarie

# this the syntaxis:
# ./sort_mail.sh <maillog_filename>
# The result will be a file as reporte_<maillog_filename>.csv

long_ID=12 #Long for IDs on POSTFIX, you can change for your postfix version

long_log=$(wc -l $1)
LOG=()
i=0
while read -r log;do
 LOG[i]=$log
 i=$(( i + 1 ))
done < "$1"

filter_ID=$(( long_ID + 1 ))
i=0
for ((i = 0; i<${#LOG[@]};i++))
do
   ID[i]=$(echo "${LOG[i]}" | awk -F':' '{ print $4}'| cut -c2-$filter_ID)
   DATE[i]=$(echo "${LOG[i]}" | cut -c1-15)
   DATEF[i]=$(date -d "${DATE[i]}" +"%H:%M:%S %d/%m/%Y")
   DATA[i]=$(echo "${LOG[i]}" | cut -d':' -f5)
done

FLOW=()
i=0
for element1 in "${DATA[@]}"
do
  if [[ $element1 == *"to=<"* ]]; then
    FLOW[i]="to"
  fi
  if [[ $element1 == *"from=<"* ]]; then
    FLOW[i]="from"
  fi
  i=$(( i + 1 ))
done


EMAIL=()
i=0
for element2 in "${DATA[@]}"
do
  if [[ $element2 == *"to=<"* ]]; then
    email=$(echo "$element2" | grep -oP '(?<=to=<)[^>]+')
    EMAIL[i]="$email"
  fi
  if [[ $element2 == *"from=<"* ]]; then
    email=$(echo "$element2" | grep -oP '(?<=from=<)[^>]+')
    EMAIL[i]="$email"
  fi
  i=$(( i + 1 ))
done


CLIENT=()
i=0
for element3 in "${DATA[@]}"
do
  if [[ $element3 == *"client"* ]]; then
    client=$(echo "$element3" | sed -n 's/.*\[\([0-9.]*\)\].*/\1/p')
    CLIENT[i]="$client"
  fi
  i=$(( i + 1 ))
done

RELAY=()
i=0

for element4 in "${DATA[@]}"
do
  if [[ $element4 == *"relay"* ]]; then
    relay=$(echo "$element4" | sed -n 's/.*\[\([0-9.]*\)\].*/\1/p')
    RELAY[i]="$relay"
  fi

  i=$(( i + 1 ))

done

valid_reg="^[A-F0-9]{$long_ID}$"

for ((i=0; i<${#ID[@]}; i++))
do
  if [[ ! ${ID[i]} =~ $valid_reg ]]; then
    ID[i]=''
    EMAL[i]=''
  fi

done


for ((i = 0; i<${#ID[@]};i++))
do
  echo "$i;${ID[i]};${DATEF[i]};${FLOW[i]};${EMAIL[i]};${CLIENT[i]};${RELAY[i]}" >> reporte_$1.csv
done
