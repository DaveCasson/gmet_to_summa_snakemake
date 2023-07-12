
from pathlib import Path
import sys
import xarray as xr
import numpy as np
import pandas as pd

def list_files_in_subdirectory(directory, suffix_to_remove):
    path = Path(directory)
    file_paths = [file.relative_to(path).as_posix().replace(suffix_to_remove, "") for file in path.glob('**/*') if file.is_file()]
    return file_paths

input_file_suffix = '_prep.nc'
input_forcing_list = list_files_in_subdirectory(Path(config['easymore']['output_dir']), input_file_suffix)

easymore_output = Path(config['easymore']['output_dir']) 
metsim_input = Path(config['metsim']['metsim_input_dir'])

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

    domain_ds.close()
    forcing_ds.close()

    # Set filename and output to netcdf
    domain_subset.to_netcdf(domain_subset_nc)

def update_time_units(input_file, output_file):
    """Update time encoding in netcdf file"""
    
    dataset = xr.open_dataset(input_file)
    dataset.time.encoding['units'] = "seconds since 1970-01-01 00:00:00"
    dataset.to_netcdf(output_file)
    dataset.close()

rule prepare_metsim_files:
    input:
         expand(Path(metsim_input,"{forcing}.nc"), forcing = input_forcing_list),
         expand(Path(metsim_input,"{forcing}_state.nc"), forcing = input_forcing_list),
         Path(config["metsim"]["metsim_dir"], config["metsim"]["domain_nc"])

         
# Create metsim domain file from an existing summa attribute file
rule create_metsim_domain_summa_attr:
    input:
        attr_nc = Path(config["summa"]["attr_nc"])
    output:
        domain_nc = Path(config["summa"]["summa_dir"], config["metsim"]["domain_nc"])
    shell:
        'ncap2 -O -s "mask=elevation*0+1" {input.attr_nc} {output.domain_nc}'

rule subset_metsim_domain_to_forcing:
    input:
        domain_nc = Path(config["summa"]["summa_dir"], config["metsim"]["domain_nc"]),
        forcing_file = Path(easymore_output,f'{input_forcing_list[0]}{input_file_suffix}')
    output:
        subset_nc = Path(config["metsim"]["metsim_dir"], config["metsim"]["domain_nc"])
    run:
        subset_domain_to_forcing(input.domain_nc, input.forcing_file, output.subset_nc)

# Define rule to run file remapping when remap file exists
rule prep_forcing_files_with_hru_id:
    input:
        input_forcing = Path(easymore_output,"{forcing}_prep.nc")

    output:
        hru_id_temp = temp(Path(easymore_output,"{forcing}_hruId.nc")),
        hru_id = Path(metsim_input,"{forcing}.nc")
    shell:
        """
        ncap2 -O -s "hru=array(0,1,hruId)" {input.input_forcing} {output.hru_id_temp};
        ncatted -O -a long_name,hru,a,c,"hru coordinate index" {output.hru_id_temp} {output.hru_id}
        """
        
rule create_state_file:
    input:
        input_forcing_file = Path(metsim_input,"{forcing}.nc")
    output:
        output_state_file = Path(metsim_input,"{forcing}_state_temp.nc")
    run:
        create_state_file(input.input_forcing_file, output.output_state_file)

rule update_state_file_time:
    input:
        input_state_file = Path(metsim_input,"{forcing}_state_temp.nc")
    output:
        output_state_file = Path(metsim_input,"{forcing}_state.nc")
    run:
        update_time_units(input.input_state_file, output.output_state_file)

