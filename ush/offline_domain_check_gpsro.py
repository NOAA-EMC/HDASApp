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

def parse_args():
    p = argparse.ArgumentParser(description="Offline Domain Check for GPS RO Data (No Matplotlib)")
    p.add_argument("-i", "--input", required=True, help="Input GPS RO data netCDF")
    p.add_argument("-o", "--output", required=True, help="Output filtered IODA file")
    p.add_argument("-g", "--gridspec", required=True, help="HAFS grid info NetCDF file")
    return p.parse_args()

def is_inside_vectorized(x, y, poly_x, poly_y):
    """
    Vectorized Ray Casting algorithm to check if points (x, y) are inside 
    the polygon defined by vertices (poly_x, poly_y).
    """
    n = len(poly_x)
    inside = np.zeros(len(x), dtype=bool)
    
    # Loop over the edges of the polygon
    p1x, p1y = poly_x[0], poly_y[0]
    for i in range(n + 1):
        p2x, p2y = poly_x[i % n], poly_y[i % n]
        
        # Find points where the ray (horizontal line) intersects the edge
        # Condition 1: y is between the y-coordinates of the edge endpoints
        mask = (y > min(p1y, p2y)) & (y <= max(p1y, p2y))
        
        # Condition 2: x is to the left of the intersection point
        if np.any(mask):
            # Calculate x-coordinate of the intersection of the edge with line Y=y
            x_inters = (y[mask] - p1y) * (p2x - p1x) / (p2y - p1y + 1e-10) + p1x
            inside[mask] = inside[mask] ^ (x[mask] < x_inters)
            
        p1x, p1y = p2x, p2y
        
    return inside

def main():
    args = parse_args()

    # --- Extract Model Domain Boundary ---
    print("Loading model domain...")
    with nc.Dataset(args.gridspec, 'r') as grid_ds:
        grid_lat = grid_ds.variables['grid_lat'][:]
        grid_lon = grid_ds.variables['grid_lon'][:]

    # Construct boundary vertices
    edge_lon = np.concatenate([
        grid_lon[0, :],         # Bottom edge
        grid_lon[:, -1],        # Right edge
        grid_lon[-1, :][::-1],  # Top edge
        grid_lon[:, 0][::-1]    # Left edge
    ])
    edge_lat = np.concatenate([
        grid_lat[0, :],
        grid_lat[:, -1],
        grid_lat[-1, :][::-1],
        grid_lat[:, 0][::-1]
    ])

    # --- Evaluate Observations ---
    print("Loading observation coordinates...")
    src_ds = nc.Dataset(args.input, 'r')
    meta_grp = src_ds.groups['MetaData']

    obs_lat = meta_grp.variables['latitude'][:]
    obs_lon = meta_grp.variables['longitude'][:]
    obs_seqnum = meta_grp.variables['sequenceNumber'][:]

    # Handle masked arrays
    lon_vals = np.ma.filled(obs_lon, np.nan)
    lat_vals = np.ma.filled(obs_lat, np.nan)
    seq_vals = np.ma.filled(obs_seqnum, -999)

    # Convert to 0-360 if grid uses it
    if grid_lon.max() > 180.0:
        print("Normalizing longitudes to 0-360...")
        lon_vals = np.where((lon_vals < 0) & np.isfinite(lon_vals), lon_vals + 360.0, lon_vals)

    print("Checking spatial bounds (Vectorized PIP)...")
    valid_coord_mask = np.isfinite(lon_vals) & np.isfinite(lat_vals)
    
    # Check only valid points
    is_inside = np.zeros(len(lon_vals), dtype=bool)
    is_inside[valid_coord_mask] = is_inside_vectorized(
        lon_vals[valid_coord_mask], 
        lat_vals[valid_coord_mask], 
        edge_lon, edge_lat
    )

    # --- Profile-based Filtering ---
    # Find sequence numbers that have any point OUTSIDE
    bad_seqnums = np.unique(seq_vals[valid_coord_mask & ~is_inside])
    bad_seqnums = bad_seqnums[bad_seqnums != -999]

    # Keep only profiles where NO points were outside
    keep_mask = ~np.isin(seq_vals, bad_seqnums)
    valid_indices = np.where(keep_mask)[0]

    num_total = len(obs_lat)
    num_kept = len(valid_indices)
    print(f"Total: {num_total} | Kept: {num_kept} | Dropped: {num_total - num_kept}")

    if num_kept == 0:
        print("No data in domain. Exiting.")
        src_ds.close()
        return

    # --- Write Output ---
    print(f"Writing to {args.output}...")
    with nc.Dataset(args.output, 'w', format='NETCDF4') as dst_ds:
        # Copy global attributes
        dst_ds.setncatts({attr: src_ds.getncattr(attr) for attr in src_ds.ncattrs()})
        dst_ds.createDimension('Location', num_kept)

        def copy_var(src_v, parent_dst, name, idx):
            fval = getattr(src_v, '_FillValue', None)
            dv = parent_dst.createVariable(name, src_v.datatype, src_v.dimensions, fill_value=fval)
            dv.setncatts({a: src_v.getncattr(a) for a in src_v.ncattrs() if a != '_FillValue'})
            dv[:] = src_v[idx]

        # Top level variables
        for v_name, v_obj in src_ds.variables.items():
            copy_var(v_obj, dst_ds, v_name, valid_indices)

        # Groups (IODA style)
        for g_name, g_obj in src_ds.groups.items():
            new_grp = dst_ds.createGroup(g_name)
            new_grp.setncatts({a: g_obj.getncattr(a) for a in g_obj.ncattrs()})
            for v_name, v_obj in g_obj.variables.items():
                copy_var(v_obj, new_grp, v_name, valid_indices)

    src_ds.close()
    print("Complete.")

if __name__ == "__main__":
    main()
