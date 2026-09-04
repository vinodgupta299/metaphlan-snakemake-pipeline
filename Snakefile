configfile: "config.yaml"


# ---------------------------------------------------------
# SAMPLES
# ---------------------------------------------------------

with open("list.txt") as f:
    SAMPLES = [line.strip() for line in f if line.strip()]


DATADIR = config["datadir"]
BT2_INDEX = config["bowtie2_index"]
MPA_INDEX = config["metaphlan_index"]


# ---------------------------------------------------------
# FINAL OUTPUTS
# ---------------------------------------------------------

rule all:
    input:
        expand(
            "results/metaphlan/{sample}_metaphlan4.txt",
            sample=SAMPLES
        )


# =========================================================
# 1. HUMAN READ REMOVAL
# =========================================================

rule remove_human:
    input:
        r1 = DATADIR + "/{sample}_R1_001.fastq.gz",
        r2 = DATADIR + "/{sample}_R2_001.fastq.gz"

    output:
        r1 = temp(
            "results/nonhuman/{sample}_1.fastq.gz"
        ),
        r2 = temp(
            "results/nonhuman/{sample}_2.fastq.gz"
        )

    threads: 8

    resources:
        mem_mb = 24000,
        runtime = 360

    log:
        "logs/human_removal/{sample}.log"

    shell:
        r"""
        module load bowtie2
        module load samtools

        bowtie2 \
            -p 4 \
            -x {BT2_INDEX} \
            -1 {input.r1} \
            -2 {input.r2} \
            2> {log} \
        | samtools view \
            -@ 1 \
            -b \
            -f 12 \
            -F 256 \
            - \
        | samtools sort \
            -n \
            -@ 2 \
            -m 2G \
            - \
        | samtools fastq \
            -@ 1 \
            -1 {output.r1} \
            -2 {output.r2} \
            -0 /dev/null \
            -s /dev/null \
            -n \
            -
        """

# =========================================================
# 2. READ QUALITY CONTROL / TRIMMING
# =========================================================

rule fastp:
    input:
        r1 = "results/nonhuman/{sample}_1.fastq.gz",
        r2 = "results/nonhuman/{sample}_2.fastq.gz"

    output:
        r1p = temp(
            "results/fastp/{sample}_QC_1P.fastq.gz"
        ),
        r2p = temp(
            "results/fastp/{sample}_QC_2P.fastq.gz"
        ),
        r1u = temp(
            "results/fastp/{sample}_QC_1U.fastq.gz"
        ),
        r2u = temp(
            "results/fastp/{sample}_QC_2U.fastq.gz"
        ),
        html = "results/fastp/{sample}_fastp.html",
        json = "results/fastp/{sample}_fastp.json"

    threads: 8

    resources:
        mem_mb = 8000,
        runtime = 120

    log:
        "logs/fastp/{sample}.log"

    shell:
        r"""
        module load fastp

        fastp \
            -i {input.r1} \
            -I {input.r2} \
            -o {output.r1p} \
            -O {output.r2p} \
            --unpaired1 {output.r1u} \
            --unpaired2 {output.r2u} \
            --thread {threads} \
            --detect_adapter_for_pe \
            --cut_front \
            --cut_tail \
            --cut_window_size 4 \
            --cut_mean_quality 20 \
            --trim_front1 3 \
            --trim_front2 3 \
            --trim_tail1 3 \
            --trim_tail2 3 \
            --length_required 60 \
            --html {output.html} \
            --json {output.json} \
            2> {log}
        """


# =========================================================
# 3. METAPHLAN4
# =========================================================

rule metaphlan:
    input:
        r1p = "results/fastp/{sample}_QC_1P.fastq.gz",
        r2p = "results/fastp/{sample}_QC_2P.fastq.gz",
        r1u = "results/fastp/{sample}_QC_1U.fastq.gz",
        r2u = "results/fastp/{sample}_QC_2U.fastq.gz"

    output:
        "results/metaphlan/{sample}_metaphlan4.txt"

    threads: 8

    resources:
        mem_mb = 32000,
        runtime = 480

    log:
        "logs/metaphlan/{sample}.log"

    shell:
        r"""
        module load conda
        source $(conda info --base)/etc/profile.d/conda.sh
        conda activate metaphlan4_old

        metaphlan \
            {input.r1p},{input.r2p},{input.r1u},{input.r2u} \
            --index {MPA_INDEX} \
            --nproc {threads} \
            --input_type fastq \
            -t rel_ab_w_read_stats \
            -o {output} \
            2> {log}
        """

