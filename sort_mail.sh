#!/bin/bash
# This code will read an maillog file for an postfix server, I used for files with 10K lines, plesase split 
# the file if is neccesarie

# this the syntaxis:
# ./sort_mail.sh <maillog_filename>
# The result will be a file as reporte_<maillog_filename>.csv

# Copyright 2023 Guillermo Espejo  <guillermo.espejo@cip.org.pe
#
# This software may be used and distributed according to the terms of
# the GNU General Public License version 2 or later.


export long_ID=10 #Long for IDs on POSTFIX, you can change for your postfix version

long_log=$(wc -l $1) #check long of log

echo $(date) " We have to proccess " $long_log " lines"

LOG=()              
    
    
function MAIN () {

#Create a matrix with the log


i=0
while read -r log;do
    LOG[i]=$log
    i=$(( i + 1 ))
done < "$1"


echo $(date) " STARTING first proccessing"

filter_ID=$(( long_ID + 1 ))

total=${#LOG[@]}
progress=0

   
i=0


for ((i = 0; i<${#LOG[@]};i++))
do
   ID[i]=$(echo "${LOG[i]}" | awk -F':' '{ print $4}'| cut -c2-$filter_ID)
   DATE[i]=$(echo "${LOG[i]}" | cut -c1-15)
   DATEF[i]=$(date -d "${DATE[i]}" +"%H:%M:%S %d/%m/%Y")
   DATA[i]=$(echo "${LOG[i]}" | cut -d':' -f5)
   DATA2[i]=$(echo "${LOG[i]}" | cut -d':' -f6-90)


   # Calculates actual progress
   progress=$(printf "%.2f" "$(echo "scale=2; 100 * ($i + 1) / $total" | bc)")

   # shows the progress
   printf "\rProgreso: $progress%%"


done

printf "\n"
echo $(date) " STARTING Flow proccess (determining if is to or from)"

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

echo $(date) " STARTING sender and recipient extraction"

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


echo $(date) " STARTING client extraction"

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

echo $(date) " STARTING relay extraction"

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
### IN WORK
echo $(date) " STARTING subject extraction"
SUBJECT=()
i=0

for element5 in "${DATA2[@]}"
do
  #echo $i $element5
  if [[ $element5 == *"header Subject"* ]]; then
#    echo "$i " "$element5"
  #  subject=$(echo "$element5")
    SUBJECT[i]=$(echo "$element5" | cut -d";" -f1)
  fi

  i=$(( i + 1 ))

done

echo $(date) " Cleanning no valid registers"
valid_reg="^[A-F0-9]{$long_ID}$"

for ((i=0; i<${#ID[@]}; i++))
do
  if [[ ! ${ID[i]} =~ $valid_reg ]]; then
    ID[i]=''
    EMAIL[i]=''
    #SUBJECT[i]=''
  fi

done

echo $(date) " Generating Report (Final Process)..."

#Generates a report
#=====================

for ((i = 0; i<${#ID[@]};i++))
do
  echo "$i;${ID[i]};${DATEF[i]};${FLOW[i]};${EMAIL[i]};${CLIENT[i]};${RELAY[i]};${SUBJECT[i]}" >> reporte_"$namelog""$idfile".csv
done

}


#Accelerate spliting in files

i=0
export namelog=$(echo $1)
export idfile=$(echo $RANDOM)
split -l 10000 -d $1 $1.$idfile.
cantfiles=$(ls $1.$idfile.*|wc -l)
echo "For better performance I have to split the file in " $cantfiles " parts"
ls $1.$idfile.* > listofpartfiles.$idfile


while read -r partfile;do

 count=$(( count + 1 ))
 echo "Working file $count" " of " $cantfiles 
 MAIN $partfile


done < listofpartfiles.$idfile
rm -rf listofpartfiles.$idfile
echo "DONE"" Please check report"  "reporte_""$namelog""$idfile".csv
