
# This Snakemake file prepares the GMET data for use in 
from pathlib import Path
import sys
sys.path.append('../')
from scripts import gmet_to_summa_utils as utils

# Resolve paths from the configuration file
config = utils.resolve_paths(config)

#Set the list of forcing files to process
#The id is the name of the forcing file without the extension
gmet_forcing_files, = glob_wildcards(Path(config['gmet_forcing_dir'],"{forcing_file}.nc"))

#This first rule establishes the output files that will be created
rule gmet_file_prep:
    input:
        expand(Path(config['gmet_tmp_forcing_dir'],"{forcing_file}_prep.nc"), forcing_file=gmet_forcing_files)

#Add greogrian calendar to the time variable, needed for easymore  
rule add_gregorian_to_nc:
    input:  
        input_forcing = Path(config['gmet_forcing_dir'],"{id}.nc")
    output: 
        output_forcing = temp(Path(config['gmet_tmp_forcing_dir'],"{id}_greg.nc"))
    shell: 
        'ncatted -a "calendar,time,o,c,"gregorian"" {input.input_forcing} {output.output_forcing}'

#Process temperature data to create t_max and t_min
rule add_t_max_and_t_min:
    input: 
        input_file = Path(config['gmet_tmp_forcing_dir'],"{id}_greg.nc")
    output:
        temp = temp(Path(config['gmet_tmp_forcing_dir'],"{id}_temp.nc")),
        output_file = Path(config['gmet_tmp_forcing_dir'],"{id}_prep.nc")
    shell:
        """
        ncap2 -s "t_max = t_mean+0.5+t_range" -A {input.input_file} {output.temp};
        ncap2 -s "t_min = t_mean+0.5-t_range" -A {output.temp};
        ncatted -O -a long_name,t_max,o,c,"estimated daily maximum temperature" {output.temp};
        ncatted -O -a long_name,t_min,o,c,"estimated daily minimum temperature" {output.temp};
        cp {output.temp} {output.output_file}
        """
