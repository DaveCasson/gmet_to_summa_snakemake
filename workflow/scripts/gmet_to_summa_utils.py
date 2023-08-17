"""

Utilities for converting gmet files to summa files

"""

from pathlib import Path
import xarray as xr

def promote_keys(nested_dict):
    """Promote keys from a nested dictionary to the top level"""
    promoted_dict = {}

    for primary_key, secondary_dict in nested_dict.items():
        # Check that secondary_dict is a dictionary
        if isinstance(secondary_dict, dict):
            for secondary_key, value in secondary_dict.items():
                promoted_dict[secondary_key] = value

    return promoted_dict

def resolve_paths(config):
    """Resolve paths from the configuration file"""
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