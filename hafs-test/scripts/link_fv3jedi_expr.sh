#!/bin/bash
HDASApp=$( git rev-parse --show-toplevel 2>/dev/null )
if [[ -z ${HDASApp} ]]; then
  echo "Not under a clone of HDASApp!"
  echo "Please delete line 2-7 and set HDASApp variable mannually"
  exit
fi

#HDASApp="/path/to/HDASApp"  # set this variable if line2-7 was removed
exprname="fv3_2024070806"
expdir=${HDASApp}/expr/${exprname}  # can be set to any directory
mkdir -p ${expdir}
cd ${expdir}
echo "expdir is at: ${expdir}"

${HDASApp}/ush/init.sh
cp -r ${HDASApp}/hafs-test/testoutput ./testoutput
cp ${HDASApp}/hafs-test/testinput/hafs_fv3jedi_2024070806_3denvar.yaml .
cp ${HDASApp}/hafs-test/testinput/hafs_fv3jedi_2024070806_4denvar.yaml .
cp ${HDASApp}/hafs-test/testinput/hafs_fv3jedi_2024070806_bumploc.yaml bumploc.yaml
sed -e "s#@HDASApp@#${HDASApp}#" ${HDASApp}/hafs-test/scripts/templates/fv3jedi_expr/run_bump.sh > run_bump.sh
sed -e "s#@HDASApp@#${HDASApp}#" ${HDASApp}/hafs-test/scripts/templates/fv3jedi_expr/run_jedi.sh > run_jedi.sh
cp ${HDASApp}/hafs-test/ush/colormap.py .
cp ${HDASApp}/hafs-test/ush/fv3jedi_increment_singleob.py .
cp ${HDASApp}/hafs-test/ush/fv3jedi_increment_fulldom.py .
rm -rf data; mkdir data
ln -snf ${HDASApp}/fix/expr_data/${exprname}/data/bump/bump_16x10 ./bump 
ln -snf ${HDASApp}/fix/expr_data/${exprname}/data/bkg .
ln -snf ${HDASApp}/fix/expr_data/${exprname}/ensemble_data .
#ln -snf ${HDASApp}/fix/expr_data/${exprname}/data/bkg/20240708.060000.fv_core.res.nest02.nc fv3_akbk
# link correct ioda files
rm -rf obs
ln -snf ${HDASApp}/fix/expr_data/${exprname}/data/obs .  # keep this line for now to be backward compatible

mkdir -p hofx
ln -snf ${HDASApp}/fix/expr_data/${exprname}/DataFix DataFix
#cp ${HDASApp}/fix/expr_data/${exprname}/DataFix/fmsmpp.nml .
#cp ${HDASApp}/fix/expr_data/${exprname}/DataFix/field_table .
#cp ${HDASApp}/fix/expr_data/${exprname}/DataFix/input_hafs_nest.nml .
ln -snf ${HDASApp}/fix/expr_data/${exprname}/INPUT INPUT
