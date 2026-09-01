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


