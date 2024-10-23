#!/bin/bash

#use this script to combine the basic config yaml with an obtype config yaml.
basic_config="fv3jedi_3denvar.yaml"
#obtype_config="satwnd_uv.yaml"
#obtype_config="adpupa_uv_220.yaml"
#obtype_config="adpupa_specificHumidity_120.yaml"
#obtype_config="adpupa_stationPressure_120.yaml"
obtype_config="adpupa_airTemperature_120.yaml"
#OBSFILE="Data/obs/hafs.2024063012.ADPUPA.nc"
OBSFILE="Data/obs/sonde_singleob_airTemperature_2024063012.nc4"


# Don't edit below this line.

# copy the basic configuration yaml into the new yaml
cp -p templates/basic_config/$basic_config ./$obtype_config

# use the stread editor to replace the instance of @OBSERVATION@ placeholder
# in the basic configuration file with the contents of the obtype config yaml.
sed -i '/@OBSERVATIONS@/{
        r templates/obtype_config/'"${obtype_config}"'
        d
}' ./$obtype_config

sed -i "s#@OBSFILE@#${OBSFILE}#g" ./$obtype_config

