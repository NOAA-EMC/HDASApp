#!/bin/bash

START=$(date +%s)

# This script helps a user set up an experiment directory.
###### USER INPUT #####
YOUR_PATH_TO_HDASAPP="/path/to/your/installation/of/HDASApp"
YOUR_EXPERIMENT_DIR="/path/to/your/desired/experiment/directory/jedi-assim_test"
YOUR_PATH_TO_GSI="/path/to/your/installation/of/GSI"

SLURM_ACCOUNT="hurricane"
DYCORE="FV3" #FV3 | MPAS   
GSI_TEST_DATA="YES"
EVA="NO"
DA_METHOD="3DEnVar" #3DEnVar | 4DEnVar | 3DFGAT
OBSTYPE="sondes" # sondes | sfcship | sfc
#######################
DATA_STAGE="/scratch1/NCEPDEV/hwrf/save/Jing.Cheng/JEDI/staged-data"
TESTCASE_DATE="2024063012"  # 2020082512; 2024063012

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
  TEST_DATA="hafs-data_fv3jedi_${TESTCASE_DATE}"
else
  echo "Not a valid DYCORE: ${DYCORE}. Please use FV3."
  echo "exiting!!!"
  exit 2
fi

if [[ ! ( $MACHINE_ID == "hera" || $MACHINE_ID == "orion" || $MACHINE_ID == "jet" ) ]]; then
   echo "Not a valid MACHINE_ID: ${MACHINE_ID}. Please use hera | orion | jet."
   exit 3
fi
case ${MACHINE_ID} in
   hera)
      DATA_STAGE="/scratch1/NCEPDEV/hwrf/save/Jing.Cheng/JEDI/staged-data"
   ;;
   orion|hercules)
      DATA_STAGE=""
   ;;
   *)
      echo "platfomr not supported: ${MACHINE_ID}"
      exit 3
   ;;
esac


# Lowercase dycore for script names.
declare -l dycore="$DYCORE"

# Ensure experiment directory exists, the move into that space.
mkdir -p $YOUR_EXPERIMENT_DIR
cd $YOUR_EXPERIMENT_DIR

# Copy the test data into the experiment directory.
echo "Copying data. This will take just a moment."
echo "  --> ${dycore}-jedi data on $MACHINE_ID"
rsync -a ${DATA_STAGE}/hafs-data_fv3jedi_${TESTCASE_DATE} .
# Copy the template run script which will be updated according to the user input
cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/scripts/templates/run_${dycore}jedi_template.sh ./${TEST_DATA}/run_${dycore}jedi.sh
# Stream editor to edit files. Use "#" instead of "/" since we have "/" in paths.
# Enter (cd) into the hafs test directory

cd ${YOUR_EXPERIMENT_DIR}/${TEST_DATA}
sed -i "s#@YOUR_PATH_TO_HDASAPP@#${YOUR_PATH_TO_HDASAPP}#g" ./run_${dycore}jedi.sh
sed -i "s#@YOUR_EXPERIMENT_DIR@#${YOUR_EXPERIMENT_DIR}#g"   ./run_${dycore}jedi.sh
sed -i "s#@SLURM_ACCOUNT@#${SLURM_ACCOUNT}#g"               ./run_${dycore}jedi.sh
sed -i "s#@MACHINE_ID@#${MACHINE_ID}#g"                     ./run_${dycore}jedi.sh
sed -i "s#@DATE_TIME@#${TESTCASE_DATE}#g"                   ./run_${dycore}jedi.sh
sed -i "s#@DEFAULT_YAML@#${OBSTYPE}_singleob_airTemperature_fv3jedi_${DA_METHOD}#g" ./run_${dycore}jedi.sh


# Copy visualization package.
cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/ush/colormap.py .
if [[ $GSI_TEST_DATA == "YES" && $DYCORE == "FV3" ]]; then
  cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/ush/fv3jedi_gsi_validation.py .
  cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/ush/fv3jedi_gsi_increment_singleob.py .
fi

