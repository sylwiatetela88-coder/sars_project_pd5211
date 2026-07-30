nextflow.enable.dsl = 2

params.sample_id = "SRR19301844"
params.reads = "${projectDir}/data/raw/${params.sample_id}.fastq"
params.reference = "${projectDir}/reference/NC_045512.2.fasta"
params.outdir = "${projectDir}/results_nextflow"

process FASTQC {
    tag "${sample_id}"
    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    path "*.html"
    path "*.zip"

    script:
    """
    fastqc ${reads}
    """
}

process BWA_INDEX {
    tag "Indexing Reference"

    input:
    path reference

    output:
    path reference
    path "${reference}.*"

    script:
    """
    bwa index ${reference}
    """
}

process ALIGN_AND_SORT {
    tag "${sample_id}"
    publishDir "${params.outdir}/alignment", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)
    path reference
    path index_files

    output:
    tuple val(sample_id), path("${sample_id}_sorted.bam"), path("${sample_id}_sorted.bam.bai")

    script:
    """
    bwa mem ${reference} ${reads} | samtools view -S -b - | samtools sort -o ${sample_id}_sorted.bam -
    samtools index ${sample_id}_sorted.bam
    """
}

process VARIANT_CALLING {
    tag "${sample_id}"
    publishDir "${params.outdir}/variants", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path reference

    output:
    path "${sample_id}_variants.vcf"

    script:
    """
    bcftools mpileup -f ${reference} ${bam} | bcftools call -mv -o ${sample_id}_variants.vcf
    """
}

workflow {
    ch_reads = Channel.of([params.sample_id, file(params.reads, checkIfExists: true)])
    ch_reference = file(params.reference, checkIfExists: true)

    FASTQC(ch_reads)
    BWA_INDEX(ch_reference)
    ALIGN_AND_SORT(ch_reads, BWA_INDEX.out[0], BWA_INDEX.out[1])
    VARIANT_CALLING(ALIGN_AND_SORT.out, ch_reference)
}

