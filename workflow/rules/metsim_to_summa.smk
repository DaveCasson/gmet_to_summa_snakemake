from pathlib import Path

def list_files_in_subdirectory(directory, suffix_to_remove):
    path = Path(directory)
    file_paths = [file.relative_to(path).as_posix().replace(suffix_to_remove, "") for file in path.glob('**/*') if file.is_file()]
    return file_paths

input_file_suffix = '.nc'
input_forcing_list = list_files_in_subdirectory(config['metsim']['metsim_output_dir'], input_file_suffix)

rule metsim_to_summa:
    input:
        expand(Path(config['summa']['summa_forcing_dir'],"{id}.nc"), id=input_forcing_list)

rule create_hru_id_file:
    input:
        subset_domain_file = Path(config["metsim"]["metsim_dir"], config["metsim"]["domain_nc"])
    output:
        hru_id_file = temp(Path(config["metsim"]["metsim_dir"], 'hruId.nc'))
    shell:
        'ncks -v hruId {input.subset_domain_file} {output.hru_id_file}'

rule append_hru_id_and_datastep_to_metsim_output:
    input:
        input_metsim_file = Path(config['metsim']['metsim_output_dir'],"{id}.nc"),
        hru_id_file = Path(config["metsim"]["metsim_dir"], 'hruId.nc')
    output:
        output_metsim_file_temp = temp(Path(config['summa']['summa_forcing_dir'],"{id}_temp.nc")),
        output_metsim_file = Path(config['summa']['summa_forcing_dir'],"{id}.nc")
    params:
        timestep = int(config["metsim"]["timestep_minutes"]) * 60
    shell:
        """
        ncks -h -A {input.hru_id_file} {input.input_metsim_file}
        ncks -O -C -x -v hru {input.input_metsim_file} {output.output_metsim_file_temp}
        ncap2 -s "data_step={params.timestep}" {output.output_metsim_file_temp} --append {output.output_metsim_file}
        """
