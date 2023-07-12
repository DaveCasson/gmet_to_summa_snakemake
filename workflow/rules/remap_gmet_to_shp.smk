
# Import needed packages
from pathlib import Path
import sys
sys.path.append('../')
from scripts import remap_forcing_to_shp

# Create a list of the the original forcing files
forcing_dir = config['forcing']['forcing_dir']
file_base, deg_base,years,ens = glob_wildcards(Path(forcing_dir, "{file_name}.{deg}.{year}.{ens}.nc"))

config['input_shp'] = Path(config['base_settings']['shp_dir'], config['base_settings']['catchment_shp'])
config['easymore_output_dir'] = Path(config['easymore']['output_dir'])
config['easymore_temp_dir'] = Path(config['easymore']['temp_dir'])

# Create a list of the temporary forcing files produced in the last workflow
file_tmp_dir = Path(config['forcing']['tmp_forcing_dir'])
tmp_forcing_files = list(file_tmp_dir.glob('*'))
easymore_output = Path(config['easymore']['output_dir'])

# Define the output files that are created
shape_file_from_forcing = Path(config['easymore']['intersect_dir'], config['easymore']['forcing_shp'])
remap_file_str = config['base_settings']['case_name'] + '_remapping.csv'
remap_file = Path(config['easymore']['temp_dir'], remap_file_str)
       
rule remap_gmet_to_shp:
    input:
        expand(Path(easymore_output,"{ens}","{file_base}.{deg}.{year}.{ens}_prep.nc"), file_base=file_base, deg=deg_base, year=years, ens=ens)

# Define rule to run file remapping when remap file exists
rule create_remap_file:
    input:
        input_forcing_file = tmp_forcing_files[0],
        input_shp = config['input_shp']
    output:
        remap_csv = remap_file
    run:
        remap_forcing_to_shp.remap_with_easymore(config, input.input_forcing_file ,input.input_shp, output.remap_csv, only_create_remap_csv=True)

# Define rule to run file remapping when remap file exists
rule remap_with_easymore:
    input:
        input_forcing = Path(file_tmp_dir,"{id}_prep.nc"),
        input_shp = config['input_shp'],
        remap_csv = remap_file
    output:
        output_forcing = Path(config['easymore_output_dir'],"{ens}","{id}_prep.nc", ens=ens)
    run:
        remap_forcing_to_shp.remap_with_easymore(config, input.input_forcing,input.input_shp,input.remap_csv,ens_member={wildcards.ens})


