import numpy as np
import sys, os
from netCDF4 import Dataset
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import argparse


parser = argparse.ArgumentParser()
parser.add_argument('-v', '--variable', type=str, help='variable name', required=True)
parser.add_argument('-o', '--obtype', type=int, help='bufr observation type', required=True)
#parser.add_argument('-f', '--figname', type=str, help='figname', required=True)
args = parser.parse_args()

variable = args.variable
obtype = args.obtype
#figname = args.figname
odiag={'windEastward':'uv','windNorthward':'uv','airTemperature':'t','specificHumidity':'q', 'radialVelocity':'rw'}
otype={'windEastward':'wind_220','windNorthward':'wind_220','airTemperature':'t_120','specificHumidity':'q_120', 'radialVelocity':'rw'}

datapath = "/scratch2/NCEPDEV/hwrf/scrub/Jing.Cheng/jediwork/test/hafs-data_fv3jedi_2024063012"
#jedi = f"{datapath}/ADPUPA_IODA_hofx_{otype[variable]}_qc.nc"
#jedi = f"{datapath}/NEXRAD_GSI_hofx_{otype[variable]}.nc"
#jedi = f"{datapath}/AIRCAR_IODA_hofx_{odiag[variable]}_{obtype}.nc"
jedi = f"{datapath}/AIRCFT_IODA_hofx_{odiag[variable]}_{obtype}.nc"
print(f'read in jedi file {jedi}')
datapath = "/scratch2/NCEPDEV/hwrf/scrub/Jing.Cheng/jediwork/test/gsi_2024063012"
gsi = f"{datapath}/diag_conv_{odiag[variable]}_ges.2024063012"

# JEDI read
nc_jedi = Dataset(jedi, 'r')
omb_jedi = nc_jedi.groups['ombg'].variables[f'{variable}'][:]
err_jedi = nc_jedi.groups['EffectiveError0'].variables[f'{variable}'][:]
jedi_otype = nc_jedi.groups['ObsType'].variables[variable][:]

# GSI read
nc_gsi = Dataset(gsi, 'r')
anl_use_flag = nc_gsi.variables['Analysis_Use_Flag'][:]
gsi_otype = nc_gsi.variables['Observation_Type'][:]
err_gsi = 1.0/nc_gsi.variables['Errinv_Final'][:]

if variable == "windEastward":
    omb_gsi = nc_gsi.variables['u_Obs_Minus_Forecast_adjusted'][:]
elif variable == "windNorthward":
    omb_gsi = nc_gsi.variables['v_Obs_Minus_Forecast_adjusted'][:]
else:
    omb_gsi = nc_gsi.variables['Obs_Minus_Forecast_adjusted'][:]

# Filter GSI obs by analysis use flag.
condition1 = (anl_use_flag != 1)
condition2 = gsi_otype != obtype 
condition3 = jedi_otype != obtype
#omb_gsi = np.ma.masked_where(anl_use_flag != 1, omb_gsi)
omb_gsi = np.ma.masked_where((condition1 | condition2), omb_gsi)
#omb_gsi = np.ma.masked_where( condition2, omb_gsi)
#err_gsi = np.ma.masked_where(anl_use_flag != 1, err_gsi)
err_gsi = np.ma.masked_where((condition1 | condition2), err_gsi)
#err_gsi = np.ma.masked_where( condition2, err_gsi)
print(err_gsi.count())

omb_jedi = np.ma.masked_where(condition3, omb_jedi)
err_jedi = np.ma.masked_where(condition3, err_jedi)

# Variable units and conversions
if variable == "stationPressure":
    omb_jedi = omb_jedi / 100.0 # from Pa to hPa
    err_jedi = err_jedi / 100.0
    units = "hPa"
    xlim_err = 3
    xlim_omb = 15
if variable == "windEastward" or variable == "windNorthward":
    units = "m/s"
    xlim_err = 10
    xlim_omb = 15
if variable == "airTemperature":
    units = "K"
    xlim_err = 10
    xlim_omb = 15
