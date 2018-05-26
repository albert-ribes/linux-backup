#!/bin/bash
rm -R source*/*
rm -R target/*
rm -R logs/*

loop_conunt=0
for year in {2000..2001}
do
	if [ ! -d source1 ]; then
		mkdir source1
	fi
	if [ ! -d source2 ]; then
		mkdir source2
	fi

	mkdir source1/folder1_${year}
	mkdir source2/folder2_${year}
	for month in {1..12}
	do
		echo "#Year-Month: ${year}-${month} ---------------------------------------------------- "
		mkdir source1/folder1_${year}/subfolder_${month}
		mkdir source2/folder2_${year}/subfolder_${month}
		for day in {1..31}
		do
			echo -e "Day: ${day}"
			date -s "$year-$month-$day 10:30:30" > /dev/null
			random=$RANDOM
			touch source1/folder1_${year}/subfolder_${month}/foo_${year}-${month}-${day}
			touch source2/folder2_${year}/subfolder_${month}/foo_${year}-${month}-${day}
			echo "${random}" > source1/folder1_${year}/subfolder_${month}/foo_${year}-${month}-${day}
			echo "${random}" > source2/folder2_${year}/subfolder_${month}/foo_${year}-${month}-${day}
			./backup.sh -t inc
			#if [ "${day}" == "31" -a "${month}" == "12" ]; then
			#	./backup.sh -t full
			#fi
			#echo "${day}/${month}/${year}"
			let "loop_conunt++"
		done
		#echo "Deleting source/folder_${year}/subfolder_${month}/foo_${year}-${month}-1"
		rm source1/folder1_${year}/subfolder_${month}/foo_${year}-${month}-1
		rm source2/folder2_${year}/subfolder_${month}/foo_${year}-${month}-1

	done
	read -p "Press enter to continue"
done
