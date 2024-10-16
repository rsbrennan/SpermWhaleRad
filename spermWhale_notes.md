RadSeq with reference genome notes

color pallette:

#eac435: Atlantic
#345995: Dry Tortuga
#03cea4: NGOMex
#fb4d3d: WGOMex

reference genome: https://www.ncbi.nlm.nih.gov/assembly/GCF_002837175.3

map of locations: `map.R`


## fastqc

```bash

cd /mnt/c/Users/Reid.Brennan/Documents/projects/radSeq/raw_data

nextflow run scripts/fastqc.nf --input_dir ./raw_data/ --outdir ./fastqc_pre_trim -with-tower -resume

```
nextflow run scripts/fastqc.nf --input_dir ./raw_data_original/ --outdir ./fastqc_original_data -resume

adapter contamination. quality looks good otherwise.
Nextera transposase

## rename files

```bash

cd /mnt/c/Users/Reid.Brennan/Documents/projects/radSeq/raw_data/

../scripts/rename.sh ../scripts/SNP052_sperm_whale_plateB_75_indexes_HS100_437.txt

ls *fq.gz | cut -f 1 -d "." > file_ids.txt

```

make sure rename was ok:

```r
ids <- read.table("file_ids.txt", header=F)
rnm <- read.table("/mnt/c/Users/Reid.Brennan/Documents/projects/radSeq/scripts/SNP052_sperm_whale_plateB_75_indexes_HS100_437.txt")

sum(!rnm$V2 %in% ids$V1)

rnm[!rnm$V2 %in% ids$V1,]

```

GTTGTGG-AAGGAGT	Pmac048b this file does not exist.


## trim

```bash
sudo service docker start

cd /mnt/c/Users/Reid.Brennan/Documents/projects/radSeq/
nextflow run scripts/fastp.nf --fastq "raw_data/*.R1.fq.gz" -with-tower -resume


cd /mnt/c/Users/Reid.Brennan/Documents/projects/radSeq/

nextflow run scripts/fastqc.nf --input_dir ./analysis/trimmed_files --outdir ./analysis/fastqc_post_trim -with-tower -resume

```

## align

need to activate mamba, from the docs. then. then can load nextflow.

mamba env list

```bash
conda activate nextflow-24.04.4 
nextflow run ../scripts/bwa.nf -c ../scripts/nextflow.config -with-tower -profile bwamem2
```

### calculate alignment stats

```bash
conda activate nextflow-24.04.4 
nextflow run ../scripts/bam_stats.nf -c ../scripts/nextflow.config -with-tower -profile bamstats
```

outputs: `count.aligned.txt`

![](figures/mapping_rates.png)


## call variants

freebayes:

use 1.3.6 : https://github.com/freebayes/freebayes/issues/794

`freebayes_parallel.sh`

649,881 snps on 2878 scaffolds

## filter snps

https://www.ddocent.com/filtering/

`filter.1.sh`: split the multi alleles. normalize them so that different representations of the same indel or complex variant were not counted separately (these variants can otherwise be presented correctly in multiple ways)


- 620,732 snps 
- after basic filtering, 126,084 snps
- After minDP 3 filter and 0.6 missing data: 36,191
- Pmac075 has abnormally high missing data- drop it from the dataset. This was the truncated fastq file too.
- After MAF, mean depth, and max missing: 4971
- Allelic balance: removes nothing.
- remove sites > 3x mean - above 53.4

HDplot to identify paralogs.
 (i) the proportion of heterozygous individuals within a population and (ii) allelic ratios within heterozygous individuals. 
 Prop of hets should be higher for paralogs.

 McKinney, Garrett J., et al. "Paralogs are revealed by proportion of heterozygotes and deviations in read ratios in genotyping‐by‐sequencing data from natural populations.” Molecular Ecology Resources 17.4 (2017): 656-669.

`~/spermWhaleRad/analysis/freebayes/filtered.final.vcf.gz`: 4441 snps

r scripts in `filter.R` which requires `HDplot.R`


# basic population structure

## PCA

`plink_pca.sh`

