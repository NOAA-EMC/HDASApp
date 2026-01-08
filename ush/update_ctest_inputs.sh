#!/bin/bash

# This script is designed as a standalone version of hafs-test/CMakeLists.txt
# Running this will update the input files (data, yamls, etc.) for each ctest
# Note that the ctest configurations (test names, mpi_args) are not updated here

DYCORE="FV3JEDI" # [FV3JEDI, MPASJEDI, BOTH]

# FV3-JEDI tests
hafs_fv3jedi_tests=(
    "hafs_fv3jedi_2024070806_3dvar"
    "hafs_fv3jedi_2024070806_3denvar"
)

# Select tests based on DYCORE
ctest_yamls=()
if [[ "$DYCORE" == "FV3JEDI" || "$DYCORE" == "BOTH" ]]; then
  ctest_yamls+=("${hafs_fv3jedi_tests[@]}")
fi

echo "Use test data from hafs-test-data repository"
HDASApp=$( git rev-parse --show-toplevel 2>/dev/null )
CMAKE_SOURCE_DIR=${HDASApp}/bundle
CMAKE_CURRENT_BINARY_DIR=${HDASApp}/build/hafs-test
hafs_test_data_local=${CMAKE_SOURCE_DIR}/hafs-test-data/
src_yaml=${CMAKE_SOURCE_DIR}/hafs-test/testinput

# Source HDAS modules so that we don't have any python version issues in gen_yaml_ctest.sh
source load_hdas.sh

# First run the gen_yaml script to regenerate the ctest yamls
currdir=`pwd`
cd ${HDASApp}/hafs-test/validated_yamls
./gen_yaml_ctest.sh
cd ${currdir}

# Run jcb to regenerate the ctest yamls
PYTHONPATH="${PYTHONPATH}:${HDASApp}/sorc/jcb/src/:${HDASApp}/build/lib/python3.*:${HDASApp}/sorc/wxflow/src"
cd "${src_yaml}"
cp "${HDASApp}/parm/jcb-hdas/test/ci/run_jcb_ctest.py" .

for ctest_yaml in "${ctest_yamls[@]}"; do
  ctest_yaml="${ctest_yaml}.yaml"
  jcb_config="jcb-${ctest_yaml}"
  cp "${HDASApp}/parm/jcb-hdas/test/ci/${jcb_config}" .
  python run_jcb_ctest.py 2024070806 "${jcb_config}" "${ctest_yaml}"
done
cd ${currdir}

if [[ $DYCORE == "FV3JEDI" || $DYCORE == "BOTH" ]]; then
   # Relink fix into expr in case new obs are added
   echo "Linking in test data for FV3-JEDI case"
   ${HDASApp}/hafs-test/scripts/link_fv3jedi_expr.sh
   for ctest in "${hafs_fv3jedi_tests[@]}"; do
      case=${ctest}
      echo "Updating ${case}..."
      casedir=${CMAKE_CURRENT_BINARY_DIR}/rundir-${case}
      src_casedir=${hafs_test_data_local}/hafs-data_fv3jedi_2024070806
      ln -snf ${src_casedir}/DataFix ${casedir}/DataFix
      ln -snf ${casedir}/DataFix/field_table ${casedir}/.
      ln -snf ${casedir}/DataFix/fmsmpp.nml ${casedir}/.
      ln -snf ${casedir}/DataFix/input_hafs_nest.nml ${casedir}/.
#      ln -snf ${casedir}/DataFix/fix/dynamics_lam_cmaq.yaml ${casedir}/.
#      ln -snf ${src_casedir}/Data_static ${casedir}/Data_static
      ln -snf ${src_casedir}/INPUT ${casedir}/INPUT
      ln -snf ${src_casedir}/data ${casedir}/data
      ln -snf ${casedir}/data/bkg/20240708*nc ${casedir}/.
      ln -snf ${casedir}/data/bkg/20240708.060000.fv_core.res.nc ${casedir}/fv_core.res.nc
      ln -snf ${casedir}/data/bkg/20240708.060000.fv_core.res.tile1.nc ${casedir}/fv_core.res.tile1.nc
      ln -snf ${casedir}/data/bkg/20240708.060000.fv_srf_wnd.res.tile1.nc ${casedir}/fv_srf_wnd.res.tile1.nc
      ln -snf ${casedir}/data/bkg/20240708.060000.fv_tracer.res.tile1.nc ${casedir}/fv_tracer.res.tile1.nc
#      ln -snf ${casedir}/data/bkg/20240708.060000.phy_data.nc ${casedir}/phy_data.nc
      ln -snf ${casedir}/data/bkg/20240708.060000.sfc_data.nc ${casedir}/sfc_data.nc
      ln -snf ${CMAKE_SOURCE_DIR}/hafs-test/testoutput ${casedir}/testoutput
      cp ${src_yaml}/${case}.yaml ${casedir}
   done
fi

echo "All done."
