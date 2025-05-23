#!/bin/bash

# make new dataset that only includes the samples not in the 1240K dataset
trident forge -p tmp/AADR_HO.geno --forgeFile tmp/subsetOnlyHO.pfs --outFormat PLINK --onlyGeno -o tmp -n AADR_HO_without_1240K
