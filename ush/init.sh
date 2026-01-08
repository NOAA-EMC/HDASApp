#!/bin/sh
#
ushdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source ${ushdir}/detect_machine.sh
basedir="$(dirname "$ushdir")"

case ${MACHINE_ID} in
  wcoss2)
    HDAS_DATA=/lfs/h2/emc/lam/noscrub/HDAS_DATA
    ;;
  hera)
    HDAS_DATA=/scratch4/HFIP/hwrfv3/save/Jing.Cheng/HDAS_DATA
    ;;
  ursa)
    HDAS_DATA=/scratch4/BMC/rtrr/HDAS_DATA
    ;;
  jet)
    HDAS_DATA=/lfs5/BMC/nrtrr/HDAS_DATA
    ;;
  orion|hercules)
    HDAS_DATA=/work/noaa/zrtrr/HDAS_DATA
    ;;
  derecho)
    HDAS_DATA=/to/be/done
    ;;
  gaeac?)
    if [[ -d /gpfs/f5 ]]; then
      HDAS_DATA=/gpfs/f5/gsl-glo/world-shared/role.rrfsfix/HDAS_DATA
    elif [[ -d /gpfs/f6 ]]; then
      HDAS_DATA=/gpfs/f6/bil-fire10-oar/world-shared/role.rrfsfix/HDAS_DATA
    else
      echo "unsupported gaea cluster: ${MACHINE_ID}"
    fi
    ;;
  *)
    echo "platform not supported: ${MACHINE_ID}"
    ;;
esac

agentfile=${basedir}/fix/.agent
filetype=$(file ${agentfile})
if [[ ! "${filetype}" == *"symbolic link"* ]]; then
  rm -rf ${agentfile}
fi
mkdir -p ${basedir}/fix
ln -snf ${HDAS_DATA}/fix ${agentfile}
touch ${basedir}/fix/INIT_DONE
