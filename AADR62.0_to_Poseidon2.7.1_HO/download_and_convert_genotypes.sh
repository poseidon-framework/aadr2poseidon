#!/bin/bash

cd AADR62.0_to_Poseidon2.7.1_HO

# download archive
wget https://dataverse.harvard.edu/api/access/datafile/10537417 -O tmp/v62.0_HO_public.anno
wget https://dataverse.harvard.edu/api/access/datafile/10537421 -O tmp/v62.0_HO_public.snp
wget https://dataverse.harvard.edu/api/access/datafile/10537420 -O tmp/v62.0_HO_public.ind
wget https://dataverse.harvard.edu/api/access/datafile/10537419 -O tmp/v62.0_HO_public.geno

# convert to EIGENSTRAT
cat > tmp/convertf_parfile <<EOF
genotypename: tmp/v62.0_HO_public.geno
snpname: tmp/v62.0_HO_public.snp
indivname: tmp/v62.0_HO_public.ind
outputformat: EIGENSTRAT
genotypeoutname: tmp/AADR_HO.geno
snpoutname: tmp/AADR_HO.snp
indivoutname: tmp/AADR_HO.ind
EOF

convertf -p tmp/convertf_parfile
