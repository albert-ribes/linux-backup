#!/bin/bash

#------------------------------------------
# VARIABLES
#------------------------------------------
. backup.conf
working_path=${PWD} #"/usr/local/"
logs_path="${working_path}/logs"


version="0.1"
author="Albert Ribes"
status="ok"
date=`date -I`
day=$(date +%d)
month=$(date +%m)
year=$(date +%Y)
previous_month=`expr $month - 1`
debug=true
#debug=false

previous_day=`date -I -d "1 day ago"`

next_day_full=`date -I -d "1 day ago"`
next_day_short=`date +%d -d "next day"`

day_of_week=$(date +%w) #0..6; 6=diumenge
initial_time=$(date +%H:%M:%S)
#echo "[INFO] Today's date = ${date},time = ${initial_time}, day_of_week = ${day_of_week}, previous_day = ${previous_day}, next_day_short = ${next_day_short}."

# Hostname to add to the files.
hostname="$(hostname)"


#source_dirs="   /home/projects/backup/source3,      /home/projects/backup/source4 "
source_dirs="$(echo -e "${source_dirs}" | tr -d '[:space:]')"
set -f                      # avoid globbing (expansion of *).
source_dirs=(${source_dirs//,/ })

#for dir in "${!source_dirs[@]}"
#do
#    echo "$dir=>${source_dirs[dir]}"
#done
set +f

log_file="backup_${date}-$(date +%H%M%S).log"


#imtl_bkp_dir="/root" # Copying directories
compress_imtl_bkp="1" # Compress copies.  1 = Yes   0 = No
rotate_imtl_bkp="1" # Rotate copies.  1 = Yes   0 = No
max_number_imtl_bkp="8" # Number of copies to preserve.
tar_args="cpfJ"
tar_exten=".tar.xz"

#------------------------------------------
# FUNCTIONS
#------------------------------------------

send_mail()
{
	if [ "$1" == "ok" ]; then
		final_time=$(date +%H%M%S)
		printf "Subject: ${type_backup} backup OK \
		\n\nBackup from ${hostname} initiated at ${initial_time} finished succesfully at ${final_time}."\
		| ssmtp albert.ribes@gmail.com >> $logs_path/$log_file
	else
		printf "Subject: ${type_backup} backup KO\n\n Something went wrong in the backup from ${hostname} initiated at ${initial_time}. \
        Please review the log file ${logs_path}/${log_file}" | ssmtp albert.ribes@gmail.com >> $logs_path/$log_file
	fi
}

help_me()
{
	echo -e "Backup utility v${version} by ${author}.\n"
	echo -e "Usage: backup [OPTIONS]\n"
	echo -e "OPTIONS:"
	echo -e "-h, --help			This help"
	echo -e "-t TYPE, --type TYPE		Where TYPE = [ full | inc ]\n"
}

end_function()
{
	#send_mail $status
	exit 1
}

#------------------------------------------
# GRAMMAR CHECKS
#------------------------------------------

if [ $# -eq 0 ]; then
	help_me
	exit 1
else
	#echo "$1"
	if [ "$1" == "-h" -o "$1" == "--help" ]; then
		help_me
		exit 1
	elif [ "$1" == "-t" -o "$1" == "--type" ]; then
		if [ -z "$2" ]; then
			echo -e "Please introduce the argument TYPE = [ full | inc ]\n"
			exit 1
		else
			#echo "$2"
			if [ "$2" != "full" -a "$2" != "inc" ]; then
				echo -e "Wrong arguments supplied\n"
				exit 1
			else
				type_backup=$2
				if [ "$type_backup" == "full" ]; then
					type_backup_short="full"
				elif [ "$type_backup" == "inc" ]; then
					type_backup_short="inc"
				fi
			#Today's backup folder
			full_backup_path="${target_dir}/${type_backup}/${date}/"
			fi
		fi
	
	else
		echo -e "Wrong arguments supplied\n"
		exit 1
	fi
fi



# Check logs directory exists
if [ ! -d ${logs_path} ]; then
	mkdir ${logs_path}
	echo -e "[INFO]	Creating logs directory '${logs_path}'.\n"
fi


if [ "$debug" = "true" ]; then
	echo -e "+++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logs_path/$log_file
	echo -e "- CONFIGURED PARAMETERS:" >> $logs_path/$log_file
	echo -e "source_dirs='${source_dirs}'" >> $logs_path/$log_file
	echo -e "target_dir='${target_dir}'" >> $logs_path/$log_file
	echo -e "full_backup_path='${full_backup_path}'" >> $logs_path/$log_file
	echo -e "working_path='${working_path}'" >> $logs_path/$log_file
	echo -e "logs_path='${logs_path}'" >> $logs_path/$log_file
	echo -e "log_file='${log_file}'" >> $logs_path/$log_file
	echo -e "anual_ret='${monthly_ret}, monthly_ret='${monthly_ret}, daily_ret'${daily_ret}" >> $logs_path/$log_file
	echo -e "+++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logs_path/$log_file
fi

#------------------------------------------
# MAIN PROGRAM
#------------------------------------------

#echo -e "\n"
echo "Timestamp: ${date}_${initial_time}" >> $logs_path/$log_file

# Check and create "logs" directory
echo -e "[INFO]	Checking logs directory... " >> $logs_path/$log_file
if [ ! -d ${logs_path} ]; then
  printf "Directory '${logs_path}' NOT found. Directory will be created.\n" >> $logs_path/$log_file
  mkdir ${logs_path}
fi

# Check need root privilegies
echo -e "[INFO]	Checking root privileges... " >> $logs_path/$log_file
if [ $(id -u) != 0 ]; then
	echo "[ERROR]	$0 need root privilegies. Exiting!\n\n" >> $logs_path/$log_file
  	status="ko"
	end_function
fi

# Check backup source directory exists
echo -e "[INFO]	Checking backup source directory... " >> $logs_path/$log_file

for dir in "${source_dirs[@]}"
do
	if [ ! -d ${dir} ]; then
		printf "[ERROR]	Backup source directory '${dir}' NOT found. Exiting!\n\n" >> $logs_path/$log_file
			status="ko"
			end_function
	fi
done

#
#if [ ! -d ${source_dir} ]; then
#  printf "\n[ERROR]	Backup source directory '${source_dir}' NOT found. Exiting!\n\n" >> $logs_path/$log_file
#  exit 1
#else
#   echo "OK" >> $logs_path/$log_file
#fi

# Check backup target directory exists
echo -e "[INFO]	Checking backup target directory... " >> $logs_path/$log_file
if [ ! -d ${target_dir} ]; then
	printf "[ERROR]	Backup target directory '${target_dir}' NOT found. Exiting!\n\n" >> $logs_path/$log_file
	status="ko"
	end_function
fi

# Check and create "current" directory
echo -e "[INFO]	Creating backup directories... " >> $logs_path/$log_file
if [ ! -d ${target_dir}/${type_backup} ]; then
  printf "Directory '${target_dir}/${type_backup}' NOT found. Directory will be created.\n" >> $logs_path/$log_file
  mkdir ${target_dir}/${type_backup}
fi

# Check space in backup disk
echo -e "[INFO]	Checking disk space... " >> $logs_path/$log_file
diskusage=$(df -k $target_dir |awk '{print $5}' |sed '1d;s/%//')5
if [ $diskusage -gt $diskspace ]
	then
	echo "[ERROR]	The destination disk for backups is full. Current disk usage ${diskusage}%." >> $logs_path/$log_file
	status="ko"
	end_function
fi

# BACKUP EXECUTION
if [ "$type_backup" == "full" ]; then
	for dir in "${source_dirs[@]}"
	do
		options="-avh --progress --delete"
		echo -e "[INFO]	Executing rsync" >> $logs_path/$log_file
		echo -e "----------------------------------------------------" >> $logs_path/$log_file
		rsync $options $dir $full_backup_path --log-file=$logs_path/$log_file > /dev/null
		echo -e "----------------------------------------------------" >> $logs_path/$log_file
		# Backup compression
		echo -e "[INFO]	Compressing files" >> $logs_path/$log_file
		tar -zcvf ${target_dir}/full/${hostname}-FULL-${date}.tar.gz -C $full_backup_path . > /dev/null
		rm -R $full_backup_path
		# Delete old backups according to configured retention
		#if [ "$type_backup" == "monthly" ]; then
		#	(cd ${target_dir}/${type_backup} && ls -1tr | head -n -${monthly_ret} | xargs -d '\n' rm -r -f --)
		#fi
	done
fi

if [ "$type_backup" == "inc" ]; then
	
	for dir in "${source_dirs[@]}"
	do
		#echo "$dir"
		options="-avh --progress --delete"
		if [ -d ${target_dir}/${type_backup}/${previous_day} ]; then
			options="$options --link-dest=${target_dir}/${type_backup}/${previous_day}"
		fi
		echo -e "[INFO]	Executing rsync:" >> $logs_path/$log_file
		echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> $logs_path/$log_file
		echo -e "rsync $options $dir $full_backup_path --log-file=$logs_path/$log_file > /dev/null" >> $logs_path/$log_file
		rsync $options $dir $full_backup_path --log-file=$logs_path/$log_file > /dev/null
		echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" >> $logs_path/$log_file
	done

	# If it's the last day of the month, compress and archive the backup
	if [ "$next_day_short" == "01" ]; then
		if [ ! -d ${target_dir}/full ]; then
			mkdir ${target_dir}/full
		fi
		# Backup compression
		echo -e "[INFO]	Compressing files" >> $logs_path/$log_file
		echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> $logs_path/$log_file
		echo -e "tar -zcvf ${target_dir}/full/${hostname}-MONTHLY-${date}.tar.gz -C $full_backup_path . " >> $logs_path/$log_file
		echo -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" >> $logs_path/$log_file
		tar -zcvf ${target_dir}/full/${hostname}-MONTHLY-${date}.tar.gz -C $full_backup_path . > /dev/null
		# Keep only ${monthly_ret} previous backups
		if [ $monthly_ret != -1 ]; then
			(cd ${target_dir}/full && ls -1tr ${hostname}-MONTHLY* | head -n -${monthly_ret} | xargs -d '\n' rm -r -f --)
		fi
	fi

	#If it's the first day of the month, delete all the previous incremental backups and logs
	if [ "$next_day_short" == "02" ]; then
		last_month=`date +%m -d "1 day ago"`
		year_previous_month=`date +%Y -d "1 day ago"`
		#echo -e "rm -r ${target_dir}/inc/${year_previous_month}-${last_month}-*"
		#echo -e "rm -rf ${target_dir}/inc/${year_previous_month}-${last_month}*"
		rm -rf $target_dir/inc/$year_previous_month-$last_month* 
		#echo -e "rm -rf $logs_path/backup_${year_previous_month}-${last_month}*"
		rm -rf $logs_path/backup_${year_previous_month}-${last_month}*

	fi

	# If it's the last day of the course, compress and archive the backup
	if [ "$day" == "01" -a "$month" == "07" ]; then
		if [ ! -d ${target_dir}/full ]; then
			mkdir ${target_dir}/full
		fi
		# Backup compression
		echo -e "[INFO]	Compressing files" >> $logs_path/$log_file
		tar -zcvf ${target_dir}/full/${hostname}-ANUAL-${date}.tar.gz -C $full_backup_path . > /dev/null
		# Keep only ${anual_ret} previous backups
		if [ $anual_ret != -1 ]; then
			(cd ${target_dir}/full && ls -1tr ${hostname}-ANUAL* | head -n -${anual_ret} | xargs -d '\n' rm -r -f --)
		fi

	fi
fi
: <<'END'
	#if [ "$month" != "01" ]; then
		#echo -e "Deleting ${year}_${previous_month}*"
		#cd ${target_dir}/${type_backup} && find * -maxdepth 0 -name "${year}_${previous_month}*" -prune -o -exec rm -rf '{}' ';'
	#fi	
	#(cd ${target_dir}/${type_backup} && ls -1tr | head -n -${daily_ret} | xargs -d '\n' rm -r -f --)
END


# SEND e-MAIL
echo -e "[INFO]	Sending an e-mail" >> $logs_path/$log_file
#send_mail $status

final_date=`date -I`
final_time=$(date +%H:%M:%S)
echo "Timestamp: ${final_date}_${final_time}" >> $logs_path/$log_file

echo -e "[INFO]	Program finished successfully" >> $logs_path/$log_file


