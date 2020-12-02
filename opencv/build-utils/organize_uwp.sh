#!/bin/bash

for oldfile in `ls | grep 310`; do
	file=`echo $oldfile | sed 's/d\.lib/\.lib/g' | sed 's/d\.pri/\.pri/g' | sed 's/d\.pdb/\.pdb/g'`
	file=`echo $file | sed 's/310//g'`
	mv $oldfile $file
done