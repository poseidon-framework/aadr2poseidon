#!/bin/bash

mkdir tmp

# download relevant files
# v66.1240K.aadr.PUB
wget https://dataverse.harvard.edu/api/access/datafile/13663706 -O tmp/v66.1240K.aadr.PUB.anno
wget https://dataverse.harvard.edu/api/access/datafile/13663698 -O tmp/v66.1240K.aadr.PUB.ind
wget https://dataverse.harvard.edu/api/access/datafile/13663698 -O tmp/v66.1240K.aadr.PUB.ind
wget https://dataverse.harvard.edu/api/access/datafile/13664080 -O tmp/v66.1240K.aadr.PUB.geno

# convert to EIGENSTRAT
cat > tmp/convertf_parfile_AADR_v66_1240K <<EOF
genotypename: tmp/v66.1240K.aadr.PUB.geno
snpname: tmp/v66.1240K.aadr.PUB.snp
indivname: tmp/v66.1240K.aadr.PUB.ind
outputformat: EIGENSTRAT
genotypeoutname: tmp/AADR_v66_1240K.geno
snpoutname: tmp/AADR_v66_1240K.snp
indivoutname: tmp/AADR_v66_1240K.ind
EOF

convertf -p tmp/convertf_parfile_AADR_v66_1240K

# convert to binary PLINK
#trident genoconvert -p tmp/AADR_1240K.geno --outFormat PLINK

