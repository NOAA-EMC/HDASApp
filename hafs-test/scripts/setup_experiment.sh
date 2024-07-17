#!/bin/bash

START=$(date +%s)

# This script is used after compiling HDASApp with -r option which downloads
# HAFS test data. This script helps a user set up an experiment directory.

###### USER INPUT #####
YOUR_PATH_TO_HDASAPP="/path/to/your/installation/of/HDASApp"
YOUR_EXPERIMENT_DIR="/path/to/your/desired/experiment/directory/jedi-assim_test"
SLURM_ACCOUNT="hurricane"
DYCORE="FV3" #FV3 | MPAS
GSI_TEST_DATA="YES"
YOUR_PATH_TO_GSI="/path/to/your/installation/of/GSI"
EVA="NO"
#######################

source $YOUR_PATH_TO_HDASAPP/ush/detect_machine.sh

# Print current setting to the screen.
echo "Your current settings are:"
echo -e "\tYOUR_PATH_TO_HDASAPP=$YOUR_PATH_TO_HDASAPP"
echo -e "\tYOUR_EXPERIMENT_DIR=$YOUR_EXPERIMENT_DIR"
echo -e "\tSLURM_ACCOUNT=$SLURM_ACCOUNT"
echo -e "\tDYCORE=$DYCORE"
echo -e "\tMACHINE_ID=$MACHINE_ID"
echo -e "\tGSI_TEST_DATA=$GSI_TEST_DATA"
echo -e "\tYOUR_PATH_TO_GSI=$YOUR_PATH_TO_GSI"
echo -e "\tEVA=$EVA\n"

# Check to see if user changed the paths to something valid.
if [[ ! -d $YOUR_PATH_TO_HDASAPP || ! -d `dirname $YOUR_EXPERIMENT_DIR` ]]; then
  echo "Please make sure to edit the USER INPUT BLOCK before running $0."
  echo "exiting!!!"
  exit 1
fi

# At the moment these are the only test data that exists. Maybe become user input later?
# It also seems the best to just do either FV3 or MPAS data each time script is run.
if [[ $DYCORE == "FV3" ]]; then
  TEST_DATA="hafs-data_fv3jedi_2020082512"
else
  echo "Not a valid DYCORE: ${DYCORE}. Please use FV3."
  echo "exiting!!!"
  exit 2
fi

if [[ ! ( $MACHINE_ID == "hera" || $MACHINE_ID == "orion" || $MACHINE_ID == "jet" ) ]]; then
   echo "Not a valid MACHINE_ID: ${MACHINE_ID}. Please use hera | orion | jet."
   exit 3
fi

# Lowercase dycore for script names.
declare -l dycore="$DYCORE"

# Ensure experiment directory exists, the move into that space.
mkdir -p $YOUR_EXPERIMENT_DIR
cd $YOUR_EXPERIMENT_DIR

# Copy the test data into the experiment directory.
echo "Copying data. This will take just a moment."
echo "  --> ${dycore}-jedi data on $MACHINE_ID"
#rsync -a $YOUR_PATH_TO_HDASAPP/bundle/hafs-test-data/${TEST_DATA} .
#rsync -a $YOUR_PATH_TO_HDASAPP/bundle/test-data-release/${TEST_DATA} .
rsync -a /scratch1/NCEPDEV/hwrf/save/Jing.Cheng/JEDI/staged-data/hafs-data_fv3jedi_2020082512 .

# Copy the template run script which will be updated according to the user input
cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/scripts/templates/run_${dycore}jedi_template.sh ./${TEST_DATA}/run_${dycore}jedi.sh

