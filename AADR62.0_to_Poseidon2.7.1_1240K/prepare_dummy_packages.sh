#!/bin/bash

# make a basic "dummy" package from the transformed AADR dataset
trident init -p tmp/AADR_1240K.geno -o tmp/AADR_1240K

# add the new .janno and .bib file
cp tmp/AADR_1240K.janno tmp/AADR_1240K/AADR_1240K.janno
cp tmp/References.bib tmp/AADR_1240K/AADR_1240K.bib

# confirm that the resulting package is structurally valid
trident validate -d tmp/AADR_1240K --logMode VerboseLog

# split the large package into smaller subsets with the prepared forgeScript files
trident forge -d tmp/AADR_1240K --forgeFile tmp/subsetModern.pfs --outFormat PLINK -o tmp/AADR_v62.0_1240K_Modern
trident forge -d tmp/AADR_1240K --forgeFile tmp/subsetEuropeAncientNorth.pfs --outFormat PLINK -o tmp/AADR_v62.0_1240K_EuropeAncientNorth
trident forge -d tmp/AADR_1240K --forgeFile tmp/subsetEuropeAncientSouth.pfs --outFormat PLINK -o tmp/AADR_v62.0_1240K_EuropeAncientSouth
trident forge -d tmp/AADR_1240K --forgeFile tmp/subsetBeyondEuropeAncient.pfs --outFormat PLINK -o tmp/AADR_v62.0_1240K_BeyondAncient
