#!/bin/bash

for oldfile in `ls | grep 310`; do
	file=`echo $oldfile | sed 's/d\.lib/\.lib/g' | sed 's/d\.pri/\.pri/g' | sed 's/d\.pdb/\.pdb/g'`
	file=`echo $file | sed 's/310//g'`
	foldername=`echo $file | sed 's/\.lib//g' | sed 's/\.pri//g' | sed 's/\.pdb//g'`
	modulename=`echo $foldername | sed 's/opencv_//g'`
	echo "$oldfile $file $foldername $modulename $pdbPath"
	mkdir $foldername
	mv $oldfile $foldername/$file
done