`pca_relatedness.R`

## relatedness and clones

`ngsrelate.sh`

~/spermWhaleRad/analysis/relatedness/relatedness.res

use KING and coefficient of coancestry Θ

co-ancestry of 0.5 for clones: https://academic.oup.com/genetics/article/206/1/105/6064207

https://onlinelibrary.wiley.com/doi/full/10.1111/mec.17300
We used ngsRelate v2 (Hanghøj et al., 2019) on called genotypes to examine two statistics of relatedness: the coefficient of coancestry Θ and the KING robust relatedness statistic (Waples et al., 2019). The latter should be more robust to the effects of population structure, while the first one should be more robust to inbreeding. We also estimated the fraternity coefficient to identify putative siblings (Ackerman et al., 2017).

Analysis: `relatedness.R`

### drop related individuals:

`filter_related.sh`

creates: `~/spermWhaleRad/analysis/relatedness/freebayes_filtered_unrelated.vcf.gz` and `~/spermWhaleRad/analysis/freebayes/freebayes_ldthin_unrelated.vcf.gz`

## re-run PCA with unrelated individuals

`plink_pca_unrelated.sh`

`pca_unrelated.R`


## admixture

`admixture.sh`

# DAPC

https://onlinelibrary.wiley.com/doi/full/10.1111/1755-0998.13706

  I show that the number of leading PC axes used as predictors of among-population differences, paxes, should not exceed the k−1 biologically informative PC axes that are expected for k effective populations in a genotype data set. 

   I show that the appropriate number of PC axes for DA is a deterministic property of a genotype data set: the leading k−1 PC axes for k effective populations. I propose a k−1 criterion for choosing a value of paxes and argue that this criterion is more appropriate for DAPC parameterization than the commonly used proportional variance criterion, where paxes is instead chosen to capture some proportion of the total genotypic variance.

 an estimate of the likely k is required for choosing an appropriate paxes.
 Nonetheless, the expectations of a k−1 limit on the number of biologically informative PC axes will still hold, and a researcher should do their best to make an appropriate judgement. A small discrepancy between k and kinfer is unlikely to cause notable problems in the DA model fit, the point being that paxes ≫ k−1 is more problematic and should be avoided.
  
  When population structure exists, there is typically an inflection point at the kth PC axis that creates an “elbow-shaped” pattern in the explained variances
   By contrast, in the M = 0.400 scenario, although there were five sampled populations, there is no variation among them (k = 1, FST = 0.0009), and the scree slope exhibits a smooth decline.
    - i.e., the smooth decline we see indicates no structure.

  Values of kinfer obtained using K-means may vary across different parameterizations. K-means-derived estimates of kinfer should be compared to expectations derived from PC screeplots and scatterplots to assess consistency across approaches.

  These data demonstrate that when genetic differentiation is large, the DA model is less likely to be influenced by the inclusion of many biologically uninformative PC axes. In contrast, when genetic differentiation is weak, inclusion of many biologically uninformative PC axes >k−1 is more likely to influence the DA model. Furthermore, because DA is mechanistically a hypothesis-driven method, a solution will be derived whether it is biologically meaningful or not.

  For all migration scenarios, increasing paxes increases the separation of populations in LD space when kDA = 5 groups; note the increasing scale of the LD axes and tighter clustering as paxes increases. However, with respect to the general patterns inferred from the LD space projection, the effect of increasing paxes ≫ k−1 is more dramatic when genetic differentiation is weak.

  This perceived separation is not being driven by the inclusion of biologically relevant predictors of among-population differences, but instead an over-fitting of the DA model to idiosyncrasies of the sample.

Two approaches that can be used to assess the fit of a DA model are leave-one-out cross-validation (for small sample sizes) and training–testing partitioning (for large sample sizes)
- basically build dapc with ~70% of samples, then see how others fit.

To determine paxes, the researcher would then need to estimate the number of effective populations, kinfer, to identify the number of leading PC axes that are biologically informative, using paxes = kinfer−1 PC axes as predictors. The value of kinfer may be the same as the researcher's expectations (kprior = kinfer), or it may differ from their expectations (kprior > kinfer, or kprior < kinfer). Regardless, because estimation of kinfer does not inform the choice of kDA, there is no issue with circularity and the researcher is performing a true hypothesis test when fitting their DA model.

