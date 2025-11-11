#!-------------------------------------------------------------------------
#!    NOAA/NCEP, National Centers for Environmental Prediction  HDASapp        !
#!-------------------------------------------------------------------------

include(funcs.cmake)

### Define CTests here ###

# FV3-JEDI tests
set(hafs_fv3jedi_tests)
# Algorithm tests
add_to_dictionary(hafs_fv3jedi_tests "hafs_fv3jedi_2024052700_3denvar"            "fv3jedi_var.x")
# Observation tests
add_to_dictionary(hafs_fv3jedi_tests "hafs_fv3jedi_2024052700_3denvar_conv_surface"  "fv3jedi_var.x")
add_to_dictionary(hafs_fv3jedi_tests "hafs_fv3jedi_2024052700_3denvar_conv_upperair" "fv3jedi_var.x")
add_to_dictionary(hafs_fv3jedi_tests "hafs_fv3jedi_2024052700_3denvar_remote"        "fv3jedi_var.x")
add_to_dictionary(hafs_fv3jedi_tests "hafs_fv3jedi_2024052700_3denvar_satrad"        "fv3jedi_var.x")

message(STATUS "Use test data from hafs-test-data repository")
set (hafs-test_data_local "${CMAKE_SOURCE_DIR}/hafs-test-data/")
set (src_yaml "${CMAKE_SOURCE_DIR}/hafs-test/testinput")
# It's unclear if anyone is using the local data functionality, therefore comment it out
# for now and add in if someone complains / remove if completely if not.
#elseif (DEFINED ENV{FV3_JEDI_TESTFILES})
#  message(STATUS "Use test data from local directory $ENV{FV3_JEDI_TESTFILES}")
#  # A bit of guesswork here, I don't know if folks using this option stored it in the same directory structure
#  set (fv3-jedi_data_testinput_tier_1_local "$ENV{FV3_JEDI_TESTFILES}/fv3-jedi-data/testinput_tier_1")

# Add some general job settings here
set(MPI_ARGS "${MPI_ARGS} --time=00:30:00 --exclusive")
set(RESTORE_MPI_ARGS ${MPI_ARGS})

