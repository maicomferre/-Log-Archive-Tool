#!/bin/bash

log_path=''
#source utils.sh

if [ '' == "$1" ]; then
	echo -e "\e[33mUsing /var/log by default.\e[0m"
	log_path="/var/log"
else
	log_path=$1
fi

if [ ! -d  "$log_path" ]; then
	echo -e "\e[31mDirectory $log_path not exists!\e[0m"
	exit
fi

echo -e "\e[32mReading...\e[0m"

read=$(ls "$log_path"/*.log)

count=0
run_as_root_message=0

file_width=50
size_width=5
action_width=10

printf "%-${file_width}s | %-${size_width}s |   %-${action_width}s |\n" \
	"File" "Size" "Action"

remember=""
readf=""  # Inicializar a variável readf
for x in $read
do 
	if [ "$(dirname "$x")" != "$remember" ]; then
		echo "$(dirname "$x")/"
		remember=$(dirname "$x")
	fi
	if [ ! -w "$x" ]; then
		echo -e "\e[31mYou doesn't have permission to $x.\e[0m"
		run_as_root_message=1
	else
        	fsize=$(stat -c%s "$x") # Tamanho em bytes
        	fsize=$(numfmt --to=iec "$fsize") # Formatar o tamanho
		action_color='\e[32m'
		action_text='To Archive'
		basenamex="$(basename "$x")"
		if [ "$fsize" == "0" ]; then
			action_color="\e[31m"
			action_text="Ignoring" 
		else
			((count++))
			#readf="$readf $x"  # Adicionar o caminho completo do arquivo
			readf="$readf $basenamex"  # Adicionar o caminho completo do arquivo
		fi
		printf "\e[32m %-${file_width}s \e[0m | %-${size_width}s | ${action_color} %-${action_width}s \e[0m |\n" " ↳ $basenamex" "$fsize" "$action_text"
	fi
done

if [ $run_as_root_message == 1 ]; then
	echo -e "\e[31mRun as root\e[0m"
	exit
fi

read -r -p "You want to archive $count logs in $log_path? (Y/n) " choise

if [ "$(echo "$choise" | tr "[:lower:]" "[:upper:]")" != 'Y' ]; then
	echo -e "\e[31mExiting...\e[0m"
	exit
fi

output_dir=""
output_name=logs_archive_$(date '+%F_%H-%M-%S_%s')_.tar.gz

if [ "$output_dir" == '' ]; then
	output_dir="$log_path/log_archive"
	mkdir -p -v "$output_dir"
	echo -e "Saving as default in folder \e[32m$output_dir\e[0m the file \e[32m$output_name\e[0m"
fi

output_dir="$output_dir"/"$output_name"

eval tar -czf "$output_dir" -C '$log_path' $readf
