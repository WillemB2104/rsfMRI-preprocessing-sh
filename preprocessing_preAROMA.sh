#!/bin/bash

preprocessing_preAROMA() {
    dataFolder="$1"
    subj_sessFolder="$2"
    destFolder="$3"
    T1_pattern="$4"
    fMRI_pattern="$5"

    # Create working directory for FSL Feat..
    mkdir -p ${destFolder};

    subjFullFolder=${dataFolder}/${subj_sessFolder}

    # Use echo to get rid of wildcards..
    T1=$(echo ${subjFullFolder}/*${T1_pattern}*)
    rsfMRI=$(echo ${subjFullFolder}/*${fMRI_pattern}*)

    # Estimate TR from data directly..
    TR=`fslval $rsfMRI pixdim4 | grep -o "[0-9.]*"`

    # Set number of time points (volumes)
    npts=`fslnvols $rsfMRI`

    # Calculate total amount of voxels (FSL only uses this for timing calculations)
    dim1=`fslval $rsfMRI dim1`
    dim2=`fslval $rsfMRI dim2`
    dim3=`fslval $rsfMRI dim3`
    dim4=`fslval $rsfMRI dim4`
    totalVoxels=$(awk "BEGIN {print ${dim1}*${dim2}*${dim3}*${dim4}}")

    echo "TR = ${TR}, volumes = ${npts}, total voxels = ${totalVoxels}"

    # Retrieve file names..
    T1_fname=$(basename "${T1}")
    rsfMRI_fname=$(basename "${rsfMRI}")

    # Now without file extensions..
    IFS='.' read -r T1_fname_no_ext string <<< "$T1_fname"
    IFS='.' read -r rsfMRI_fname_no_ext string <<< "$rsfMRI_fname"

    # Create soft symbolic links to T1 and rsfMRI scans in working directory..
    T1_link=${destFolder}/${subj_sessFolder}/${T1_fname}
    rsfMRI_link=${destFolder}/${subj_sessFolder}/${rsfMRI_fname}
    mkdir -p ${destFolder}/${subj_sessFolder};
    ln -s ${T1} ${T1_link}
    ln -s ${rsfMRI} ${rsfMRI_link}

    # Reorient scans to standard orientation (MNI152)..
    fslreorient2std ${T1_link} ${destFolder}/${subj_sessFolder}/${T1_fname_no_ext}_reoriented
    fslreorient2std ${rsfMRI_link} ${destFolder}/${subj_sessFolder}/${rsfMRI_fname_no_ext}_reoriented

    # Use antsBrainExtraction with OASIS templates - takes a while
    template0=./Templates/T_template0_reoriented.nii.gz
    prob_mask=./Templates/T_template0_BrainCerebellumProbabilityMask_reoriented.nii.gz
    regs_mask=./Templates/T_template0_BrainCerebellumRegistrationMask_reoriented.nii.gz
    echo "antsBrainExtraction arguments: -d 3 -a ${destFolder}/${subj_sessFolder}/${T1_fname_no_ext}_reoriented.nii.gz -e ${template0} -m ${prob_mask} -f ${regs_mask} -o ${destFolder}/${subj_sessFolder}/ants -k 1"
    antsBrainExtraction.sh -d 3 -a ${destFolder}/${subj_sessFolder}/${T1_fname_no_ext}_reoriented.nii.gz -e ${template0} -m ${prob_mask} -f ${regs_mask} -o ${destFolder}/${subj_sessFolder}/ants -k 1

    # Rename files and remove unnecessary ANTs output..
    mv ${destFolder}/${subj_sessFolder}/antsBrainExtractionBrain.nii.gz ${destFolder}/${subj_sessFolder}/${T1_fname_no_ext}_reoriented_BFCorr_brain.nii.gz
	mv ${destFolder}/${subj_sessFolder}/antsBrainExtractionMask.nii.gz ${destFolder}/${subj_sessFolder}/${T1_fname_no_ext}_reoriented_BFCorr_brain_mask.nii.gz
	mv ${destFolder}/${subj_sessFolder}/antsN4Corrected0.nii.gz ${destFolder}/${subj_sessFolder}/${T1_fname_no_ext}_reoriented_BFCorr.nii.gz
	rm -rf ${destFolder}/${subj_sessFolder}/ants*

    # Replace placeholders in standard FEAT design..
    reoriented_brain=${destFolder}/${subj_sessFolder}/${T1_fname_no_ext}_reoriented_BFCorr_brain.nii.gz
    reoriented_rsfMRI=${destFolder}/${subj_sessFolder}/${rsfMRI_fname_no_ext}_reoriented

    tmpDesign=${destFolder}/${subj_sessFolder}/tmpDesign.fsf

    cp ./Templates/design.fsf ${tmpDesign}
    sed -i -e 's/NPTS_HOLDER/'${npts}'/' ${tmpDesign}
    sed -i -e 's/TR_HOLDER/'${TR}'/' ${tmpDesign}
    sed -i -e 's/VOXELS_HOLDER/'${totalVoxels}'/' ${tmpDesign}
    sed -i -e 's|FMRI_HOLDER|'"${reoriented_rsfMRI}"'|' ${tmpDesign} # Using different delimiter so we can sed paths
    sed -i -e 's|STRUCT_HOLDER|'"${reoriented_brain}"'|' ${tmpDesign}

    # Run FEAT..
    feat ${tmpDesign}
    rm ${tmpDesign}
}

