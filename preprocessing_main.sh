#!/bin/bash

run() {
    TIMEFORMAT='Pre-processing time took %R seconds to complete.'
    time {
        dataFolder="$1"
        subj_sessFolder="$2"
        destFolder="$3"
        T1_pattern="$4"
        fMRI_pattern="$5"

        echo "#1 Running ANTS brain extraction and FEAT pre-processing"
        source ./preprocessing_preAROMA.sh
        preprocessing_preAROMA "${dataFolder}" "${subj_sessFolder}" "${destFolder}" "${T1_pattern}" "${fMRI_pattern}"
        echo -e "Finished ANTS brain extraction and FEAT preprocessing\n"

        echo "#2 Performing ANTsRegistration"
        source ./preprocessing_ANTsRegistration.sh
        ANTsRegistration "${subj_sessFolder}" "${destFolder}"
        echo -e "Finished ANTsRegistration\n"

        echo "#3 Pre-processing AROMA"
        source ./preprocessing_AROMA.sh
        aroma "${subj_sessFolder}" "${destFolder}" ./ICA-AROMA/ICA_AROMA.py
        echo -e "Finished pre-processing ICA AROMA\n"

        echo "#4 Pre-processing Post-AROMA"
        source ./preprocessing_postAROMA.sh
        nuisance "${subj_sessFolder}" "${destFolder}" ./Templates "${TR}"
        echo -e "Finished pre-processing Post-AROMA\n"
        }
}

dataFolder="$1"
subjFolder="$2"
sessFolder="$3"
destFolder="$4"
T1_pattern="$5"
fMRI_pattern="$6"

# Merge subject and session folder paths
if [[ !  -z  ${sessFolder}  ]] ; then
  subj_sessFolder=${subjFolder}/${sessFolder}
else
  subj_sessFolder=${subjFolder}
fi

# Check if we can find subject's T1 and rsfMRI scans using specified paths and string tokens
if [[ ! -s $(echo ${dataFolder}/${subj_sessFolder}/*${T1_pattern}*) ]]; then
  echo -e "Cannot find T1W scan -- ${dataFolder}/${subj_sessFolder}/*${T1_pattern}* does not match a single file. \n\n Please check the specified data-, subject- and session folder and T1 pattern used to match filename"
  exit
fi
if [[ ! -s $(echo ${dataFolder}/${subj_sessFolder}/*${fMRI_pattern}*) ]]; then
  echo -e "Cannot find rsfMRI scan -- ${dataFolder}/${subj_sessFolder}/*${fMRI_pattern}* does not match a single file. \n\n Please check the specified data-, subject- and session folder and rsfMRI pattern used to match filesname"
  exit
fi

# Set up directory where we can store logs
logPath="${destFolder}"/"${subj_sessFolder}"
mkdir -p ${logPath}

run "${dataFolder}" "${subj_sessFolder}" "${destFolder}" "${T1_pattern}" "${fMRI_pattern}" | tee ${logPath}/log_"${subj_sessFolder//\//_}".txt

# Expects one of the following structures to find structural and functional data:
# "${dataFolder}/${subjectID}/{T1_pattern}|{fMRI_pattern}.nii(.gz)
# "${dataFolder}/${subjectID}/{sessionID}/{T1_pattern}|{fMRI_pattern}.nii(.gz)

# Use this command when there are no session folders:
# run dataFolder subjectID "" destFolder T1_pattern fMRI_pattern

# For example:
#./preprocessing_main.sh /data/wbbruin/Desktop/rsfmri_preprocessing_sh/Testset ECT_MRI_1 "" ~/Desktop/OUTPUT T1W fMRI

# Or when directing to to specific session subdirectory
# ./preprocessing_main.sh /data/wbbruin/Desktop/rsfmri_preprocessing_sh/Testset ECT_MRI_2 session1 ~/Desktop/OUTPUT T1W fMRI