see `dapc.R` and resulting files.


# Genetic diversity

### pi

need to get invariant sites in the vcf.

`freebayes_allSites.sh` -> `freebayes_allsites.vcf.gz`

need to filter- use the same basic filters as with the variant dataset.

`filter.allsites.1.sh`- then combining with good snp set.

`pixy.sh`

### het

```bash

bio/stacks/2.65

# split the pops, also run fstats.
populations --in_vcf ~/spermWhaleRad/analysis/freebayes/freebayes_filtered_nonrelated.vcf.gz --popmap populations.txt --fstats --t 14 --out_path ~/spermWhaleRad/analysis/pop_structure

# populations as one.
populations --in_vcf ~/spermWhaleRad/analysis/relatedness/freebayes_filtered_nonrelated.vcf.gz --t 14 --out_path ~/spermWhaleRad/analysis/pop_structure/


```

Both heterozygosity and pi analysis is in: `diversity.R`




### LD

Linkage Disequilibrium
In order to choose a threshold value for thinning in the pruning step, linkage disequilibrium decay was plotted for the 30 longest scaffolds on the quality-filtered dataset. For this, the squared correlation coefficients between genotypes of sites separated by a maximum of 50,000 bp were calculated with VCFtools (–geno-r2 –ld-window-bp 50000). Nucleotide position and R2 values for a random subset of a million sites in each scaffold were then plotted with a custom R script (Oosting, 2021). The analysis was run twice, once on the 188 individuals, and once without including king tarakihi specimens.


# effective population size

### currentNe

use only the major chromosomes, so I know the actual distance between snps.
currentNe ~/spermWhaleRad/analysis/freebayes/freebayes_unrelated_chr.vcf

~/spermWhaleRad/analysis/Ne/freebayes_all_chr.vcf.gz
zcat ~/spermWhaleRad/analysis/Ne/freebayes_all_chr.vcf.gz > ~/spermWhaleRad/analysis/Ne/freebayes_all_chr.vcf

subset the vcf to each of the 4 pops:

check this file: `variants_all_chr_NeFormat.ped` bc different results in current Ne than vcf despite same number of snps, etc.

