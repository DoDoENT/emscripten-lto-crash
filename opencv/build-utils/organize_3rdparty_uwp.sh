#!/bin/bash

for oldfile in `ls`; do
	file=`echo $oldfile | sed 's/d\.lib/\.lib/g' | sed 's/d\.pri/\.pri/g' | sed 's/d\.pdb/\.pdb/g'`
	mv $oldfile $file
done