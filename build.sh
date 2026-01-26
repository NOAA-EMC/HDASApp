#!/bin/bash

# build.sh
# 1 - determine host, load modules on supported hosts; proceed w/o otherwise
# 2 - configure; build; install
# 4 - optional, run unit tests

set -eu

echo "Start ... `date`"
dir_root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $dir_root/ush/detect_machine.sh
source $dir_root/ush/init.sh

# ==============================================================================
usage() {
  set +x
  echo
  echo "Usage: $0 -p <prefix> | -t <target> -h"
  echo
  echo "  -p  installation prefix <prefix>    DEFAULT: <none>"
  echo "  -t  target to build for <target>    DEFAULT: $MACHINE_ID"
  echo "  -c  additional CMake options        DEFAULT: <none>"
  echo "  -v  build with verbose output       DEFAULT: NO"
  echo "  -b  build JCB                       DEFAULT: YES"
  echo "  -f  force a clean build             DEFAULT: NO"
  echo "  -d  include HAFS ctest data         DEFAULT: NO"
  echo "  -a  build everything in bundle      DEFAULT: NO"
  echo "  -h  display this message and quit"
  echo
  exit 1
}

# ==============================================================================

# Defaults:
INSTALL_PREFIX=""
CMAKE_OPTS=""
BUILD_TARGET="${MACHINE_ID:-'localhost'}"
BUILD_JOBS="${BUILD_JOBS:-8}"
BUILD_VERBOSE="${BUILD_VERBOSE:-"NO"}"
CLONE_JCSDADATA="NO"
BUILD_TESTING="OFF"
BUILD_HAFS_TEST="NO"
CLEAN_BUILD="NO"
BUILD_JCSDA="NO"
BUILD_JCB="YES"
COMPILER="${COMPILER:-intel}"

while getopts "p:t:c:b:hvdfa" opt; do
  case $opt in
    p)
      INSTALL_PREFIX=$OPTARG
      ;;
    t)
      BUILD_TARGET=$OPTARG
      ;;
    c)
      CMAKE_OPTS=$OPTARG
      ;;
    b)
      BUILD_JCB=$OPTARG
      ;;
    v)
      BUILD_VERBOSE=YES
      ;;
    d)
      BUILD_HAFS_TEST=YES
      ;;
    f)
      CLEAN_BUILD=YES
      ;;
    a)
      BUILD_JCSDA=YES
      ;;
    h|\?|:)
      usage
      ;;
  esac
done

case ${BUILD_TARGET} in
  hera | orion | hercules | wcoss2 | noaacloud | gaeac5 | gaeac6 | ursa )
    echo "Building HDASApp on $BUILD_TARGET"
    source $dir_root/ush/module-setup.sh
    module use $dir_root/modulefiles
    module load HDAS/$BUILD_TARGET.$COMPILER
    CMAKE_OPTS+=" -DMPIEXEC_EXECUTABLE=$MPIEXEC_EXEC -DMPIEXEC_NUMPROC_FLAG=$MPIEXEC_NPROC -DMACHINE_ID=$MACHINE_ID"
    module list
    ;;
  $(hostname))
    echo "Building HDASApp on $BUILD_TARGET"
    ;;
  *)
    echo "Building HDASApp on unknown target: $BUILD_TARGET"
    ;;
esac

#CMAKE_OPTS+=" -DCLONE_JCSDADATA=$CLONE_JCSDADATA -DMACHINE=$BUILD_TARGET -DBUILD_TESTING=$BUILD_TESTING"
#CMAKE_OPTS+=" -DCLONE_JCSDADATA=$CLONE_JCSDADATA -DMACHINE=$BUILD_TARGET"
CMAKE_OPTS+="  -DBUILD_TESTING=$BUILD_TESTING"
# TODO: Remove LD_LIBRARY_PATH line as soon as permanent solution is available
if [[ $BUILD_TARGET == 'wcoss2' ]]; then
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/opt/cray/pe/mpich/8.1.19/ofi/intel/19.0/lib"
fi

BUILD_DIR=${BUILD_DIR:-$dir_root/build}
if [[ $CLEAN_BUILD == 'YES' ]]; then
  [[ -d ${BUILD_DIR} ]] && rm -rf ${BUILD_DIR}
fi
mkdir -p ${BUILD_DIR} && cd ${BUILD_DIR}

# If INSTALL_PREFIX is not empty; install at INSTALL_PREFIX
[[ -n "${INSTALL_PREFIX:-}" ]] && CMAKE_OPTS+=" -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}"

