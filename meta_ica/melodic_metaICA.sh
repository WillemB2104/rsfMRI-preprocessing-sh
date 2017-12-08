#!/bin/bash

dim=70
dataFolder="${HOME}/fMRI_data/PTSD_veterans"
melodicFolder="${dataFolder}/analysis/controls_ICA_aroma.gica"
melodicFolderDim="${melodicFolder}/dim${dim}"
metaFolder="${melodicFolderDim}/meta_melodic_dim${dim}"
bgImage="${melodicFolder}/bg_image.nii.gz"


echo ${metaFolder}
mkdir -p ${metaFolder}

# 1. merge all the ICA components
fslmerge -t ${metaFolder}/melodic_indv_input.nii.gz `ls ${melodicFolderDim}/indv_melodic*[0-9]/melodic_IC.nii.gz`

# 2. run meta-ica
melodic -i ${metaFolder}/melodic_indv_input.nii.gz -o ${metaFolder} -v -m ${melodicFolder}/mask.nii.gz --tr=1.0000 --report --bgimage=${bgImage} --mmthresh=0.5 --vn --disableMigp -d ${dim} --Ostats
