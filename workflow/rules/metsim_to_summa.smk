from pathlib import Path

# Import custom functions
sys.path.append('../')
from scripts import gmet_to_summa_utils as gts_utils

# Resolve paths from the configuration file
config = gts_utils.resolve_paths(config)

input_forcing_list = gts_utils.list_files_in_subdirectory(config['metsim_output_dir'], '.nc')

rule metsim_to_summa:
    input:
        expand(Path(config['summa_forcing_dir'],"{id}.nc"), id=input_forcing_list)

rule create_hru_id_file:
    input:
        subset_domain_file = Path(config["metsim_dir"], config["metsim_domain_nc"])
    output:
        hru_id_file = temp(Path(config["metsim_dir"], 'hruId.nc'))
    shell:
        'ncks -v hruId {input.subset_domain_file} {output.hru_id_file}'

rule append_hru_id_and_datastep_to_metsim_output:
    input:
        input_metsim_file = Path(config['metsim_output_dir'],"{id}.nc"),
        hru_id_file = Path(config["metsim_dir"], 'hruId.nc')
    output:
        output_metsim_file_temp = temp(Path(config['summa_forcing_dir'],"{id}_temp.nc")),
        output_metsim_file = Path(config['summa_forcing_dir'],"{id}.nc")
    params:
        timestep = int(config["metsim_timestep_minutes"]) * 60
    shell:
        """
        if ! ncdump -h {input.input_metsim_file} | grep -q "hruId"; then
            ncks -h -A {input.hru_id_file} {input.input_metsim_file}
        fi
        ncks -O -C -x -v hru {input.input_metsim_file} {output.output_metsim_file_temp}
        ncrename -O -v .SWradAtm,SWRadAtm {output.output_metsim_file_temp}
        ncrename -O -v .LWradAtm,LWRadAtm {output.output_metsim_file_temp}
        ncap2 -s "data_step={params.timestep}" {output.output_metsim_file_temp} --append {output.output_metsim_file}
        """

        