# activate tests based on if this is cloned within the global-workflow
WORKFLOW_BUILD=${WORKFLOW_BUILD:-"OFF"}
CMAKE_OPTS+=" -DWORKFLOW_TESTS=${WORKFLOW_BUILD}"

# JCSDA changed test data things, need to make a dummy CRTM directory
if [ -d "$dir_root/bundle/fix/test-data-release/" ]; then rm -rf $dir_root/bundle/fix/test-data-release/; fi
if [ -d "$dir_root/bundle/test-data-release/" ]; then rm -rf $dir_root/bundle/test-data-release/; fi
mkdir -p $dir_root/bundle/fix/test-data-release/
mkdir -p $dir_root/bundle/test-data-release/
ln -sf $HDASAPP_TESTDATA/crtm $dir_root/bundle/fix/test-data-release/crtm
ln -sf $HDASAPP_TESTDATA/crtm $dir_root/bundle/test-data-release/crtm

# Install the jcb clients
if [[ $BUILD_JCB == 'YES' ]]; then
  cd $dir_root/sorc/jcb
  #python jcb_client_init.py
  # Build an example jedi.yaml
  #PYTHONPATH="${PYTHONPATH}:$dir_root/sorc/jcb/src/:$dir_root/build/lib/python3.*:${dir_root}/sorc/wxflow/src"
  #cd $dir_root/sorc/jcb/src/jcb/configuration/apps/hdas/test/client_integration
  #python run.py
  cd $dir_root/sorc/jcb/src/jcb/configuration/apps/
  ln -sf $dir_root/parm/jcb-hdas hdas
  cd $dir_root/sorc/jcb/src/jcb/configuration/
  ln -sf $dir_root/parm/jcb-algorithms algorithms
  cd ${BUILD_DIR}
fi

# Create super yamls and link in test data
if [[ $BUILD_HAFS_TEST == 'YES' ]]; then

  # Build the ctest yamls - gen_yaml
  #cd $dir_root/hafs-test/validated_yamls
  #./gen_yaml_ctest.sh

  # Build the ctest yamls - jcb
  #PYTHONPATH="${PYTHONPATH}:$dir_root/sorc/jcb/src/:$dir_root/build/lib/python3.*:${dir_root}/sorc/wxflow/src"

  cd $dir_root/hafs-test/testinput

  ctest_yamls=(
    # Algorithm ctests
    hafs_fv3jedi_2024070806_3denvar.yaml
    hafs_fv3jedi_2024070806_4denvar.yaml
    # Observation ctests (fv3jedi & 3dvar only)
    #hafs_fv3jedi_2024070806_3dvar_conv_surface.yaml
  )

  cp $dir_root/parm/jcb-hdas/test/ci/run_jcb_ctest.py .
  #for ctest_yaml in "${ctest_yamls[@]}"; do
  #  jcb_config="jcb-$ctest_yaml"
  #  cp $dir_root/parm/jcb-hdas/test/ci/$jcb_config .
  #  python run_jcb_ctest.py 2024070806 $jcb_config $ctest_yaml
  #  ctest=${ctest_yaml%.yaml}
  #done
  cd ${BUILD_DIR}

  # Link in test data for experimrnts: FV3-JEDI
  echo "Linking in test data for FV3-JEDI case"
  $dir_root/hafs-test/scripts/link_fv3jedi_expr.sh
fi

CMAKE_OPTS+=" -DMPIEXEC_MAX_NUMPROCS:STRING=120 -DBUILD_HAFS_TEST=$BUILD_HAFS_TEST"

# Configure
echo "Configuring ... `date`"
set -x
cmake \
  ${CMAKE_OPTS:-} \
  $dir_root/bundle
set +x

# Build
echo "Building ... `date`"
set -x
if [[ $BUILD_JCSDA == 'YES' ]]; then
  make -j ${BUILD_JOBS:-8} VERBOSE=$BUILD_VERBOSE
else
  #builddirs="fv3-jedi iodaconv bufr-query da-utils"
  builddirs="fv3-jedi bufr-query"
  for b in $builddirs; do
    cd $b
    set +x      
    echo "Building $b ... `date`"
    set -x
    make -j ${BUILD_JOBS} VERBOSE=$BUILD_VERBOSE
    cd ../
  done
fi
set +x

# Install
if [[ -n ${INSTALL_PREFIX:-} ]]; then
  echo "Installing ... `date`"
  set -x
  make install -j ${BUILD_JOBS:-8}
  set +x
fi
echo "Finish ... `date`"
exit 0
