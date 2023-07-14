
from pathlib import Path
import sys
import xarray as xr
import numpy as np
import pandas as pd

sys.path.append('../')
from scripts import gmet_to_summa_utils as gts_utils
from scripts import metsim_utils as ms_utils

# Resolve paths from the configuration file
config = gts_utils.resolve_paths(config)

# Create a list of the forcing files produced in the last workflow
#input_forcing_list = gts_utils.list_files_in_subdirectory(config['easymore_output_dir'], config['prep_suffix'])
# Create a list of the temporary forcing files produced in the last workflow
#file_tmp_dir = Path(config['easymore_output_dir'])
# List all files recursively
#file_list = list(file_tmp_dir.rglob('*'))
# Filter out directories from the file list
#full_path_forcing_list = [file.name for file in file_list if file.is_file()]
#print(input_forcing_list)
input_forcing_list = gts_utils.list_files_in_subdirectory(config['easymore_output_dir'])

# Read all forcing files and create a list based on the output directory (i.e. ens/filename.nc)
#ensemble_list, input_forcing_list = gts_utils.build_ensemble_list(config['easymore_output_dir'])
#print(ensemble_list)
#print(input_forcing_list)
easymore_output = Path(config['easymore_output_dir']) 
metsim_input = Path(config['metsim_input_dir'])

# Main rule to define the files produced by this workflow
rule prepare_metsim_files:
    input:
        Path(config["metsim"]["metsim_dir"], config["metsim_domain_nc"]),
        expand(Path(metsim_input,"{forcing}.nc"), forcing = input_forcing_list),
        expand(Path(metsim_input,"{forcing}_state.nc"), forcing = input_forcing_list)
         
# Create metsim domain file from an existing summa attribute file
rule create_metsim_domain_summa_attr:
    input:
        attr_nc = Path(config["attribute_nc"])
    output:
        domain_nc = Path(config["summa"]["summa_dir"], config["metsim_domain_nc"])
    shell:
        'ncap2 -O -s "mask=elevation*0+1" {input.attr_nc} {output.domain_nc}'

rule subset_metsim_domain_to_forcing:
    input:
        domain_nc = Path(config["summa_dir"], config["metsim_domain_nc"]),
        forcing_file = Path(easymore_output,f'{input_forcing_list[0]}.nc')
    output:
        subset_nc = Path(config["metsim_dir"], config["metsim_domain_nc"])
    run:
        ms_utils.subset_domain_to_forcing(input.domain_nc, input.forcing_file, output.subset_nc)

# Define rule to run file remapping when remap file exists
rule prep_forcing_files_with_hru_id:
    input:
        input_forcing = Path(easymore_output,"{forcing}.nc")
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
        ms_utils.create_state_file(input.input_forcing_file, output.output_state_file)

rule update_state_file_time:
    input:
        input_state_file = Path(metsim_input,"{forcing}_state_temp.nc")
    output:
        output_state_file = Path(metsim_input,"{forcing}_state.nc")
    run:
        gts_utils.update_time_units(input.input_state_file, output.output_state_file)
