#!/bin/bash

dim=70
dataFolder="${HOME}/fMRI_data/PTSD_veterans"
melodicFolder="${dataFolder}/analysis/controls_ICA_aroma.gica"
melodicFolderDim="${melodicFolder}/dim${dim}/"
saveFolder="${melodicFolderDim}/meta_melodic_dim${dim}"
funcFiles="${melodicFolder}/controls_preprocessed_aroma_final_without21_rejected_Sattleworth.txt"
#saveFolder="${dataFolder}/analysis/ptsd_dual_regression"
#funcFiles="${saveFolder}/dual_regression_ptsd_filtered.txt"
iter=1

for funcFile in `cat ${funcFiles}`; do	
	echo ${funcFile} 

	echo "Mean individual normalized functionals"
	fslmaths ${funcFile} -Tmean ${saveFolder}/meanFunc${iter}
	((iter+=1))
done 

echo "Merge mean functionals"
fslmerge -t ${saveFolder}/meanFunc.nii.gz `ls ${saveFolder}/meanFunc*[0-9].nii.gz`
imrm ${saveFolder}/meanFunc*[0-9].nii.gz

echo "Mean mean functionals"
fslmaths ${saveFolder}/meanFunc.nii.gz -Tmean ${saveFolder}/meanFunc.nii.gz
