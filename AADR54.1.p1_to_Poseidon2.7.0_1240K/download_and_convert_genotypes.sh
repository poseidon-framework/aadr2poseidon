#!/bin/bash

cd AADR54.1.p1_to_Poseidon2.7.0_1240K

# download archive
wget https://reichdata.hms.harvard.edu/pub/datasets/amh_repo/curated_releases/V54/V54.1.p1/SHARE/public.dir/v54.1.p1_1240K_public.tar -O tmp/v54.1.p1_1240K_public.tar

# unpack
tar -xvf tmp/v54.1.p1_1240K_public.tar -C tmp

# convert to EIGENSTRAT
cat > tmp/convertf_parfile <<EOF
genotypename: tmp/v54.1.p1_1240K_public.geno
snpname: tmp/v54.1.p1_1240K_public.snp
indivname: tmp/v54.1.p1_1240K_public.ind
outputformat: EIGENSTRAT
genotypeoutname: tmp/AADR_1240K.geno
snpoutname: tmp/AADR_1240K.snp
indivoutname: tmp/AADR_1240K.ind
EOF

convertf -p tmp/convertf_parfile

# convert to binary PLINK
trident genoconvert -p tmp/AADR_1240K.geno --outFormat PLINK
