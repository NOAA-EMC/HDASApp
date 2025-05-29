#!/bin/bash
# update_develop.sh
# update specified repositories to most recent develop hash

repos="
oops
vader
saber
ioda
ufo
fv3-jedi
iodaconv
"

my_dir="$( cd "$( dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd )"

hdasdir=${1:-${my_dir}/../../}

for r in $repos; do
  echo "Updating ${hdasdir}/sorc/${r}"
  cd ${hdasdir}/sorc
  git submodule update --remote --merge ${r}
done
cd ${hdasdir}
