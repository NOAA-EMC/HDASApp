#!/bin/bash
#SBATCH --account=@SLURM_ACCOUNT@
#SBATCH --qos=debug
#SBATCH --ntasks=600

#SBATCH -t 00:30:00
#SBATCH --job-name=fv3jedi_test
#SBATCH -o jedi.log
#SBATCH --open-mode=truncate
#SBATCH --cpus-per-task 4 --exclusive

. /apps/lmod/lmod/init/sh
set +x

module purge

module use @YOUR_PATH_TO_HDASAPP@/modulefiles
module load HDAS/@MACHINE_ID@.intel

module list

export OOPS_TRACE=1
export OMP_NUM_THREADS=1

ulimit -s unlimited
ulimit -v unlimited
ulimit -a

module list

cd `pwd`
inputfile=$1
if [[ $inputfile == "" ]]; then
  inputfile=./testinput/@DEFAULT_YAML@.yaml
fi
obsdir=./obsout
if [[ ! -d "$obsdir" ]]; then
  echo "Missing obs file, link from GSI_TEST/obsout"
  ln -sf ../gsi_@DATE_TIME@/obsout .

fi

jedibin="@YOUR_PATH_TO_HDASAPP@/build/bin"
# Run JEDI - currently cannot change processor count
srun -l -n 600 $jedibin/fv3jedi_var.x ./$inputfile out.log
rm out.log.0*

exit
