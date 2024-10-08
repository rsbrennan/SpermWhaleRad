#!/bin/bash
#SBATCH --job-name=populations
#SBATCH --mail-user=reid.brennan@noaa.gov
#SBATCH --mail-type=ALL
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -D /home/rbrennan/spermWhaleRad/logout
#SBATCH -c 14
#SBATCH --mem=20G
#SBATCH --partition=standard
#SBATCH --time=8:00:00


module load bio/stacks/2.65

# split the pops, also run fstats.
populations --in-vcf ~/spermWhaleRad/analysis/freebayes/freebayes_filtered_nonrelated.vcf.gz --popmap ~/spermWhaleRad/scripts/populations.txt --fstats --threads 14 --out-path ~/spermWhaleRad/analysis/pop_structure/populations_pops



