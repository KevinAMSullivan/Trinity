Add a master Trinity script for anyone to use and edit

#Enter commit message above when making changes and make it a command (not a paste event)
#Don't commit personal information to master branch (e.g. paths or unrelated comments)

#!/bin/bash
#$ -V
#$ -cwd
#$ -S /bin/bash
#$ -N Trinity.Efusc
#$ -o $JOB_NAME.o$JOB_ID
#$ -e $JOB_NAME.e$JOB_ID
#$ -q raycc
#$ -pe sm 11
#$ -P communitycluster
 
# This script will run Trinity to assemble transcriptome reads using a genome to guide the assembly
# for additional information, refer to http://trinityrnaseq.sourceforge.net/

# migrate to your working directory
/lustre/work/kevsulli/Trinity/Eptesicus/
		
#Now, lets do the next set of files for the Eptesicus fuscus tissues (unnecesario)
# Create a new directory to work in

# make sure you're doing this for yourself and not in one of my locations.  Otherwise, it won't work.
# migrate to your working directory

# No need to create a new softlink to the original genome and perl script.  We already have the file we need in Dr Ray's work directory and my liver directory.
ln -s /lustre/work/daray/GENOMES/bat.whole.genomes/Efus.scaffolds.sn.fas
ln -s /lustre/work/kevsulli/Trinity/sort_fastq_reads.pl
# We're going to copy the files we want to use from a separate Eptesicus directory
#Only the first 3 would get gunzipped, so I'll add the other line in later
cp /lustre/work/kevsulli/Eptesicus_transcriptome/Sample_EL1364_Efusc_mRNA/EL1364_ATCACG_L006_R1_001.fastq .
cp /lustre/work/kevsulli/Eptesicus_transcriptome/Sample_EL1364_Efusc_mRNA/EL1364_ATCACG_L006_R2_001.fastq .

# fastx_clipper will clip adapter sequences from reads; 
# always put -Q33; don't forget to name an output file (-o) to save new file to folder
fastx_clipper -Q33 -l 0 \
	-a AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
	-n -i EL1364_ATCACG_LOO6_R1_001.fastq \
	-o EL1364_R1clipped.fastq
fastx_clipper -Q33 -l 0 \
        -a AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
        -n -i EL1364_ATCACG_L006_R2_001.fastq \
        -o EL1364_R2clipped.fastq
#next step is to trim the data; use command below
fastq_quality_trimmer -Q33 \
	-t 15 -l 0 \
	-i EL1364_R1clipped.fastq \
	-o EL1364_R1cliptrim.fastq
fastq_quality_trimmer -Q33 \
        -t 15 -l 0 \
        -i EL1364_R2clipped.fastq \
        -o EL1364_R2cliptrim.fastq 
#sort and take out orphans 
perl sort_fastq_reads.pl \
	EL1364_R1cliptrim.fastq \
	EL1364_R2cliptrim.fastq \
	EL1364_R1_sorted.fq \
	EL1364_R2_sorted.fq \
	EL1364_RX_orphan.fq
# check line count to make sure files are the same size
wc -l EL1364_R1_sorted.fq >EL1364_R1_linecount.txt
wc -l EL1364_R2_sorted.fq >EL1364_R2_linecount.txt
# Run Trinity using the current genome assembly as a guide 
perl /lustre/work/apps/trinityrnaseq_r20140717/Trinity \
	--genome Efus.scaffolds.sn.fas \
	--genome_guided_max_intron 10000 \
	--genome_guided_sort_buffer 10G \
	--genome_guided_CPU 4 \
	--GMAP_CPU 10 \
	--seqType fq \
	--JM 2G \
	--left EL1364_R1_sorted.fq \
	--right EL1364_R2_sorted.fq \
	--CPU 10
# Obtain basic stats for the number of genes and isoforms and contiguity of the assembly by running
/lustre/work/apps/trinityrnaseq_r20140717/util/TrinityStats.pl \
	trinity_out_dir/Trinity-GG.fasta \
	>trinity_out_dir/Trinity-GG_transcript_count.txt
# run an unquided assembly
perl /lustre/work/apps/trinityrnaseq_r20140717/Trinity \
	--seqType fq \
	--JM 50G \
	--left EL1364_R1_sorted.fq \
	--right EL1364_R2_sorted.fq \
	--CPU 6
# Obtain basic stats
/lustre/work/apps/trinityrnaseq_r20140717/util/TrinityStats.pl \
        trinity_out_dir/Trinity.fasta \
        >trinity_out_dir/Trinity_transcript_count.txt
		
		
