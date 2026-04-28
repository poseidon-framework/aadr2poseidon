#!/bin/bash

mkdir tmp

# download relevant files
# v66.1240K.aadr.PUB
wget https://dataverse.harvard.edu/api/access/datafile/13663706 -O tmp/v66.1240K.aadr.PUB.anno




# convert to EIGENSTRAT
#cat > tmp/convertf_parfile <<EOF
#genotypename: tmp/v62.0_1240k_public.geno
#snpname: tmp/v62.0_1240k_public.snp
#indivname: tmp/v62.0_1240k_public.ind
#outputformat: EIGENSTRAT
#genotypeoutname: tmp/AADR_1240K.geno
#snpoutname: tmp/AADR_1240K.snp
#indivoutname: tmp/AADR_1240K.ind
#EOF

#convertf -p tmp/convertf_parfile

# convert to binary PLINK
#trident genoconvert -p tmp/AADR_1240K.geno --outFormat PLINK
