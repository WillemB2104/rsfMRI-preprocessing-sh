#!/bin/bash

ANTsRegistration() {
    # ANTs registration here is performed using structural brain extracted image and 2mm standard templates
    subj_sessFolder="$1"
    destFolder="$2"

    featFolder=$(echo ${destFolder}/${subj_sessFolder}/*.feat)
    structBrain="${featFolder}/reg/highres.nii.gz"

    # 1. normalization (structural to MNI) in ANTs
    echo "ANTs normalization initiated!"
    antsRegistrationSyN.sh -d 3 -f ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz -m ${structBrain} -o ${featFolder}/reg/ANTsT1toMNI -n 12 -j 1

    # 2. transform BBR coregistration to ANTs
    echo "Transforming BBR coregistration"
    c3d_affine_tool -ref ${structBrain} -src ${featFolder}/reg/example_func.nii.gz ${featFolder}/reg/example_func2highres.mat -fsl2ras -oitk ${featFolder}/reg/ANTsEPI2T1_BBR.txt

    # 3. Transform example_func to MNI with ANTs for checking
    echo "Transform example_func to MNI with ANTs"
    antsApplyTransforms -d 3 -i ${featFolder}/reg/example_func.nii.gz -r ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz -o ${featFolder}/reg/ANTsEPI2MNI.nii.gz -n BSpline -t ${featFolder}/reg/ANTsT1toMNI1Warp.nii.gz -t ${featFolder}/reg/ANTsT1toMNI0GenericAffine.mat -t ${featFolder}/reg/ANTsEPI2T1_BBR.txt -v --float
}