# Copy hafs-test yamls and obs files.
mkdir -p testinput
mkdir -p Data/obs
cp -rp $YOUR_PATH_TO_HDASAPP/hafs-test/validated_yamls/* testinput
cp -p ${DATA_STAGE}/obs/* Data/obs/.


# Copy GSI test data
if [[ $GSI_TEST_DATA == "YES" ]]; then
  echo "  --> gsi data on $MACHINE_ID"
  # Enter into the gsi test directory
  cd $YOUR_EXPERIMENT_DIR
  if [[ $MACHINE_ID == "hera" ]]; then
    rsync -a ${DATA_STAGE}/gsi_${TESTCASE_DATE} .
  elif [[ $MACHINE_ID == "orion" ]]; then
    echo " HDAS Test Data staging on ORION is ongoing"
  elif [[ $MACHINE_ID == "jet" ]]; then
    echo " HDAS Test Data stating on JET is ongoing"
  fi
  cd gsi_${TESTCASE_DATE}

  cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/scripts/templates/run_gsi_template.sh run_gsi.sh
  sed -i "s#@YOUR_PATH_TO_GSI@#${YOUR_PATH_TO_GSI}#g" ./run_gsi.sh
  sed -i "s#@SLURM_ACCOUNT@#${SLURM_ACCOUNT}#g"       ./run_gsi.sh
  sed -i "s#@MACHINE_ID@#${MACHINE_ID}#g"             ./run_gsi.sh
  sed -i "s#@DA_METHOD@#${DA_METHOD}#g"               ./run_gsi.sh
  sed -i "s#@DATA_STAGE@#${DATA_STAGE}#g"             ./run_gsi.sh
  sed -i "s#@TESTCASE_DATE@#${TESTCASE_DATE}#g"       ./run_gsi.sh
  cp -p $YOUR_PATH_TO_HDASAPP/hafs-test/scripts/templates/run_gsi_ncdiag_template.sh run_gsi_ncdiag.sh
  sed -i "s#@YOUR_PATH_TO_HDASAPP@#${YOUR_PATH_TO_HDASAPP}#g" ./run_gsi_ncdiag.sh
  sed -i "s#@MACHINE_ID@#${MACHINE_ID}#g"                     ./run_gsi_ncdiag.sh
  sed -i "s#@OBSTYPE@#${OBSTYPE}#g"                           ./run_gsi_ncdiag.sh
  sed -i "s#@TESTCASE_DATE@#${TESTCASE_DATE}#g"               ./run_gsi_ncdiag.sh

  ln -sf ${YOUR_PATH_TO_GSI}/build/src/gsi/gsi.x .
  #cp gsiparm.anl.tmp gsiparm.anl
  # linke observation prepbufr data
  if [ ${OBSTYPE} == "sondes" ]; then
     ln -sf ${DATA_STAGE}/obs/sonde_singleob_airTemperature_prepbufr prepbufr
  elif [ ${OBSTYPE} == "sfcship" ]; then
     ln -sf ${DATA_STAGE}/obs/sfcshp_singleob_airTemperature_prepbufr prepbufr
  elif [ ${OBSTYPE} == "sfc" ]; then
     ln -sf ${DATA_STAGE}/obs/sfc_singleob_airTemperature_prepbufr prepbufr
  else
     echo "Input ${OBSTYPE} is not available for now (currently available: SONDE, SHIP, SFC)"
  fi
  if [ ${DA_METHOD} == "4DEnVar" ]; then
    L4DENSVAR=.true.
    NHR_OBSBIN=3
    ENS_NSTARTHR=3
  else
    L4DENSVAR=.false.
    NHR_OBSBIN=-1
    ENS_NSTARTHR=6
  fi
  sed -i "s#@L4DENSVAR@#${L4DENSVAR}#g" ./gsiparm.anl
  sed -i "s#@NHR_OBSBIN@#${NHR_OBSBIN}#g" ./gsiparm.anl
  sed -i "s#@ENS_NSTARTHR@#${ENS_NSTARTHR}#g" ./gsiparm.anl

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
