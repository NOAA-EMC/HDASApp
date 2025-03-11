#!/bin/bash
#SBATCH --nodes=1 #--ntasks-per-node=1
#SBATCH --account=@SLURM_ACCOUNT@
#SBATCH --qos=debug

#SBATCH -t 00:30:00
#SBATCH --job-name=ioda_test
#SBATCH -o iodanc.log
#SBATCH --open-mode=truncate

set +x

module purge

module use @YOUR_PATH_TO_HDASAPP@/modulefiles
module load HDAS/@MACHINE_ID@.intel

export OOPS_TRACE=1
export OMP_NUM_THREADS=1

ulimit -s unlimited
ulimit -v unlimited
ulimit -a

cd `pwd`
inputfile=$1
if [[ $inputfile == "" ]]; then
  inputfile=./prepbufr_adpupa.yaml
fi
cyc=@DATE_TIME@
reftime=$(date -u -d "${cyc:0:8} ${cyc:8:2}:${cyc:10:2}" +"%Y-%m-%dT%H:%M:%SZ")
echo "$reftime"
sed -i "s#@referenceTime@#${reftime}#g" ./${inputfile}

ln -sf gfs.prepbufr.2024063012 prepbufr

jedibin="@YOUR_PATH_TO_HDASAPP@/build/bin"

$jedibin/bufr2ioda.x $inputfile
exit