# Stream editor to edit files. Use "#" instead of "/" since we have "/" in paths.
cd ${YOUR_EXPERIMENT_DIR}/${TEST_DATA}
sed -i "s#@YOUR_PATH_TO_HDASAPP@#${YOUR_PATH_TO_HDASAPP}#g" ./run_${dycore}jedi.sh
sed -i "s#@YOUR_EXPERIMENT_DIR@#${YOUR_EXPERIMENT_DIR}#g"   ./run_${dycore}jedi.sh
sed -i "s#@SLURM_ACCOUNT@#${SLURM_ACCOUNT}#g"               ./run_${dycore}jedi.sh
sed -i "s#@MACHINE_ID@#${MACHINE_ID}#g"                     ./run_${dycore}jedi.sh

# Copy visualization package.
cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/ush/colormap.py .
if [[ $GSI_TEST_DATA == "YES" && $DYCORE == "FV3" ]]; then
  cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/ush/fv3jedi_gsi_validation.py .
  cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/ush/fv3jedi_gsi_increment_singleob.py .
fi

# Copy rrts-test yamls and obs files.
mkdir -p testinput
mkdir -p Data/obs
cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/testinput/* testinput/.
#cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/obs/* Data/obs/.
cp -p /scratch1/NCEPDEV/hwrf/save/Jing.Cheng/JEDI/staged-data/obs/* Data/obs/.

# Copy GSI test data
if [[ $GSI_TEST_DATA == "YES" ]]; then
  echo "  --> gsi data on $MACHINE_ID"
  cd $YOUR_EXPERIMENT_DIR
  if [[ $MACHINE_ID == "hera" ]]; then
    rsync -a /scratch1/NCEPDEV/hwrf/save/Jing.Cheng/JEDI/staged-data/gsi_2020082512 .
  elif [[ $MACHINE_ID == "orion" ]]; then
    echo " HDAS Test Data staging on ORION is ongoing"
  elif [[ $MACHINE_ID == "jet" ]]; then
    echo " HDAS Test Data stating on JET is ongoing"
  fi
  cd gsi_2020082512
  cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/scripts/templates/run_gsi_template.sh run_gsi.sh
  sed -i "s#@YOUR_PATH_TO_GSI@#${YOUR_PATH_TO_GSI}#g" ./run_gsi.sh
  sed -i "s#@SLURM_ACCOUNT@#${SLURM_ACCOUNT}#g"       ./run_gsi.sh
  sed -i "s#@MACHINE_ID@#${MACHINE_ID}#g"             ./run_gsi.sh
  cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/scripts/templates/run_gsi_ncdiag_template.sh run_gsi_ncdiag.sh
  sed -i "s#@YOUR_PATH_TO_HDASAPP@#${YOUR_PATH_TO_HDASAPP}#g" ./run_gsi_ncdiag.sh
  sed -i "s#@MACHINE_ID@#${MACHINE_ID}#g"                     ./run_gsi_ncdiag.sh
  #cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/obs/* Data/obs/.
  cp -p /scratch1/NCEPDEV/hwrf/save/Jing.Cheng/JEDI/staged-data//obs/* Data/obs/.
  ln -sf ${YOUR_PATH_TO_GSI}/build/src/gsi/gsi.x .
  ln -sf Data/obs/sfcshp_singleob_prepbufr prepbufr
  cp gsiparm.anl_singleob gsiparm.anl
fi

# Copy EVA scripts
if [[ $EVA == "YES" ]]; then
  echo "  --> eva scripts on $MACHINE_ID"
  cd $YOUR_EXPERIMENT_DIR
  rsync -a $YOUR_PATH_TO_HDASAPP/ush/eva .
  cd eva
  cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/scripts/templates/run_eva_template.sh run_eva.sh
  sed -i "s#@YOUR_PATH_TO_HDASAPP@#${YOUR_PATH_TO_HDASAPP}#g" ./run_eva.sh
  sed -i "s#@MACHINE_ID@#${MACHINE_ID}#g"                     ./run_eva.sh
fi

echo "done."
END=$(date +%s)
DIFF=$((END - START))
echo "Time taken to run the code: $DIFF seconds"
