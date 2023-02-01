#!/bin/bash

wget https://reichdata.hms.harvard.edu/pub/datasets/amh_repo/curated_releases/V54/V54.1/SHARE/public.dir/v54.1_1240K_public.tar -O tmp/v54.1_1240K_public.tar

tar -xvf tmp/v54.1_1240K_public.tar -C tmp

cat > tmp/convertf_parfile <<EOF
genotypename: tmp/v54.1_1240K_public.geno
snpname: tmp/v54.1_1240K_public.snp
indivname: tmp/v54.1_1240K_public.ind
outputformat: PACKEDPED
genotypeoutname: tmp/AADR_1240K.bed
snpoutname: tmp/AADR_1240K.bim
indivoutname: tmp/AADR_1240K.fam
EOF

convertf -p tmp/convertf_parfile
