#!/bin/bash

mkdir tmp

#### v66.1240K.aadr.PUB ####

# download
wget https://dataverse.harvard.edu/api/access/datafile/13663706 -O tmp/v66.1240K.aadr.PUB.anno
wget https://dataverse.harvard.edu/api/access/datafile/13664080 -O tmp/v66.1240K.aadr.PUB.geno
wget https://dataverse.harvard.edu/api/access/datafile/13663698 -O tmp/v66.1240K.aadr.PUB.ind
wget https://dataverse.harvard.edu/api/access/datafile/13664260 -O tmp/v66.1240K.aadr.PUB.snp

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
trident genoconvert -p tmp/AADR_v66_1240K.geno --outFormat PLINK --zip

#### v66.2M.aadr.PUB ####

# download
wget https://dataverse.harvard.edu/api/access/datafile/13663704 -O tmp/v66.2M.aadr.PUB.anno
wget https://dataverse.harvard.edu/api/access/datafile/13663727 -O tmp/v66.2M.aadr.PUB.geno
wget https://dataverse.harvard.edu/api/access/datafile/13663699 -O tmp/v66.2M.aadr.PUB.ind
wget https://dataverse.harvard.edu/api/access/datafile/13664261 -O tmp/v66.2M.aadr.PUB.snp

#### v66.2M_compatibility.aadr.PUB ####

# download
wget https://dataverse.harvard.edu/api/access/datafile/13663707 -O tmp/v66.2M_compatibility.aadr.PUB.anno
wget https://dataverse.harvard.edu/api/access/datafile/13663735 -O tmp/v66.2M_compatibility.aadr.PUB.geno
wget https://dataverse.harvard.edu/api/access/datafile/13663701 -O tmp/v66.2M_compatibility.aadr.PUB.ind
wget https://dataverse.harvard.edu/api/access/datafile/13664262 -O tmp/v66.2M_compatibility.aadr.PUB.snp

#### v66.compatibility_HO.aadr.PUB ####

# download
wget https://dataverse.harvard.edu/api/access/datafile/13663710 -O tmp/v66.compatibility_HO.aadr.PUB.anno
wget https://dataverse.harvard.edu/api/access/datafile/13664067 -O tmp/v66.compatibility_HO.aadr.PUB.geno
wget https://dataverse.harvard.edu/api/access/datafile/13663705 -O tmp/v66.compatibility_HO.aadr.PUB.ind
wget https://dataverse.harvard.edu/api/access/datafile/13663709 -O tmp/v66.compatibility_HO.aadr.PUB.snp

#### v66.HO.aadr.PUB.anno ####

# download
wget https://dataverse.harvard.edu/api/access/datafile/13664265 -O tmp/v66.HO.aadr.PUB.anno
wget https://dataverse.harvard.edu/api/access/datafile/13663836 -O tmp/v66.HO.aadr.PUB.geno
wget https://dataverse.harvard.edu/api/access/datafile/13664264 -O tmp/v66.HO.aadr.PUB.ind
wget https://dataverse.harvard.edu/api/access/datafile/13664263 -O tmp/v66.HO.aadr.PUB.snp