```bash

module load bio/plink/1.90b6.23 

cd ~/spermWhaleRad/analysis/Ne

# where is the code for pulling out the major chromsoeomes?


# need to add snp ids:

filtered.final_ids.vcf.gz

module load bio/bcftools/1.11
module load lib64/htslib/1.11

tabix ~/spermWhaleRad/analysis/Ne/freebayes_all_chr.vcf 
bcftools annotate ~/spermWhaleRad/analysis/Ne/freebayes_all_chr.vcf.gz -x ID -I +'%CHROM:%POS' > ~/spermWhaleRad/analysis/Ne/freebayes_all_chr_ids.vcf 

plink --vcf freebayes_all_chr_ids.vcf \
--recode --out variants_all_chr \
--allow-extra-chr --double-id --a2-allele freebayes_all_chr_ids.vcf 4 3 '#' --real-ref-alleles 

## test files:

cat freebayes_all_chr_ids.vcf | head -n 600 > test.vcf

~/plink2 --vcf test.vcf --export ped --out plink2_conversion

plink --vcf test.vcf --allow-extra-chr --recode --out plink1_conversion
head -n1 plink1_conversion.ped | grep -o " " | wc -l
head -n1 | grep -o "\t" | wc -l
awk '{print NF; exit}' plink2_conversion.ped 

# run currentNe
 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe plink1_conversion.ped 4 -o plink1_conversion
 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe plink2_conversion.ped 4 -o plink2_conversion
 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe test.vcf 4 -o vcf_input

## plink

## plink2


~/plink2 --vcf ~/spermWhaleRad/analysis/Ne/freebayes_all_chr_ids.vcf --export ped

module load bio/vcftools/0.1.16

cp freebayes_all_chr.vcf freebayes_all_chr_mod.vcf

sed -i 's/NC_041214.2/1/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041215.1/2/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041216.1/3/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041217.1/4/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041218.1/5/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041219.1/6/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041220.1/7/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041221.1/8/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041222.1/9/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041223.1/10/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041224.1/11/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041225.1/12/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041226.1/13/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041227.1/14/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041228.1/15/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041229.1/16/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041230.1/17/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041231.1/18/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041232.1/19/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041233.1/20/g' freebayes_all_chr_mod.vcf
sed -i 's/NC_041234.1/21/g' freebayes_all_chr_mod.vcf

vcftools --vcf ~/spermWhaleRad/analysis/Ne/freebayes_all_chr_mod.vcf --out my_data --plink

plink --vcf ~/spermWhaleRad/analysis/Ne/freebayes_all_chr_mod.vcf  \
--recode --out variants_all_chr_mod_plink1 \
--allow-extra-chr --double-id

~/plink2 --vcf freebayes_all_chr_mod.vcf --export ped --out variants_all_chr_mod_plink2

 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe freebayes_all_chr_mod.vcf 21 -o vcf.out
 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe my_data.ped 21 -o vcftools_ped.out
 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe variants_all_chr_mod_plink1.ped 21 -o plink1_ped.out
 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe variants_all_chr_mod_plink2.ped 21 -o plink2_ped.out












awk '$6=-9' variants_all_chr_NeFormat-old.ped > variants_all_chr_NeFormat-old2.ped 

sed 's/\t/ /g' my_data.ped > my_data2.ped
sed 's/\t/ /g' my_data.map > my_data2.map
~/spermWhaleRad/analysis/Ne/currentNe/currentNe ~/spermWhaleRad/analysis/Ne/freebayes_all_chr.vcf 21 -o allindivs

 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe my_data2.ped 21 -o my_data_ped
 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe my_data2.ped 21 -o my_data_ped
 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe plink2.ped 21 -o oldplink
 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe variants_all_chr_NeFormat-old2.ped 21 -o old2
 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe variants_all_chr_NeFormat.ped 21 -k 0.05 -o allindivs_withK
 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe variants_all_chr_NeFormat.ped 21 -k -0.05 -o allindivs_withK
 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe variants_all_chr_NeFormat.ped 21 -k -0.1 -o allindivs_withK
 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe variants_all_chr_NeFormat.ped 21 -k -0.11 -o allindivs_withK
 ~/spermWhaleRad/analysis/Ne/currentNe/currentNe variants_all_chr_NeFormat.ped 21 -k -0.11 -o allindivs_withK

```


no siblings specified:


specify the average number of full siblings in the sample: -k -0.12

~/spermWhaleRad/analysis/Ne/currentNe/currentNe

### NeEstimator:

waples says do no remove relatives. this will increase the estimate upwards. See preprint of his, "Idiot's guide..."

#### subset to only chr of interest and LD thin

