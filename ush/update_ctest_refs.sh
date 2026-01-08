#!/bin/bash

# This script is designed as a standalone version of hafs-test/CMakeLists.txt
# Running this will update the input files (data, yamls, etc.) for each ctest
# Note that the ctest configurations (test names, mpi_args) are not updated here

DYCORE="FV3JEDI" # [FV3JEDI, MPASJEDI, BOTH]

# FV3-JEDI tests
hafs_fv3jedi_tests=(
    "hafs_fv3jedi_2024070806_3denvar"
)

echo "Use test data from hafs-test-data repository"
HDASApp=$( git rev-parse --show-toplevel 2>/dev/null )
CMAKE_SOURCE_DIR=${HDASApp}/bundle
CMAKE_CURRENT_BINARY_DIR=${HDASApp}/build/hafs-test
ref_out=${CMAKE_SOURCE_DIR}/hafs-test/testoutput

if [[ $DYCORE == "FV3JEDI" || $DYCORE == "BOTH" ]]; then
   for ctest in "${hafs_fv3jedi_tests[@]}"; do
      case=${ctest}
      echo "Updating ${case}..."
      casedir=${CMAKE_CURRENT_BINARY_DIR}/rundir-${case}
      if [[ -d ${casedir} ]]; then
          if [[ $(find "$casedir" -type f -name "hafs-fv3jedi*.out") ]]; then
              cp ${casedir}/hafs-fv3jedi*out ${ref_out} # WAIT, NEED TO CHANGE THE NAME
          else
              echo "    No file files found for ${ctest}... skipping!"
          fi
      else
          echo "    Ctest directory: ${ctest} does not exist... skipping!"
      fi
   done
fi

# Now change the names
for file in $(find "$ref_out" -type f -name "*hafs-*.out*"); do
   echo "Overwriting ${file%???}ref..."
   mv ${file} ${file%???}ref
done

echo "All done."
