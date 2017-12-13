#!/bin/bash

nuisance() {
    subj_sessFolder="$1"
    destFolder="$2"
	TemplateFolder="$3"
	TR="$4"

    featFolder=$(echo ${destFolder}/${subj_sessFolder}/*.feat)
	AROMAFolder=${featFolder}/ICA_AROMA
	fMRIData=${AROMAFolder}/denoised_func_data_nonaggr.nii.gz
	exampleFunc=${featFolder}/reg/example_func.nii.gz
	structuralBrain=$(echo ${destFolder}/${subj_sessFolder}/*_reoriented_BFCorr_brain.nii.gz)
	MNIMask=${TemplateFolder}/MNI152_T1_4mm_brain_mask_filled.nii.gz
	MNI4mm=${TemplateFolder}/MNI152_T1_4mm.nii.gz

	nuisanceFolder=${featFolder}/ICA_AROMA/nuisance_files
	mkdir -p ${nuisanceFolder}

    # Get rid of file extension(s), i.e. ".nii.gz"
	IFS='.' read -r structuralBrain_no_ext string <<< "$structuralBrain"

	# 1. We have to go FAST
	echo "T1 segmentation"
	fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -o ${structuralBrain} ${structuralBrain}
	imrm ${structuralBrain_no_ext}_mixeltype.nii.gz
	imrm ${structuralBrain_no_ext}_seg.nii.gz
	imrm ${structuralBrain_no_ext}_pveseg.nii.gz

    echo "Thresholding masks"
	fslmaths ${structuralBrain_no_ext}_pve_0.nii.gz -thr 0.99 -bin ${nuisanceFolder}/csf_mask_epi_conservative.nii.gz
	fslmaths ${structuralBrain_no_ext}_pve_1.nii.gz -thr 0.01 -bin ${nuisanceFolder}/gm_tmp.nii.gz
	fslmaths ${structuralBrain_no_ext}_pve_2.nii.gz -thr 0.99 -bin ${nuisanceFolder}/wm_mask_epi_conservative.nii.gz

	echo "Inverting gray matter masks"
	fslmaths ${nuisanceFolder}/gm_tmp.nii.gz -sub 1 -abs ${nuisanceFolder}/gm_inv.nii.gz
	fslmaths ${nuisanceFolder}/csf_mask_epi_conservative.nii.gz -mul ${nuisanceFolder}/gm_inv.nii.gz ${nuisanceFolder}/csf_mask_epi_conservative.nii.gz
	fslmaths ${nuisanceFolder}/wm_mask_epi_conservative.nii.gz -mul ${nuisanceFolder}/gm_inv.nii.gz ${nuisanceFolder}/wm_mask_epi_conservative.nii.gz

	# erosion x3 WM, x1 CSF
	echo "Eroding masks"
	fslmaths ${nuisanceFolder}/wm_mask_epi_conservative.nii.gz -eroF ${nuisanceFolder}/wm_mask_epi_conservative.nii.gz
	fslmaths ${nuisanceFolder}/wm_mask_epi_conservative.nii.gz -eroF ${nuisanceFolder}/wm_mask_epi_conservative.nii.gz
	fslmaths ${nuisanceFolder}/wm_mask_epi_conservative.nii.gz -eroF ${nuisanceFolder}/wm_mask_epi_conservative.nii.gz
	fslmaths ${nuisanceFolder}/csf_mask_epi_conservative.nii.gz -eroF ${nuisanceFolder}/csf_mask_epi_conservative.nii.gz

	# 3. Transform to fMRI space using NearestNeighbor interpolation
	echo "Transform masks to fMRI space"
	antsApplyTransforms -d 3 -i ${nuisanceFolder}/csf_mask_epi_conservative.nii.gz -r ${exampleFunc} -o ${nuisanceFolder}/csf_mask_epi_conservative.nii.gz -n NearestNeighbor -t [${featFolder}/reg/ANTsEPI2T1_BBR.txt,1] -v --float
	antsApplyTransforms -d 3 -i ${nuisanceFolder}/wm_mask_epi_conservative.nii.gz -r ${exampleFunc} -o ${nuisanceFolder}/wm_mask_epi_conservative.nii.gz -n NearestNeighbor -t [${featFolder}/reg/ANTsEPI2T1_BBR.txt,1] -v --float
	antsApplyTransforms -d 3 -i ${TemplateFolder}/ho_csf_prior.nii.gz -r ${exampleFunc} -o ${nuisanceFolder}/csf_prior.nii.gz -n NearestNeighbor -t [${featFolder}/reg/ANTsEPI2T1_BBR.txt,1] -t [${featFolder}/reg/ANTsT1toMNI0GenericAffine.mat,1] -t ${featFolder}/reg/ANTsT1toMNI1InverseWarp.nii.gz -v --float
	antsApplyTransforms -d 3 -i ${TemplateFolder}/ho_wm_prior.nii.gz -r ${exampleFunc} -o ${nuisanceFolder}/wm_prior.nii.gz -n NearestNeighbor -t [${featFolder}/reg/ANTsEPI2T1_BBR.txt,1] -t [${featFolder}/reg/ANTsT1toMNI0GenericAffine.mat,1] -t ${featFolder}/reg/ANTsT1toMNI1InverseWarp.nii.gz -v --float

    # combine Harvard Oxford prior masks with subject specific mask
    echo "Combine prior masks with extracted masks"
	fslmaths ${nuisanceFolder}/csf_mask_epi_conservative.nii.gz -mul ${nuisanceFolder}/csf_prior.nii.gz ${nuisanceFolder}/csf_mask_epi_final.nii.gz
	fslmaths ${nuisanceFolder}/wm_mask_epi_conservative.nii.gz -mul ${nuisanceFolder}/wm_prior.nii.gz ${nuisanceFolder}/wm_mask_epi_final.nii.gz

	# 4. Extract mean CSF/WM time-series
	echo "Calculate mean signal of WM/CSF"
	fslmeants -i ${fMRIData} -o ${nuisanceFolder}/mean_csf_conservative.txt -m ${nuisanceFolder}/csf_mask_epi_final.nii.gz
	fslmeants -i ${fMRIData} -o ${nuisanceFolder}/mean_wm_conservative.txt -m ${nuisanceFolder}/wm_mask_epi_final.nii.gz

	# 5. Combine both nuisance files
	echo "Combining files"	
	paste ${nuisanceFolder}/mean_csf_conservative.txt ${nuisanceFolder}/mean_wm_conservative.txt > ${nuisanceFolder}/nuisance.txt
		
	# 6. Calculating temporal mean (not sure whether it's correct to do it here)
	echo "Calculate Temporal Mean"
	fslmaths ${fMRIData} -Tmean ${featFolder}/tempMean.nii.gz

	# 7. Nuisance regression
	echo "Nuisance Regression in Progress" 
	fsl_glm -i ${fMRIData} -d ${nuisanceFolder}/nuisance.txt --demean -o ${AROMAFolder}/beta_params.nii.gz --out_res=${AROMAFolder}/denoised_func_data_nonaggr_residual.nii.gz
	imrm ${AROMAFolder}/beta_params.nii.gz		

	# 8. Fixing header information
	echo "Fix header information of residual images"
	fslcpgeom ${fMRIData} ${AROMAFolder}/denoised_func_data_nonaggr_residual.nii.gz

	# 9. Temporal filtering: sigma_hp = 1/2*f*TR = 1/2*0.01*TR = 100/2*TR = 100/2*1.6 = 31.25
	f=0.01
	sigma_hp=$(awk "BEGIN {print 1/(2*${TR}*${f})}")

	echo "High-pass filtering with sigma_hp=${sigma_hp} (>${f} Hz, TR=${TR})"
	fslmaths ${AROMAFolder}/denoised_func_data_nonaggr_residual.nii.gz -bptf ${sigma_hp} -1 -add ${featFolder}/tempMean.nii.gz ${AROMAFolder}/denoised_func_data_nonaggr_residual_highpass.nii.gz

	# 10. Registration to MNI at 4mm
	echo "Register the preprocessed data to MNI at 4mm and mask using an 4mm MNI-mask"
	antsApplyTransforms -d 3 -e 3 -i ${AROMAFolder}/denoised_func_data_nonaggr_residual_highpass.nii.gz -r ${MNI4mm} -n BSpline -t ${featFolder}/reg/ANTsT1toMNI1Warp.nii.gz -t ${featFolder}/reg/ANTsT1toMNI0GenericAffine.mat -t ${featFolder}/reg/ANTsEPI2T1_BBR.txt -o ${AROMAFolder}/func_data_aroma_residual_final.nii.gz -v --float
	fslmaths ${AROMAFolder}/func_data_aroma_residual_final.nii.gz -mas ${MNIMask} ${AROMAFolder}/func_data_aroma_residual_final.nii.gz

    ### Save additional output for preprocessed files without nuisance regression ###

	# 11. Temporal filtering
	echo "High-pass filtering with sigma_hp=${sigma_hp} (>${f} Hz, TR=${TR}) without nuisance regression"
	fslmaths ${fMRIData} -bptf ${sigma_hp} -1 -add ${featFolder}/tempMean.nii.gz ${AROMAFolder}/denoised_func_data_nonaggr_highpass.nii.gz

	# 12. Registration to MNI at 4mm
	echo "Register the preprocessed data without nuisance regression to MNI at 4mm and mask using an 4mm MNI-mask"
	antsApplyTransforms -d 3 -e 3 -i ${AROMAFolder}/denoised_func_data_nonaggr_highpass.nii.gz -r ${MNI4mm} -n BSpline -t ${featFolder}/reg/ANTsT1toMNI1Warp.nii.gz -t ${featFolder}/reg/ANTsT1toMNI0GenericAffine.mat -t ${featFolder}/reg/ANTsEPI2T1_BBR.txt -o ${AROMAFolder}/func_data_aroma_final.nii.gz -v --float
	fslmaths ${AROMAFolder}/func_data_aroma_final.nii.gz -mas ${MNIMask} ${AROMAFolder}/func_data_aroma_final.nii.gz
}