if(FV3_DYCORE)

      message(STATUS "MACHINE_ID is " ${MACHINE_ID})

      get_all_keys(hafs_fv3jedi_tests caselist)
      foreach(case ${caselist})

         get_from_dictionary(hafs_fv3jedi_tests case exe)

	 # Some case-dependent settings still needed
         if ("${case}" STREQUAL "hafs_fv3jedi_2024052700_3denvar" OR "${case}" STREQUAL "hafs_fv3jedi_2024052700_getkf_solver")
           set(MPI_ARGS "${MPI_ARGS} --ntasks-per-node=10")
         elseif ("${case}" STREQUAL "hafs_fv3jedi_2024052700_3denvar_mgbf" OR "${case}" STREQUAL "hafs_fv3jedi_2024052700_hybrid3denvar_mgbf")
           set(MPI_ARGS "${MPI_ARGS} --ntasks-per-node=7")
         endif()
	 if ("${MACHINE_ID}" STREQUAL "wcoss2")
           configure_file(${CMAKE_SOURCE_DIR}/hafs-test/ush/wrapper_ctest_pbs.sh ${CMAKE_CURRENT_BINARY_DIR}/wrapper_ctest_pbs.sh COPYONLY)
	   set(COMMAND_NAME "${CMAKE_CURRENT_BINARY_DIR}/wrapper_ctest_pbs.sh")
           if ("${case}" STREQUAL "hafs_fv3jedi_2024052700_3denvar_mgbf" OR "${case}" STREQUAL "hafs_fv3jedi_2024052700_hybrid3denvar_mgbf")
             set(ARGS_NAME "${case} ${exe} ${case}.yaml 28 7")
           else()
             set(ARGS_NAME "${case} ${exe} ${case}.yaml 40 4")
           endif()
	   set(MPI_TASKS 0)
	 else()
	   set(COMMAND_NAME "${exe}")
           set(ARGS_NAME  "${case}.yaml")
           if ("${case}" STREQUAL "hafs_fv3jedi_2024052700_3denvar_mgbf" OR "${case}" STREQUAL "hafs_fv3jedi_2024052700_hybrid3denvar_mgbf")
	     set(MPI_TASKS 196)
           else()
	     set(MPI_TASKS 160)
           endif()
	 endif()

         set(casedir "${CMAKE_CURRENT_BINARY_DIR}/rundir-${case}")
         set(src_casedir "${hafs-test_data_local}/hafs-data_fv3jedi_2024052700")
         if (NOT EXISTS "${casedir}")
           file(MAKE_DIRECTORY ${casedir})
         endif()
         file(CREATE_LINK ${src_casedir}/DataFix ${casedir}/DataFix SYMBOLIC)
         file(CREATE_LINK ${src_casedir}/Data_static ${casedir}/Data_static SYMBOLIC)
         file(COPY ${src_casedir}/fmsmpp.nml DESTINATION ${casedir})
         file(COPY ${src_casedir}/field_table DESTINATION ${casedir})
         file(COPY ${src_casedir}/input_lam_C775_NP16X10.nml DESTINATION ${casedir})
         file(COPY ${src_casedir}/input_lam_C775_NP14X14.nml DESTINATION ${casedir})
         file(COPY ${src_casedir}/dynamics_lam_cmaq.yaml DESTINATION ${casedir})

         file(CREATE_LINK ${src_casedir}/INPUT ${casedir}/INPUT SYMBOLIC)
         file(CREATE_LINK ${src_casedir}/data ${casedir}/data SYMBOLIC)
         file(CREATE_LINK ${src_casedir}/fv_core.res.nc ${casedir}/fv_core.res.nc SYMBOLIC)
         file(CREATE_LINK ${src_casedir}/fv_core.res.tile1.nc ${casedir}/fv_core.res.tile1.nc SYMBOLIC)
         file(CREATE_LINK ${src_casedir}/fv_srf_wnd.res.tile1.nc ${casedir}/fv_srf_wnd.res.tile1.nc SYMBOLIC)
         file(CREATE_LINK ${src_casedir}/fv_tracer.res.tile1.nc ${casedir}/fv_tracer.res.tile1.nc SYMBOLIC)
         file(CREATE_LINK ${src_casedir}/phy_data.nc ${casedir}/phy_data.nc SYMBOLIC)
         file(CREATE_LINK ${src_casedir}/sfc_data.nc ${casedir}/sfc_data.nc SYMBOLIC)
         file(CREATE_LINK ${src_casedir}/berror_stats ${casedir}/berror_stats SYMBOLIC)
         file(CREATE_LINK ${src_casedir}/fv3_akbk ${casedir}/fv3_akbk SYMBOLIC)
         file(CREATE_LINK ${src_casedir}/fv3_grid_spec ${casedir}/fv3_grid_spec SYMBOLIC)
         file(CREATE_LINK ${src_casedir}/coupler.res ${casedir}/coupler.res SYMBOLIC)
         file(CREATE_LINK ${src_casedir}/gsiparm_regional.anl ${casedir}/gsiparm_regional.anl SYMBOLIC)
         file(CREATE_LINK ${src_casedir}/mgbf_p196_14x14.nml ${casedir}/mgbf_p196_14x14.nml SYMBOLIC)
         file(CREATE_LINK ${CMAKE_SOURCE_DIR}/hafs-test/testoutput ${casedir}/testoutput SYMBOLIC)
         file(COPY ${src_yaml}/${case}.yaml DESTINATION ${casedir} )
         set(target_test ${case})
	 if ("${target_test}" STREQUAL "hafs_fv3jedi_2024052700_getkf_solver")
           ecbuild_add_test( TARGET ${target_test}
                        MPI      ${MPI_TASKS}
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/rundir-${target_test}
                        ARGS     ${ARGS_NAME}
			TEST_DEPENDS "hafs_fv3jedi_2024052700_getkf_observer"
                        COMMAND  ${COMMAND_NAME} )
	 else()
           ecbuild_add_test( TARGET ${target_test}
                        MPI      ${MPI_TASKS}
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/rundir-${target_test}
                        ARGS     ${ARGS_NAME}
                        COMMAND  ${COMMAND_NAME} )
	 endif()
         set_property(TEST ${target_test} PROPERTY ENVIRONMENT_MODIFICATION
                      "LD_LIBRARY_PATH=path_list_prepend:${CMAKE_SOURCE_DIR}/../build/lib64")
         set(MPI_ARGS ${RESTORE_MPI_ARGS})
      endforeach()

endif()