if variable == "specificHumidity":
    omb_jedi = omb_jedi * 1000.0 # from kg/kg to g/kg 
    err_jedi = err_jedi * 1000.0
    omb_gsi = omb_gsi * 1000.0 # from kg/kg to g/kg 
    err_gsi = err_gsi * 1000.0
    units = "g/kg"
    xlim_err = 10
    xlim_omb = 15
if variable == "radialVelocity":
    xlim_omb=15
    xlim_err = 10
    units = "m/s"
# Remove masked errors
omb_jedi = omb_jedi[~err_jedi.mask]
err_jedi = err_jedi[~err_jedi.mask]
omb_gsi = omb_gsi[~err_gsi.mask]
err_gsi = err_gsi[~err_gsi.mask]

# Counts
nobs_jedi = omb_jedi.count()
nobs_gsi = omb_gsi.count()
# Title
#plt.figure(figsize=(8,0.25))
#plt.suptitle(f"{figname}")
#plt.tight_layout()
#plt.savefig(f"title.png", format='png', dpi=300)

# JEDI Plots

# Histogram for omb
binmax = 50
binwidth = 1
plt.figure(figsize=(4,3))
n, bins, patches = plt.hist(omb_jedi, bins=range(-1*binmax,binmax+binwidth,binwidth), color = 'tab:red', edgecolor='k', alpha=0.7, label='JEDI nobs = %s' % nobs_jedi)
ylim_omb=np.round(max(n)*1.2)
print(ylim_omb)
plt.xlim([-1*xlim_omb,xlim_omb])
#plt.ylim([0,8500])
plt.ylim([0,ylim_omb])
plt.xlabel(rf'O-b [${units}$]')
plt.ylabel('Count')
plt.legend(loc='upper left', prop={'size':7})
plt.tight_layout()
plt.savefig(f"{variable}_{obtype}_hist_omb_jedi.png", format='png', dpi=300)
plt.close()

# Histogram for obs error
binmax = 50
binwidth = 0.1
plt.figure(figsize=(4,3))
n, bins, patches = plt.hist(err_jedi, bins=np.arange(0,binmax+binwidth,binwidth), color = 'tab:red', edgecolor='k', alpha=0.7, label='JEDI nobs = %s' % nobs_jedi)
plt.xlim([0,xlim_err])
ylim_oberr=np.round(max(n)*1.2)
#plt.ylim([0,240])
plt.ylim([0,ylim_oberr])
plt.xlabel(rf'Obs. error [${units}$]')
plt.ylabel('Count')
plt.legend(loc='upper left', prop={'size':7})
plt.tight_layout()
plt.savefig(f"{variable}_{obtype}_hist_err_jedi.png", format='png', dpi=300)
plt.close()
print(np.min(err_jedi), np.max(err_jedi))

# GSI Plots
# Histogram for omb
binmax = 50
binwidth = 1
plt.figure(figsize=(4,3))
n, bins, patches = plt.hist(omb_gsi, bins=range(-1*binmax,binmax+binwidth,binwidth), color = 'tab:blue', edgecolor='k', alpha=0.7, label='GSI nobs = %s' % nobs_gsi)
plt.xlim([-1*xlim_omb,xlim_omb])
plt.ylim([0,ylim_omb])
plt.xlabel(rf'O-b [${units}$]')
plt.ylabel('Count')
plt.legend(loc='upper left', prop={'size':7})
plt.tight_layout()
plt.savefig(f"{variable}_{obtype}_hist_omb_gsi.png", format='png', dpi=300)
plt.close()

# Histogram for obs error
binmax = 50
binwidth = 0.1
plt.figure(figsize=(4,3))
n, bins, patches = plt.hist(err_gsi, bins=np.arange(0,binmax+binwidth,binwidth), color = 'tab:blue', edgecolor='k', alpha=0.7, label='GSI nobs = %s' % nobs_gsi)
plt.xlim([0,xlim_err])
plt.ylim([0,ylim_oberr])
#plt.ylim([0,240])

plt.xlabel(rf'Obs. error [${units}$]')
plt.ylabel('Count')
plt.legend(loc='upper left', prop={'size':7})
plt.tight_layout()
plt.savefig(f"{variable}_{obtype}_hist_err_gsi.png", format='png', dpi=300)
plt.close()
