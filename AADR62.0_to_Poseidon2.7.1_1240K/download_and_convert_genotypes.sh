#!/bin/bash

cd AADR62.0_to_Poseidon2.7.1_1240K
mkdir tmp

# download relevant files
wget https://dataverse.harvard.edu/api/access/datafile/10537413 -O tmp/v62.0_1240k_public.anno
wget https://dataverse.harvard.edu/api/access/datafile/10537414 -O tmp/v62.0_1240k_public.ind
wget https://dataverse.harvard.edu/api/access/datafile/10537415 -O tmp/v62.0_1240k_public.snp
wget https://dataverse.harvard.edu/api/access/datafile/10537126 -O tmp/v62.0_1240k_public.geno

# convert to EIGENSTRAT
cat > tmp/convertf_parfile <<EOF
genotypename: tmp/v62.0_1240k_public.geno
snpname: tmp/v62.0_1240k_public.snp
indivname: tmp/v62.0_1240k_public.ind
outputformat: EIGENSTRAT
genotypeoutname: tmp/AADR_1240K.geno
snpoutname: tmp/AADR_1240K.snp
indivoutname: tmp/AADR_1240K.ind
EOF

convertf -p tmp/convertf_parfile

# convert to binary PLINK
trident genoconvert -p tmp/AADR_1240K.geno --outFormat PLINK
