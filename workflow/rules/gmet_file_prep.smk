
# This Snakemake file prepares the GMET data for use in 
from pathlib import Path

#Set input and output directories
forcing_dir = config['forcing']['forcing_dir']
file_tmp_dir = config['forcing']['tmp_forcing_dir']

#Set the list of forcing files to process
#The id is the name of the forcing file without the extension
gmet_forcing_files, = glob_wildcards(Path(forcing_dir,"{id}.nc"))

#This first rule establishes the output files that will be created
rule gmet_file_prep:
    input:
        expand(Path(file_tmp_dir,"{id}_prep.nc"), id=gmet_forcing_files)

#Add greogrian calendar to the time variable, needed for easymore  
rule add_gregorian:
    input:  
        Path(forcing_dir,"{id}.nc")
    output: 
        temp(Path(file_tmp_dir,"{id}_greg.nc"))
    shell: 
        'ncatted -a "calendar,time,o,c,"gregorian"" {input} {output}'

#Process temperature data to create t_max and t_min
rule add_t_max_and_t_min:
    input: 
        input_file = Path(file_tmp_dir,"{id}_greg.nc")
    output:
        temp = temp(Path(file_tmp_dir,"{id}_temp.nc")),
        output_file =Path(file_tmp_dir,"{id}_prep.nc")
    shell:
        """
        ncap2 -s "t_max = t_mean+0.5+t_range" -A {input.input_file} {output.temp};
        ncap2 -s "t_min = t_mean+0.5-t_range" -A {output.temp};
        ncatted -O -a long_name,t_max,o,c,"estimated daily maximum temperature" {output.temp};
        ncatted -O -a long_name,t_min,o,c,"estimated daily minimum temperature" {output.temp};
        cp {output.temp} {output.output_file}
        """
