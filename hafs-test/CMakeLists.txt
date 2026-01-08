#!-------------------------------------------------------------------------
#!    NOAA/NCEP, National Centers for Environmental Prediction  RDASapp        !
#!-------------------------------------------------------------------------

include(funcs.cmake)

### Define CTests here ###

# FV3-JEDI tests
set(hafs_fv3jedi_tests)
# Algorithm tests
add_to_dictionary(hafs_fv3jedi_tests "hafs_fv3jedi_2024070806_3denvar"            "fv3jedi_var.x")
add_to_dictionary(hafs_fv3jedi_tests "hafs_fv3jedi_2024070806_4denvar"            "fv3jedi_var.x")
# Observation tests
#add_to_dictionary(hafs_fv3jedi_tests "hafs_fv3jedi_2024070806_3dvar_conv_surface"  "fv3jedi_var.x")

message(STATUS "Use test data from hafs-test-data repository")
set (hafs-test_data_local "${CMAKE_SOURCE_DIR}/hafs-test-data/")
set (src_yaml "${CMAKE_SOURCE_DIR}/hafs-test/testinput")

# Add some general job settings here
set(MPI_ARGS "${MPI_ARGS} --time=00:30:00 --exclusive")
set(RESTORE_MPI_ARGS ${MPI_ARGS})

message(STATUS "MACHINE_ID is " ${MACHINE_ID})

get_all_keys(hafs_fv3jedi_tests caselist)
foreach(case ${caselist})

   get_from_dictionary(hafs_fv3jedi_tests case exe)

	 # Some case-dependent settings still needed
   if ("${case}" STREQUAL "hafs_fv3jedi_2024070806_3denvar" OR "${case}" STREQUAL "hafs_fv3jedi_2024070806_4denvar")
     set(MPI_ARGS "${MPI_ARGS} --ntasks=160")
     set(IS_HEAVY_TEST TRUE)
   else()
     set(IS_HEAVY_TEST FALSE)
   endif()
   if ("${MACHINE_ID}" STREQUAL "wcoss2")
     configure_file(${CMAKE_SOURCE_DIR}/hafs-test/ush/wrapper_ctest_pbs.sh ${CMAKE_CURRENT_BINARY_DIR}/wrapper_ctest_pbs.sh COPYONLY)
     set(COMMAND_NAME "${CMAKE_CURRENT_BINARY_DIR}/wrapper_ctest_pbs.sh")
     set(ARGS_NAME "${case} ${exe} ${case}.yaml 40 4")
     set(MPI_TASKS 0)
   else()
     set(COMMAND_NAME "${exe}")
     set(ARGS_NAME  "${case}.yaml")
     set(MPI_TASKS 160)
   endif()

   set(casedir "${CMAKE_CURRENT_BINARY_DIR}/rundir-${case}")
   set(src_casedir "${hafs-test_data_local}/hafs-data_fv3jedi_2024070806")
   if (NOT EXISTS "${casedir}")
     file(MAKE_DIRECTORY ${casedir})
     file(MAKE_DIRECTORY ${casedir}/hofx)
   endif()
   
   file(CREATE_LINK ${src_casedir}/DataFix ${casedir}/DataFix SYMBOLIC)
   file(CREATE_LINK ${src_casedir}/INPUT ${casedir}/INPUT SYMBOLIC)
   file(CREATE_LINK ${src_casedir}/bkg ${casedir}/bkg SYMBOLIC)
   file(CREATE_LINK ${src_casedir}/bump ${casedir}/bump SYMBOLIC)
   file(CREATE_LINK ${src_casedir}/ensemble_data ${casedir}/ensemble_data SYMBOLIC)
   file(CREATE_LINK ${src_casedir}/obs ${casedir}/obs SYMBOLIC)
   file(CREATE_LINK ${CMAKE_SOURCE_DIR}/hafs-test/testoutput ${casedir}/testoutput SYMBOLIC)
   file(COPY ${src_yaml}/${case}.yaml DESTINATION ${casedir} )
   set(target_test ${case})

   ecbuild_add_test( TARGET ${target_test}
                MPI      ${MPI_TASKS}
                WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/rundir-${target_test}
                ARGS     ${ARGS_NAME}
                COMMAND  ${COMMAND_NAME} )
   if (IS_HEAVY_TEST)
      set_tests_properties(${target_test} PROPERTIES
          PROCESSORS 160
          RUN_SERIAL TRUE
      )
   endif()

   set_property(TEST ${target_test} PROPERTY ENVIRONMENT_MODIFICATION
                "LD_LIBRARY_PATH=path_list_prepend:${CMAKE_SOURCE_DIR}/../build/lib64")
   set(MPI_ARGS ${RESTORE_MPI_ARGS})
endforeach()
