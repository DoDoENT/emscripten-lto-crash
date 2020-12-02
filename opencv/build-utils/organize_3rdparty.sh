#!/bin/bash

for oldfile in `ls`; do
	file=`echo $oldfile | sed 's/d\.lib/\.lib/g' | sed 's/d\.pri/\.pri/g' | sed 's/d\.pdb/\.pdb/g'`
	foldername=`echo $file | sed 's/\.lib//g' | sed 's/\.pri//g' | sed 's/\.pdb//g'`
	echo "$oldfile $file $foldername"
	mkdir $foldername
	mv $oldfile $foldername/$file
done