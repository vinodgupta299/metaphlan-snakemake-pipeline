# MetaPhlAn4 Snakemake Pipeline

Snakemake workflow for shotgun metagenomics: human-read removal (Bowtie2) →
quality trimming (fastp) → taxonomic profiling (MetaPhlAn4).

## Pipeline steps
1. **remove_human** — align to human reference (Bowtie2), keep unmapped read pairs
2. **fastp** — adapter trimming and quality filtering
3. **metaphlan** — taxonomic profiling with MetaPhlAn4

## Setup
1. Create the conda environment:
   \`\`\`
   conda create -n snakemake_env -c conda-forge -c bioconda snakemake
   pip install snakemake-executor-plugin-slurm
   \`\`\`
2. Edit \`config.yaml\` with your data directory and reference index paths.
3. Add your sample names (one per line, no extension) to \`list.txt\`.

## Run
\`\`\`bash
snakemake -n                # dry run — check the plan first
sbatch run_snakemake.slurm  # submit the controller job
\`\`\`

## Directory structure
\`\`\`
├── Snakefile
├── config.yaml
├── list.txt
├── profile/config.yaml
└── run_snakemake.slurm
\`\`\`
