#!/bin/bash

indvMelodic() {
	run="$1"
	mainInput="$2"
	melodicMainFolder="$3"
	bgImage="$4"
	dim="$5"
	overlapMask=${melodicMainFolder}/mask.nii.gz	

	# 1, create output folder based on the run
	outputFolder="${melodicMainFolder}/dim${dim}/indv_melodic${run}"
	mkdir -p ${outputFolder}
	echo ${outputFolder}	
	inputs="${outputFolder}/filelist${run}.txt"

	# 2. shuffle the main input filelist and store it under the output folder
	cat ${mainInput} | shuf > ${inputs}
	
	# 3. extract the first 20 subjects and resave only them
	head -20 ${inputs} > ${outputFolder}/tmp.txt
	mv ${outputFolder}/tmp.txt ${inputs}
	
	# 4. run melodnic
	melodic -i ${inputs} -o ${outputFolder} -a concat --sep_vn -m ${overlapMask} --disableMigp --mmthresh=0.5 --tr=1.6000000 --bgimage=${bgImage} -d ${dim} --report -v
} 

dim=70
dataFolder="${HOME}/fMRI_data/PTSD_veterans"
melodicFolder="${dataFolder}/analysis/controls_ICA_aroma.gica"
bgImage="${melodicFolder}/bg_image.nii.gz"
fileList="${melodicFolder}/controls_preprocessed_aroma_final_without21_rejected_Sattleworth.txt"
N=10

for run in {01..25}; do
	((i=i%N)); ((i++==0)) && wait
	indvMelodic ${run} ${fileList} ${melodicFolder} ${bgImage} ${dim}&
done



