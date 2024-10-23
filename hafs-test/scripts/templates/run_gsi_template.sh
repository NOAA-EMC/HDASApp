#!/bin/bash
#SBATCH --account=@SLURM_ACCOUNT@
#SBATCH --qos=debug
#SBATCH --ntasks=360
#SBATCH -t 00:30:00
#SBATCH --job-name=gsi_test
#SBATCH -o gsi.out
#SBATCH --open-mode=truncate
#SBATCH --cpus-per-task 4 --exclusive

. /apps/lmod/lmod/init/sh
set +x

module purge

module use @YOUR_PATH_TO_GSI@/modulefiles
module load gsi_@MACHINE_ID@.intel

#module list

export OMP_NUM_THREADS=1

ulimit -s unlimited
ulimit -v unlimited
ulimit -a

export FILE_DIR="@DATA_STAGE@/hafs-data_fv3jedi_@TESTCASE_DATE@/Data/bkg"
export DATE=@TESTCASE_DATE@
export YYMODD=${DATE:0:8}
export HH=${DATE: -2}
export DATE=$(date -d "${YYMODD} ${HH}:00:00" +%s)
export DATEP3=$(date -d "@$(($DATE + 3*3600))" +"%Y%m%d %H")
export DATEM3=$(date -d "@$(($DATE - 3*3600))" +"%Y%m%d %H")
export YYMODD9=$(echo $DATEP3 | cut -d' ' -f1)
export HH9=$(echo $DATEP3 | cut -d' ' -f2)
export YYMODD3=$(echo $DATEM3 | cut -d' ' -f1)
export HH3=$(echo $DATEM3 | cut -d' ' -f2)
cp -p ${FILE_DIR}/${YYMODD}.${HH}0000.coupler.res coupler.res
cp -p ${FILE_DIR}/${YYMODD}.${HH}0000.fv_core.res.nc fv3_akbk
cp -p ${FILE_DIR}/${YYMODD}.${HH}0000.fv_core.res.tile1.nc fv3_dynvars
cp -p ${FILE_DIR}/${YYMODD}.${HH}0000.sfc_data.nc fv3_sfcdata
cp -p ${FILE_DIR}/${YYMODD}.${HH}0000.fv_srf_wnd.res.tile1.nc fv3_srfwnd
cp -p ${FILE_DIR}/${YYMODD}.${HH}0000.fv_tracer.res.tile1.nc fv3_tracer
cp -p ${FILE_DIR}/grid_spec.nc fv3_grid_spec
if [ "@DA_METHOD@" == "3DFGAT" ] || [ "@DA_METHOD@" == "4DEnVar" ]; then
 cp -p ${FILE_DIR}/${YYMODD9}.${HH9}0000.coupler.res coupler.res_09
 cp -p ${FILE_DIR}/${YYMODD9}.${HH9}0000.fv_core.res.nc fv3_akbk_09
 cp -p ${FILE_DIR}/${YYMODD9}.${HH9}0000.fv_core.res.tile1.nc fv3_dynvars_09
 cp -p ${FILE_DIR}/${YYMODD9}.${HH9}0000.sfc_data.nc fv3_sfcdata_09
 cp -p ${FILE_DIR}/${YYMODD9}.${HH9}0000.fv_srf_wnd.res.tile1.nc fv3_srfwnd_09
 cp -p ${FILE_DIR}/${YYMODD9}.${HH9}0000.fv_tracer.res.tile1.nc fv3_tracer_09
 cp -p ${FILE_DIR}/${YYMODD3}.${HH3}0000.coupler.res coupler.res_03
 cp -p ${FILE_DIR}/${YYMODD3}.${HH3}0000.fv_core.res.nc fv3_akbk_03
 cp -p ${FILE_DIR}/${YYMODD3}.${HH3}0000.fv_core.res.tile1.nc fv3_dynvars_03
 cp -p ${FILE_DIR}/${YYMODD3}.${HH3}0000.sfc_data.nc fv3_sfcdata_03
 cp -p ${FILE_DIR}/${YYMODD3}.${HH3}0000.fv_srf_wnd.res.tile1.nc fv3_srfwnd_03
 cp -p ${FILE_DIR}/${YYMODD3}.${HH3}0000.fv_tracer.res.tile1.nc fv3_tracer_03
fi

export FILE_DIR="@DATA_STAGE@/hafs-data_fv3jedi_@TESTCASE_DATE@/ens"
ln -sf ${FILE_DIR}/mem001/grid_spec.nc fv3_ens_grid_spec
for ((ii=1; ii<=10; ii++))
do
 export mem=$(printf "%02d" $ii)
 ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD}.${HH}0000.fv_core.res.tile1.nc fv3SAR06_ens_mem0${mem}-fv3_dynvars
 ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD}.${HH}0000.fv_tracer.res.tile1.nc fv3SAR06_ens_mem0${mem}-fv3_tracer
 ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD}.${HH}0000.fv_srf_wnd.res.tile1.nc fv3SAR06_ens_mem0${mem}-fv3_srfwnd
 ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD}.${HH}0000.sfc_data.nc fv3SAR06_ens_mem0${mem}-fv3_sfcdata
 ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD}.${HH}0000.coupler.res fv3SAR06_ens_mem0${mem}-coupler.res
 if [ "@DA_METHOD@" == "4DEnVar" ]; then
  ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD3}.${HH3}0000.fv_core.res.tile1.nc fv3SAR03_ens_mem0${mem}-fv3_dynvars
  ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD3}.${HH3}0000.fv_tracer.res.tile1.nc fv3SAR03_ens_mem0${mem}-fv3_tracer
  ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD3}.${HH3}0000.fv_srf_wnd.res.tile1.nc fv3SAR03_ens_mem0${mem}-fv3_srfwnd
  ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD3}.${HH3}0000.sfc_data.nc fv3SAR03_ens_mem0${mem}-fv3_sfcdata
  ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD3}.${HH3}0000.coupler.res fv3SAR03_ens_mem0${mem}-coupler.res
  ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD9}.${HH9}0000.fv_core.res.tile1.nc fv3SAR09_ens_mem0${mem}-fv3_dynvars
  ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD9}.${HH9}0000.fv_tracer.res.tile1.nc fv3SAR09_ens_mem0${mem}-fv3_tracer
  ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD9}.${HH9}0000.fv_srf_wnd.res.tile1.nc fv3SAR09_ens_mem0${mem}-fv3_srfwnd
  ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD9}.${HH9}0000.sfc_data.nc fv3SAR09_ens_mem0${mem}-fv3_sfcdata
  ln -sf ${FILE_DIR}/mem0${mem}/${YYMODD9}.${HH9}0000.coupler.res fv3SAR09_ens_mem0${mem}-coupler.res
 fi
done

srun --label @YOUR_PATH_TO_GSI@/build/src/gsi/gsi.x

ANAL_TIME=@TESTCASE_DATE@

# Loop over first and last outer loops to generate innovation
# diagnostic files for indicated observation types (groups)
#
# NOTE: Since we set miter=2 in GSI namelist SETUP, outer
# loop 03 will contain innovations with respect to
# the analysis. Creation of o-a innovation files
# is triggered by write_diag(3)=.true. The setting
# write_diag(1)=.true. turns on creation of o-g
# innovation files.
#
loops="01 03"
for loop in $loops; do
  case $loop in
    01) string=ges;;
    03) string=anl;;
    *) string=$loop;;
  esac

  # Collect diagnostic files for obs types (groups) below
  ./diag.sh ${loop} ${string}
done
