"""

Utilities for preparing and running metsim

"""

from pathlib import Path
import xarray as xr
import numpy as np
from collections import OrderedDict
import yaml

from metsim import MetSim

from . import gmet_to_summa_utils as gts_utils

def create_metsim_config(config, input_forcing_file, input_state_file, output_file):
    """Create metsim configuration file, both from master configuration file and from hardwired settings"""
    
    # Read base configuration from yaml file
    with open(config['metsim_base_config']) as file:
        metsim_base_config = OrderedDict(yaml.load(file, Loader=yaml.FullLoader))

    #Derive start and end time from forcing file
    start_time, end_time = gts_utils.get_time_range(input_forcing_file)
    metsim_base_config["start"] = str(start_time)
    metsim_base_config["stop"] = str(end_time)

    # Set input forcing and state
    metsim_base_config["forcing"] = str(input_forcing_file)
    metsim_base_config["state"] = str(input_state_file)

    # Set domain file and output file path
    metsim_base_config["domain"] = str(Path(config['metsim_dir'],config["metsim_domain_nc"]))
    output_file_path = Path(output_file)
    metsim_base_config['out_dir'] = str(output_file_path.parent)
    
    #Set other settings
    metsim_base_config["out_freq"] = config['metsim']['out_freq']
    metsim_base_config["scheduler"] = "threading"
    metsim_base_config['time_step'] = str(config['metsim_timestep_minutes'])

    # Create MetSim object
    ms = MetSim(metsim_base_config)

    return ms

def rename_metsim_output(ms,new_file_name):
    ms_output = [ms._get_output_filename(times) for times in ms._times]

    if len(ms_output) == 1:
        ms_output_file = Path(ms_output[0])
        ms_output_file.rename(new_file_name)
    elif len(ms_output) > 1:
        output = xr.open_mfdataset(ms_output, concat_dim='time')
        output.to_netcdf(new_file_name)
    elif len(ms_output) == 0:
        raise ValueError("No output files were generated by MetSim")

    return

def create_state_file(input_forcing_file, output_state_file,timestep_hrs=24):
    # Open the input file
    ds = xr.open_dataset(input_forcing_file)
    # Get the time variable
    time_var = ds['time']
    # Get the number of records
    nrecs = len(time_var)
    # Get the start time of the original file
    end_time = time_var[-1].values
    # Select the last 90 days of data
    data = ds.sel(time=slice(end_time - np.timedelta64(89 * 24 * 3600, 's'), end_time))
    # Shift the time nrecs days previously
    data['time'] = data['time'] - np.timedelta64(nrecs * timestep_hrs * 3600, 's')
    # Output the data to a new file
    data.to_netcdf(output_state_file)
    
    return

def subset_domain_to_forcing(domain_input_nc, forcing_file, domain_subset_nc):
    """Subset domain file to forcing with smaller domain"""

    # Open NetCDF to xarray dataset
    domain_ds = xr.open_dataset(domain_input_nc)
    forcing_ds = xr.open_dataset(forcing_file)

    # Return only domain hrus that match the forcing hrus
    domain_subset = domain_ds.where(domain_ds.hruId.isin(forcing_ds.hruId), drop=True)
    # Trim further to only remaining grus. Otherwise drop of gru could be used.
    domain_gru = domain_subset.gruId.where(
        domain_ds.gruId.isin(domain_subset.hru2gruId), drop=True
    )
    domain_subset["gruId"] = domain_gru[0]

    # Sort by hruId
    domain_subset = domain_subset.sortby("hruId")

    # Set filename and output to netcdf
    domain_subset.to_netcdf(domain_subset_nc)

    domain_ds.close()
    forcing_ds.close()

    return