```bash
module load bio/vcftools/0.1.16
module load bio/plink/1.90b6.23

cd ~/spermWhaleRad/analysis/freebayes

zcat freebayes_unrelated_chr.vcf.gz > freebayes_unrelated_chr_mod.vcf

sed -i 's/NC_041214.2/1/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041215.1/2/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041216.1/3/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041217.1/4/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041218.1/5/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041219.1/6/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041220.1/7/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041221.1/8/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041222.1/9/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041223.1/10/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041224.1/11/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041225.1/12/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041226.1/13/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041227.1/14/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041228.1/15/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041229.1/16/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041230.1/17/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041231.1/18/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041232.1/19/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041233.1/20/g' freebayes_unrelated_chr_mod.vcf
sed -i 's/NC_041234.1/21/g' freebayes_unrelated_chr_mod.vcf

module load bio/bcftools/1.11
module load bio/htslib/1.19

cp ~/spermWhaleRad/analysis/Ne/freebayes_all_chr_mod.vcf ~/spermWhaleRad/analysis/freebayes

bgzip freebayes_unrelated_chr_mod.vcf > freebayes_unrelated_chr_mod.vcf.gz
bgzip freebayes_all_chr_mod.vcf > freebayes_all_chr_mod.vcf.gz

tabix freebayes_unrelated_chr_mod.vcf.gz
tabix freebayes_all_chr_mod.vcf.gz

bcftools annotate freebayes_unrelated_chr_mod.vcf.gz -x ID -I +'%CHROM:%POS' > freebayes_unrelated_chr_mod_ids.vcf
bcftools annotate freebayes_all_chr_mod.vcf.gz -x ID -I +'%CHROM:%POS' > freebayes_all_chr_mod_ids.vcf

plink --vcf freebayes_unrelated_chr_mod_ids.vcf \
--indep-pairwise 50 5 0.2 --allow-extra-chr --double-id \
--out variants_pruned_chr
plink --vcf freebayes_all_chr_mod_ids.vcf \
--indep-pairwise 50 5 0.2 --allow-extra-chr --double-id \
--out variants_pruned_chr_all

vcftools --vcf freebayes_unrelated_chr_mod_ids.vcf  --snps variants_pruned_chr.prune.in --recode --recode-INFO-all --stdout |  bgzip >  freebayes_unrelated_chr_mod_ids_ldthin.vcf.gz
vcftools --vcf freebayes_all_chr_mod_ids.vcf  --snps variants_pruned_chr_all.prune.in --recode --recode-INFO-all --stdout >  freebayes_all_chr_mod_ids_ldthin.vcf.gz

zcat freebayes_all_chr_mod_ids_ldthin.vcf.gz | grep -v "^#" | wc -l

```

subset the vcf to each of the 4 pops:
thin for physical LD

```r

library(dartR.popgen)
# Correct estimates based on the number of chromosomes
nes <- gl.LDNe(pops,   outfile = "popsLD.txt",  neest.path = path.binaries,
  critical = c(0, 0.05), singleton.rm = TRUE, mating = "random",
  Waples.correction='nChromosomes', Waples.correction.value=22) 

```




### GONE:

format map file: !!!!!!!! I THINK THIS IS CAUSING PROBLEMS!!!!!!!!
`python /mnt/c/Users/Reid.Brennan/Documents/projects/spermWhaleRad/git_repo/SpermWhaleRad/scripts/GONE_map_format.py`

all found here: ~/spermWhaleRad/analysis/Ne

```bash



#subset to only indivs within a pop:
vcftools --vcf freebayes_all_chr.vcf.gz --remove ~/spermWhaleRad/analysis/relatedness/relatedindivs.txt  --recode --recode-INFO-all --stdout  > LDthin_numCorrect_nonrelated.vcf

plink --vcf freebayes_all_chr.vcf.gz \
--make-bed --out variants_all_chr \
--allow-extra-chr --double-id

```

freebayes_all_chr.vcf.gz
variants_all_chr_NeFormat.ped

need to drop chr names, etc to work with GONE.
GONE_map_format.py
variants_all_chr_NeFormat.map

INPUT_PARAMETERS_FILE


# Fst

using snpR is in `diversity.R`

But also run with vcftools, just to make sure nothing wacky going on/ they are consistent.

```bash

module load bio/vcftools/0.1.16
vcftools --gzvcf ../freebayes/filtered.final.vcf.gz --weir-fst-pop ~/spermWhaleRad/scripts/Atlantic.pop --weir-fst-pop ~/spermWhaleRad/scripts/tortuga.pop

vcftools --gzvcf ../freebayes/filtered.final.vcf.gz --weir-fst-pop ~/spermWhaleRad/scripts/Atlantic.pop --weir-fst-pop ~/spermWhaleRad/scripts/NGOMex.pop      

```

# problems

this file is truncated. Pmac075
Failed to process file 437_GTTGAAC-TATCCTC_S228_L004_R1_001.fastq.gz
it was modified on may 18, 2016, everything else on april 25, 2016

Pmac075 also has abnormally high missing data- drop it from the dataset. 

GTTGTGG-AAGGAGT	Pmac048b this file does not exist.
