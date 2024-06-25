help([[
Load environment for running the HDAS application with Intel compilers and MPI.
]])

local pkgName    = myModuleName()
local pkgVersion = myModuleVersion()
local pkgNameVer = myModuleFullName()

prepend_path("MODULEPATH", '/work/noaa/epic/role-epic/spack-stack/orion/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core')
prepend_path("MODULEPATH", '/work2/noaa/da/python/opt/modulefiles/stack')

-- below two lines get us access to the spack-stack modules
load("stack-intel/2021.9.0")
load("stack-intel-oneapi-mpi/2021.9.0")
-- JCSDA has 'jedi-fv3-env/unified-dev', but we should load these manually as needed
load("cmake/3.23.1")
load("curl/8.4.0")
load("zlib/1.2.13")
load("git/2.31.1")
load("hdf5/1.14.0")
load("parallel-netcdf/1.12.2")
load("netcdf-c/4.9.2")
load("nccmp/1.9.0.1")
load("netcdf-fortran/4.6.1")
load("nco/5.0.6")
load("parallelio/2.5.10")
load("wget/1.21.1")
load("boost/1.83.0")
load("bufr/12.0.1")
load("git-lfs/3.1.2")
load("ecbuild/3.7.2")
load("openjpeg/2.3.1")
load("eccodes/2.32.0")
load("eigen/3.4.0")
load("openblas/0.3.24")
load("eckit/1.24.5")
load("fftw/3.3.10")
load("fckit/0.11.0")
load("fiat/1.2.0")
load("ectrans/1.2.0")
load("atlas/0.35.1")
load("sp/2.5.0")
load("gsl-lite/0.37.0")
load("libjpeg/2.1.0")
load("krb5/1.20.1")
load("libtirpc/1.3.3")
load("hdf/4.2.15")
load("jedi-cmake/1.4.0")
load("libpng/1.6.37")
load("libxt/1.1.5")
load("libxmu/1.1.4")
load("libxpm/4.11.0")
load("libxaw/1.0.13")
load("udunits/2.2.28")
load("ncview/2.1.9")
load("netcdf-cxx4/4.3.1")
load("py-pybind11/2.11.0")
--load("crtm/v2.4_jedi")
load("contrib/0.1")
load("noaatools/3.1")
load("rocoto/1.3.5")

load("hpc/1.2.0")
unload("python/3.10.13")
unload("py-numpy/1.22.3")
load("miniconda3/4.6.14")
load("gdasapp/1.0.0")

-- below is a hack because of cmake finding the wrong python...
setenv("CONDA_PREFIX", "/work2/noaa/da/python/opt/core/miniconda3/4.6.14/envs/gdasapp/")

setenv("CC","mpiicc")
setenv("FC","mpiifort")
setenv("CXX","mpiicpc")
local mpiexec = '/opt/slurm/bin/srun'
local mpinproc = '-n'
setenv('MPIEXEC_EXEC', mpiexec)
setenv('MPIEXEC_NPROC', mpinproc)

setenv("CRTM_FIX","/work2/noaa/da/cmartin/GDASApp/fix/crtm/2.4.0")
setenv("HDASAPP_TESTDATA","/work2/noaa/da/cmartin/CI/GDASApp/data")

execute{cmd="ulimit -s unlimited",modeA={"load"}}

whatis("Name: ".. pkgName)
whatis("Version: ".. pkgVersion)
whatis("Category: HDASApp")
whatis("Description: Load all libraries needed for HDASApp")
