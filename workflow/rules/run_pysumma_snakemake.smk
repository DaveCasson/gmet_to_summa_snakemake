"""

Snakemake file to run the base SUMMA simulations.

The model simulation is chunked by GRU to allow for parallelization on a cluster.

The chunks of GRUs are defined by the user

"""

from pathlib import Path
import sys
import pysumma as ps
# Import local packages
sys.path.append(str(Path('../').resolve()))

sys.path.append('../')
from scripts import gmet_to_summa_utils as gts_utils
config = gts_utils.resolve_paths(config,log_config = False)

# Resolve all file paths and directories in the config file
config['file_manager'] = '../../test_data/summa/settings/fileManager.txt'
config['summa_output_dir'] = '../../test_data/summa/output/'
config['attributes_nc'] = '../../test_data/summa/settings/attributes.nc'
config['gru_chunk_size'] = 3
config['case_name'] = 'tuolumne'
config['run_suffix'] = 'base'

# UPDATE LOCAL SUMMA PATH
config['summa_exe'] = '/Users/drc858/GitHub/summa/bin/summa.exe'


# Generate GRU start and count
num_grus = gts_utils.calc_num_grus(config['attributes_nc'])
gru_chunk_strings = gts_utils.generate_gru_start_and_count(num_grus, chunk_size=config['gru_chunk_size'])

rule run_summa_base_simulations:
    input:
        expand(Path(config['summa_output_dir'],f"{config['case_name']}_{config['run_suffix']}_{{gru_chunk}}_timestep.nc"),gru_chunk=gru_chunk_strings)

rule run_summa_in_gru_chunks:
    input:
        file_manager = Path(config['file_manager'])
    output:
        summa_chunked_output = Path(config['summa_output_dir'],f"{config['case_name']}_{config['run_suffix']}_{{gru_chunk}}_timestep.nc")
    params:
        summa_exe = config['summa_exe'],
        gru_start = lambda wildcards: gts_utils.extract_gru_int({wildcards.gru_chunk}),
        gru_count = config['gru_chunk_size']
    run:
        sim = ps.Simulation(params.summa_exe,input.file_manager)
        sim.run(run_suffix=config['run_suffix'], startGRU=params.gru_start, countGRU=params.gru_count, write_config=False)


        
