#!/usr/bin/env python3
"""
offline_domain_check_gpsro.py

gpsro offline domain check
Reads a HAFS domain grids (grid_spec.nc) and filter out the gpsro observation outside
of model domain, including the profile that across the model boundary.

e.g.
#obs_file = 'hafs.t12z.gnssro_cosmic2.nc'
#grid_file = 'grid_spec.nc'
#output_file = 'gnssro_domain_filtered.nc'
"""
import argparse
import netCDF4 as nc
import numpy as np
from matplotlib.path import Path

def parse_args():
    p = argparse.ArgumentParser(description="Offline Domain Check for GPS RO Data")
    p.add_argument("-i", "--input", required=True, help="Input GPS RO data netCDF")
    p.add_argument("-o", "--output", required=True, help="Output thinned IODA file")
    p.add_argument("-g", "--gridspec", help="HAFS grid info NetCDF file (e.g., grid_spec.nc)")
    return p.parse_args()

args = parse_args()
obs_file = args.input
grid_file = args.gridspec
output_file = args.output

# --- 2. Extract Model Domain Boundary ---
print("Loading model domain...")
with nc.Dataset(grid_file, 'r') as grid_ds:
    grid_lat = grid_ds.variables['grid_lat'][:]
    grid_lon = grid_ds.variables['grid_lon'][:]

# Construct the boundary polygon from the outermost edges of the grid
edge_lon = np.concatenate([
    grid_lon[0, :],         # Bottom edge
    grid_lon[:, -1],        # Right edge
    grid_lon[-1, :][::-1],  # Top edge (reversed)
    grid_lon[:, 0][::-1]    # Left edge (reversed)
])
edge_lat = np.concatenate([
    grid_lat[0, :],
    grid_lat[:, -1],
    grid_lat[-1, :][::-1],
    grid_lat[:, 0][::-1]
])

# Create a matplotlib Path object representing the domain polygon
domain_polygon = Path(np.column_stack((edge_lon, edge_lat)))

# --- 3. Evaluate Observations ---
print("Loading observation coordinates...")
src_ds = nc.Dataset(obs_file, 'r')
meta_grp = src_ds.groups['MetaData']

obs_lat = meta_grp.variables['latitude'][:]
obs_lon = meta_grp.variables['longitude'][:]
obs_seqnum = meta_grp.variables['sequenceNumber'][:]

# Replace masked values with NaN so they aren't treated as real locations (like 3.4e38)
lon_vals = np.ma.filled(obs_lon, np.nan)
lat_vals = np.ma.filled(obs_lat, np.nan)
seq_vals = np.ma.filled(obs_seqnum, -999) # Use -999 as a placeholder for missing sequence numbers

print(f"Diagnostics - Grid Lon Min/Max: {grid_lon.min():.2f} / {grid_lon.max():.2f}")
# Calculate min/max only on valid data for accurate diagnostics
valid_lon_mask = np.isfinite(lon_vals)
print(f"Diagnostics - Obs Lon Min/Max: {lon_vals[valid_lon_mask].min():.2f} / {lon_vals[valid_lon_mask].max():.2f}")

# If the model grid uses 0-360, we must convert the observation longitudes to 0-360
# just for the spatial evaluation.
if grid_lon.max() > 180.0:
    print("Converting observation longitudes to 0-360 convention for boundary check...")
    # Convert negative longitudes (e.g., -100) to positive 0-360 format (e.g., 260)
    lon_vals = np.where((lon_vals < 0) & np.isfinite(lon_vals), lon_vals + 360.0, lon_vals)

print("Checking observations against domain boundary...")
# Create a mask of points that are physically valid coordinates (ignoring missing data)
valid_coord_mask = np.isfinite(lon_vals) & np.isfinite(lat_vals)

# Stack ONLY the valid coordinates for the point-in-polygon check
valid_coords = np.column_stack((lon_vals[valid_coord_mask], lat_vals[valid_coord_mask]))

# Evaluate ONLY valid coordinates against the domain polygon
is_inside_valid = domain_polygon.contains_points(valid_coords)

# Get the sequence numbers corresponding to these valid coordinates
seqnums_of_valid_points = seq_vals[valid_coord_mask]

# Find sequence numbers that have at least one VALID point outside the domain
bad_seqnums = np.unique(seqnums_of_valid_points[~is_inside_valid])

# Ensure our missing placeholder (-999) isn't accidentally classified as a bad profile
bad_seqnums = bad_seqnums[bad_seqnums != -999]

# Create the master keep_mask for the ENTIRE array (including rows with FillValues)
# If a sequence number is NOT in the bad list, we keep all its levels
keep_mask = ~np.isin(seq_vals, bad_seqnums)

# Get the actual array indices to keep
valid_indices = np.where(keep_mask)[0]

num_total = len(obs_lat)
num_kept = len(valid_indices)
num_dropped = num_total - num_kept

print(f"Total observations: {num_total}")
print(f"Observations dropped: {num_dropped} (belonging to {len(bad_seqnums)} out-of-bounds profiles)")
print(f"Observations kept: {num_kept}")
if num_kept == 0:
    print("No observations are inside the domain. Exiting without creating output.")
    src_ds.close()
    exit()

# --- 4. Write Filtered Data to New NetCDF ---
print(f"Writing filtered data to {output_file}...")
dst_ds = nc.Dataset(output_file, 'w', format='NETCDF4')

# Copy Global Attributes
src_global_attrs = {attr: src_ds.getncattr(attr) for attr in src_ds.ncattrs()}
dst_ds.setncatts(src_global_attrs)

# Create Location Dimension
dst_ds.createDimension('Location', num_kept)

def copy_variable(src_var, dst_grp_or_ds, var_name, indices):
    """Helper function to copy variables and slice them using our valid_indices."""
    fill_value = getattr(src_var, '_FillValue', None)
    
    dst_var = dst_grp_or_ds.createVariable(
        varname=var_name, 
        datatype=src_var.datatype, 
        dimensions=src_var.dimensions, 
        fill_value=fill_value
    )
    
    # Copy attributes (excluding _FillValue)
    var_attrs = {attr: src_var.getncattr(attr) for attr in src_var.ncattrs() if attr != '_FillValue'}
    dst_var.setncatts(var_attrs)
    
    # Write sliced data
    dst_var[:] = src_var[indices]

for var_name, src_var in src_ds.variables.items():
    copy_variable(src_var, dst_ds, var_name, valid_indices)

for grp_name, src_grp in src_ds.groups.items():
    dst_grp = dst_ds.createGroup(grp_name)
    grp_attrs = {attr: src_grp.getncattr(attr) for attr in src_grp.ncattrs()}
    dst_grp.setncatts(grp_attrs)
    
    for var_name, src_var in src_grp.variables.items():
        copy_variable(src_var, dst_grp, var_name, valid_indices)

# --- 5. Cleanup ---
src_ds.close()
dst_ds.close()

print("Filtering complete!")

