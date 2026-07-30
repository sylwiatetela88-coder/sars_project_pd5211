rule all:
    input:
        "results/variants.vcf",
        "results/aligned_sorted.bam",
        "results/aligned.sam",
        "data/raw/SRR19301844.fastq",
        "reference/NC_045512.2.fasta",
        "results/SRR19301844_fastqc.html"

rule map:
    input:
        fastq="data/raw/SRR19301844.fastq",
        ref="reference/NC_045512.2.fasta"
    output:
        "results/aligned.sam"
    shell:
        "bwa mem {input.ref} {input.fastq} > {output}"

rule bam:
    input:
        "results/aligned.sam"
    output:
        "results/aligned_sorted.bam"
    shell:
        """
        samtools view -S -b {input} > temp.bam
        samtools sort temp.bam -o {output}
        """

rule fastqc:
    input:
        "data/raw/SRR19301844.fastq"
    output:
        # Zamiast zwykłego ciągu znaków:
        report("results/SRR19301844_fastqc.html", category="Kontrola Jakości")
    shell:
        "fastqc {input} -o results/"

rule variants:
    input:
        bam="results/aligned_sorted.bam",
        ref="reference/NC_045512.2.fasta"
    output:
        # Dzięki temu Snakemake ładnie wyrenderuje lub osadzi plik VCF w raporcie
        report("results/variants.vcf", category="Warianty")
    shell:
        "bcftools mpileup -f {input.ref} {input.bam} | bcftools call -mv -o {output}"

