#!/bin/bash

dataFolder="${HOME}/fMRI_data/PTSD_veterans"
melodicFolder="${dataFolder}/analysis/controls_ICA_aroma.gica"
dualRegFolder="${dataFolder}/analysis/ptsd_dual_regression"
melodicTemplate="${melodicFolder}/controls_preprocessed_aroma_final_without21_rejected_Sattleworth.txt"
dualRegTemplate="${dualRegFolder}/dual_regression_ptsd_filtered.txt"

paste ${melodicTemplate} ${dualRegTemplate} > ${melodicFolder}/templateAll.txt

iter=1
for funcFile in `cat ${melodicFolder}/templateAll.txt`; do	
	echo ${funcFile} 
	echo "Create individual masks"
	fslmaths ${funcFile} -Tstd -bin ${melodicFolder}/mask_${iter} -odt char
	((iter+=1))
done 

echo "Create common mask"
fslmerge -t ${melodicFolder}/maskAll.nii.gz `ls ${melodicFolder}/mask_*.nii.gz`
fslmaths ${melodicFolder}/maskAll -Tmin ${melodicFolder}/mask
imrm ${melodicFolder}/mask_*.nii.gz
rm ${melodicFolder}/templateAll.txt
