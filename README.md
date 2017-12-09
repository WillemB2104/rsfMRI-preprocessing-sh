# Preprocessing pipeline for rsfMRI data using ANTs, FSL, ICA-AROMA and c3d.

The pipeline is written in separate bash scripts that include the following preprocessing steps:

1. **FEAT pre-processing**: reorient functional and structural scans to standard orientation, apply brain extraction using ANTs and run FSL's FEAT

2. **ANTsRegistration**: (co)registration using FSL and ANTs, normalization of transformation matrices to MNI space using 2mm standard templates

3. **Pre-processing AROMA**: create masks for functional data, run ICA-AROMA to identify and remove motion artifacts from fMRI data

4. **Pre-processing Post-AROMA**: perform nuisance regression, high pass filtering and register the preprocessed data to MNI at 4mm and mask using an 4mm MNI-mask



#### Usage:

The pipeline runs per individual subject and is executed with the following command:

`./preprocessing_main.sh dataFolder subjectID sessionID destFolder T1_pattern fMRI_pattern`

##### Input is expected to follow one of the following directory structures to find structural and functional data in NIFTI format:

• {dataFolder}/{subjectID}/{T1_pattern}|{fMRI_pattern}.nii(.gz)

• {dataFolder}/{subjectID}/{sessionID}/{T1_pattern}|{fMRI_pattern}.nii(.gz)


##### Use this command when there are no session folders:

`./preprocessing_main.sh dataFolder subjectID "" destFolder T1_pattern fMRI_pattern`

##### For example:

`./preprocessing_main.sh /data/wbbruin/Desktop/rsfmri_preprocessing_sh/Testset ECT_MRI_1 "" ~/Desktop/OUTPUT T1W fMRI`

##### Or when directing to to specific session subdirectory:

`./preprocessing_main.sh /data/wbbruin/Desktop/rsfmri_preprocessing_sh/Testset ECT_MRI_2 session1 ~/Desktop/OUTPUT T1W fMRI`


#### Pipeline requirements:

- FSL 
- ANTs
- c3d
- Customized ICA-AROMA toolbox (contains changes in ICA_AROMA_functions.py that allow combining FSL's BBR coregistration with ANTs affine transformation files)
- Python 2.7 (modules: os, argparse, commands, numpy, random)
- Templates directory containing standard MNI tempates, OASIS templates (used for ANTs brain extraction), FEAT design file and Harvard-Oxford priors for CSF and WM 


#### Final notes: 

Don't forget to unzip the ICA-AROMA toolbox before running the pipeline. This directory should be located under the main directory containing preprocessing bash scripts. Python dependencies for ICA-AROMA can be installed using requirements.txt.

Finally, a small anonymized test set has been added which rsfMRI and structural MR data for 6 subjects, and can be used for testing.
