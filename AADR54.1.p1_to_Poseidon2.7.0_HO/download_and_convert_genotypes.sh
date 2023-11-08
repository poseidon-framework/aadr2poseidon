#!/bin/bash

cd AADR54.1.p1_to_Poseidon2.7.0_HO

# download archive
wget https://reichdata.hms.harvard.edu/pub/datasets/amh_repo/curated_releases/V54/V54.1.p1/SHARE/public.dir/v54.1.p1_HO_public.tar -O tmp/v54.1.p1_HO_public.tar

# unpack
tar -xvf tmp/v54.1.p1_HO_public.tar -C tmp

# convert to EIGENSTRAT
cat > tmp/convertf_parfile <<EOF
genotypename: tmp/v54.1.p1_HO_public.geno
snpname: tmp/v54.1.p1_HO_public.snp
indivname: tmp/v54.1.p1_HO_public.ind
outputformat: EIGENSTRAT
genotypeoutname: tmp/AADR_HO.geno
snpoutname: tmp/AADR_HO.snp
indivoutname: tmp/AADR_HO.ind
EOF

convertf -p tmp/convertf_parfile

# convert to binary PLINK
trident genoconvert -p tmp/AADR_HO.geno --outFormat PLINK
