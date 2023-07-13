
# Import needed packages
from pathlib import Path
import sys
sys.path.append('../')
from scripts import remap_forcing_to_shp
from scripts import gmet_to_summa_utils as gts_utils

# Resolve paths from the configuration file
config = gts_utils.resolve_paths(config)

# Read all forcing files and create a list based on the output directory (i.e. ens/filename.nc)
ensemble_list, file_path_list = gts_utils.build_ensemble_list(config['gmet_forcing_dir'])

# Create a list of the temporary forcing files produced in the last workflow
file_tmp_dir = Path(config['gmet_tmp_forcing_dir'])
tmp_forcing_files = list(file_tmp_dir.glob('*'))
       
rule remap_gmet_to_shp:
    input:
        expand(Path(config['easymore_output_dir'],"{file}_prep.nc"), file=file_path_list)

# Define rule to run file remapping when remap file exists
rule create_remap_file:
    input:
        input_forcing_file = tmp_forcing_files[0],
        input_shp = config['catchment_shp']
    output:
        remap_csv = config['remap_file']
    run:
        remap_forcing_to_shp.remap_with_easymore(config, input.input_forcing_file ,input.input_shp, output.remap_csv, only_create_remap_csv=True)

# Define rule to run file remapping when remap file exists
rule remap_with_easymore:
    input:
        input_forcing = Path(file_tmp_dir,"{id}_prep.nc"),
        input_shp = config['catchment_shp'],
        remap_csv = config['remap_file'],
        ens_str = "{id}"[:3]
    output:
        output_forcing = Path(config['easymore_output_dir'],"{id}_prep.nc", file=file_path_list)
    run:
        remap_forcing_to_shp.remap_with_easymore(config, input.input_forcing,input.input_shp,input.remap_csv,ens=ens_str)


