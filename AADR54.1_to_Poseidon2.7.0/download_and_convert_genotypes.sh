#!/bin/bash

#wget https://reichdata.hms.harvard.edu/pub/datasets/amh_repo/curated_releases/V54/V54.1/SHARE/public.dir/v54.1_1240K_public.anno -O tmp/v54.1_1240K_public.anno
#wget https://reichdata.hms.harvard.edu/pub/datasets/amh_repo/curated_releases/V54/V54.1/SHARE/public.dir/v54.1_1240K_public.ind -O tmp/v54.1_1240K_public.ind
wget https://reichdata.hms.harvard.edu/pub/datasets/amh_repo/curated_releases/V54/V54.1/SHARE/public.dir/v54.1_1240K_public.tar -O tmp/v54.1_1240K_public.tar

tar -xvf tmp/v54.1_1240K_public.tar -C tmp

cat > tmp/convertf_parfile <<EOF
genotypename: tmp/v54.1_1240K_public.geno
snpname: tmp/v54.1_1240K_public.snp
indivname: tmp/v54.1_1240K_public.ind
outputformat: EIGENSTRAT
genotypeoutname: tmp/AADR_1240K.geno
snpoutname: tmp/AADR_1240K.snp
indivoutname: tmp/AADR_1240K.ind
EOF

# two-step conversion is necessary, because convertf handles the group name 
# column differently than poseidon in binary plink format
convertf -p tmp/convertf_parfile
trident genoconvert -p tmp/AADR_1240K.geno --outFormat PLINK
