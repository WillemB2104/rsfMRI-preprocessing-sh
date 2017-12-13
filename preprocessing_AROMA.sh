#!/bin/bash

aroma() {
    subj_sessFolder="$1"
    destFolder="$2"
	AROMAScript="$3"

    featFolder=$(echo ${destFolder}/${subj_sessFolder}/*.feat)
	fMRIData="${featFolder}/filtered_func_data.nii.gz"
	mcFiles="${featFolder}/mc/prefiltered_func_data_mcf.par"
	exampleFunc="${featFolder}/reg/example_func.nii.gz"

	# 1. Create Mask (creates func.nii.gz (brain-extracted) and func_mask.nii.gz, we only need the later und will remove the former)
	echo "Creating Func Mask!"
	bet ${exampleFunc} ${featFolder}/reg/func -f 0.3 -n -m -R
	imrm ${featFolder}/reg/func.nii.gz

	# 2. run AROMA
	echo "Running AROMA" 
	echo ${fMRIData}
	python $AROMAScript -in ${fMRIData} -out ${featFolder}/ICA_AROMA -mc ${mcFiles} -m ${featFolder}/reg/func_mask.nii.gz -affmat ${featFolder}/reg/ANTsEPI2T1_BBR.txt -affmat2 ${featFolder}/reg/ANTsT1toMNI0GenericAffine.mat -warp ${featFolder}/reg/ANTsT1toMNI1Warp.nii.gz
}


