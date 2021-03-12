#!/bin/bash
# V.615 by Fan Zhong (zonefan@163.com).
# To Sort items in bedGraph files according to the score (colume 4th).
# Keep all the items with the same thershold score.
# The script need to be run under bash enviroment that with numeric sorting function "sort -g".

read -p "Please set the top socre items number (e.g. 30000):" TopN	# read cutoff number from keyboard input.
read -p "Please set the lower limit of items number (e.g. 2000):" lowerlim
rm -rf ./TopScoreOut/
mkdir -p ./TopScoreOut/ScoreSorted	# make a directory to store score-sorted BED files
echo -e "Top numbers:"$TopN"\tLower limit:"$lowerlim"\n" > ./TopScoreOut/0_Report

filelist="./Beineg_mm9_p0.001_S0/*.bedGraph"
nK=`expr $TopN / 1000`k

for file in $filelist
do
filename=`basename $file .bedGraph`
lineNum=`cat $file | wc -l`

if [ "$lineNum" == 0 ]; then
ThersholdScore=0
cp $file ./TopScoreOut/ScoreSorted/$filename\_SS.bedGraph
elif [ "$lineNum" != 0 ] && [ "$lineNum" -lt "$TopN" ]; then
ThersholdScore=`sort -k 4gr,4 $file | tee ./TopScoreOut/ScoreSorted/$filename\_SS.bedGraph | tail -n 1 | cut -f 4`
else
ThersholdScore=`sort -k 4gr,4 $file | tee ./TopScoreOut/ScoreSorted/$filename\_SS.bedGraph | sed -n "$TopN"p | cut -f 4`
fi

max=$(( `grep -Fn $ThersholdScore ./TopScoreOut/ScoreSorted/$filename\_SS.bedGraph | awk '{print $1}' FS=":" | awk 'BEGIN {max = 0} {if ($1+0 > max+0){max=$1;content=$0}} END {print content}'` + 0 ))
min=$(( `grep -Fn $ThersholdScore ./TopScoreOut/ScoreSorted/$filename\_SS.bedGraph | awk '{print $1}' FS=":" | awk 'BEGIN {min = 9999999999} {if ($1+0 < min+0){min=$1;content=$0}} END {print content}'` + 0 ))

center=$(( ($max + $min)/2 ))
if [ "$center" -le "$TopN" ]; then
TopM=$max
elif [ "$min" -le "$lowerlim" ]; then
TopM=$max
else
TopM=$(( $min - 1))
fi

head -n $TopM ./TopScoreOut/ScoreSorted/$filename\_SS.bedGraph | sort -k1,1 -k2,2n > ./TopScoreOut/$filename\_$nK.bedGraph
2>>./TopScoreOut/0_Report
echo $filename >> ./TopScoreOut/0_Report
echo -e "Score:"$ThersholdScore"\tMin:"$min"\tMax:"$max"\tPick:"$TopM"\n" >> ./TopScoreOut/0_Report
done

