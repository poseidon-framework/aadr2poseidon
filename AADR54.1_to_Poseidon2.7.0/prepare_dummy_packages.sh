trident init -p tmp/AADR_1240K.geno -o tmp/AADR_1240K

cp tmp/AADR_1240K.janno tmp/AADR_1240K/AADR_1240K.janno
cp tmp/References.bib tmp/AADR_1240K/AADR_1240K.bib

trident validate -d tmp/AADR_1240K --logMode VerboseLog

trident forge -d tmp/AADR_1240K --forgeFile tmp/subsetModern.pfs --outFormat PLINK -o tmp/AADR_v54.1.p1_1240K_Modern
trident forge -d tmp/AADR_1240K --forgeFile tmp/subsetEuropeAncient.pfs --outFormat PLINK -o tmp/AADR_v54.1.p1_1240K_EuropeAncient
trident forge -d tmp/AADR_1240K --forgeFile tmp/subsetBeyondEuropeAncient.pfs --outFormat PLINK -o tmp/AADR_v54.1.p1_1240K_BeyondAncient
