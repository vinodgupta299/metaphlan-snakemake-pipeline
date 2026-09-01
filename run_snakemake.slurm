#!/bin/bash

#SBATCH --job-name=snakemake_controller
#SBATCH --partition=sm-n2-8g
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=24:00:00
#SBATCH --output=snakemake_controller.%j.out
#SBATCH --error=snakemake_controller.%j.err
#SBATCH --mail-user=xx@xx.xx
#SBATCH --mail-type=END,FAIL

module load conda

source $(conda info --base)/etc/profile.d/conda.sh

conda activate snakemake_env

cd /path_to_snakemake_project/my_project

snakemake \
    --profile profile
