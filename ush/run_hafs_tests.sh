#!/bin/sh
##srun --account=hurricane --partition=hera --nodes=16 --ntasks=160 --cpus-per-task=4 --mem=0 --time=02:00:00 --exclusive --pty bash
##export SLURM_OVERLAP=1
## ./run_hafs_tests.sh hurricane
export SLURM_ACCOUNT=${1}
export PBS_ACCOUNT=${1}

if [[ "${1}" == "" ]]; then
  echo "Usage: ${0}  account_name"
  exit 1
fi

#
ushdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source ${ushdir}/load_hdas.sh

set -x
cd ${ushdir}/../build/hafs-test
pwd

ulimit -s unlimited
ulimit -v unlimited
ulimit -a

ctest -vv # or ctest -VV for verbose outputs
exit $?
