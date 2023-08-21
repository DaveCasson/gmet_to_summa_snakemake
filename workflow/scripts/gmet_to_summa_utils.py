"""

Utilities for converting gmet files to summa files

"""

import xarray as xr
from pathlib import Path
from datetime import datetime
import numpy as np
from snakemake.logging import logger

from pprint import pformat

def resolve_paths(config,log_config = False):
    """Resolve paths from the configuration file"""

    # Log the settings if required
    if log_config:
        logger.info(f'Settings logged from {config}')
        config_to_log = pformat(config)
        logger.debug(f'Settings: {config_to_log}')

    promoted_config = promote_keys(config)
    config.update(promoted_config)

    # Resolve gmet paths
    config['gmet_tmp_forcing_dir'] = Path(config['working_dir'], 'gmet_tmp')

    # Resolve easymore paths
    config['easymore_dir'] = Path(config['working_dir'], 'easymore')
    config['easymore_intersect_dir'] = Path(config['easymore_dir'], 'intersect')
    config['easymore_temp_dir'] = Path(config['easymore_dir'], 'temp')
    config['easymore_output_dir'] = Path(config['easymore_dir'], 'output')

    config['forcing_shp_path'] = Path(config['easymore_intersect_dir'],config['forcing_shp'])

    # Resolve metsim paths
    config['metsim_dir'] = Path(config['working_dir'], 'metsim')
    config['metsim_input_dir'] = Path(config['metsim_dir'], 'input')
    config['metsim_output_dir'] = Path(config['metsim_dir'], 'output')

    # Define the remapping file that is created by easymore
    remap_file_str = config['base_settings']['case_name'] + '_remapping.csv'
    config['remap_file'] = Path(config['easymore_temp_dir'], remap_file_str)

    return config                  

def promote_keys(nested_dict):
    """Promote keys from a nested dictionary to the top level"""
    promoted_dict = {}

    for primary_key, secondary_dict in nested_dict.items():
        # Check that secondary_dict is a dictionary
        if isinstance(secondary_dict, dict):
            for secondary_key, value in secondary_dict.items():
                promoted_dict[secondary_key] = value

    return promoted_dict

def build_ensemble_list(directory):
    ''' Build a list of the ensemble name and the file name for each file in the directory
        e.g. for each file in the directory: ens_forc.tuolumne.01d.2020.001.nc' --> 001/ens_forc.tuolumne.01d.2020.001.nc
    '''
    
    path = Path(directory)
    files = path.glob('*') 
    file_path_list = set()
    ensemble_list = set()  

    for file in files:
        if file.exists():
            filename = file.stem  # Get the filename without the extension
            ens = filename[-3:]  # Get the last three characters
            ensemble_list.add(ens)
            file_path_list.add(Path(ens, filename)) # Create and add the ens/filename.nc path

    return ensemble_list, file_path_list

def list_files_in_subdirectory(directory, suffix_to_remove='.nc'):
    path = Path(directory)
    file_paths = [file.relative_to(path).as_posix().replace(suffix_to_remove, "") for file in path.glob('**/*') if file.is_file()]

    return file_paths

def return_first_file(directory):
    #Return first file in a directory
    directory_path = Path(directory)
    directory_path.mkdir(parents=True, exist_ok=True)
    # List all files recursively
    file_list = list(directory_path.rglob('*'))
    # Filter out directories from the file list
    if len(file_list) == 0:
        first_file = "No file found"
    else:
        # Create iterator and extract first file
        tmp_forcing_files = [file for file in file_list if file.is_file()]
        first_file = tmp_forcing_files[0]
        #tmp_forcing_files_iter = iter(tmp_forcing_files)
        #first_file = next(tmp_forcing_files_iter)

    return first_file


def update_time_units(input_file, output_file):
    """Update time encoding in netcdf file"""
    
    dataset = xr.open_dataset(input_file)
    dataset.time.encoding['units'] = "seconds since 1970-01-01 00:00:00"
    dataset.to_netcdf(output_file)
    dataset.close()

def get_time_range(nc_file):
    # Open the netCDF file
    ds = xr.open_dataset(nc_file)
    # Get the time variable
    time_var = ds['time']
    # Get the start and end times
    start_time = time_var[0].values.astype('datetime64[D]').astype(str)
    end_time = time_var[-1].values.astype('datetime64[D]').astype(str)
    # Close the netCDF file
    ds.close()
    # Return the start and end times
    return start_time, end_time

def generate_gru_start_and_count(sim_size, chunk_size: int=None, num_chunks: int=None):
        '''
        Generate a list of gru start and stop times for parallel simulation.
        Original code: https://github.com/UW-Hydro/pysumma/blob/master/pysumma/distributed.py#L104
        '''
        assert not (chunk_size and num_chunks), \
            "Only specify at most one of `chunk_size` or `num_chunks`!"
        start, stop = 0, 0
        if not (chunk_size or num_chunks):
            chunk_size = 12
        if chunk_size:
            sim_truncated = (chunk_size-1) * (sim_size // (chunk_size-1))
            starts = np.arange(1, sim_truncated+1, chunk_size).astype(int)
            stops = np.append(starts[1:], sim_size+1)
            chunks = np.vstack([starts, stops]).T
        elif num_chunks:
            chunk_size = np.ceil(sim_size / num_chunks).astype(int)
            starts = np.arange(1, sim_size, chunk_size)
            stops = np.append(starts[1:], sim_size+1)
            chunks = np.vstack([starts, stops]).T
        
        gru_chunk_dict = [{'startGRU': start, 'countGRU': stop - start}
                for start, stop in chunks]
        
        gru_chunk_strings = ["G{:02d}-{:02d}".format(item['startGRU'], item['startGRU'] + item['countGRU'] - 1) for item in gru_chunk_dict]

        return gru_chunk_strings


def calc_num_grus(attribute_nc):
    """
    Calculate the number of GRUs in the SUMMA model.
    """
    with xr.open_dataset(attribute_nc) as ds:
        num_grus = ds['gruId'].shape[0]
    ds.close()
    return num_grus
    
def extract_gru_int(s):
    """Extract an integer value for the startGRU from the gru_chunk"""
    string_value = list(s)[0]   
    return int(string_value[1:string_value.index('-')])