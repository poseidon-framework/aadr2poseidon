# [V66.p1](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/FFIDCW): Data release: Jun 8 2026

The AADR v66 included data that was not supposed to be public. As stated in the official changelog:

> We have decommissioned the previously available versions of the v62.0 and v66.0 AADR datasets, and posted new ones v62.0.p1 and v66.p1 that are exactly the same except that we  removed data from 161 modern individuals reported in Jacobs G et al. (2019) Multiple Deeply Divergent Denisovan Ancestries in Papuans. Cell, 177, 1010-1021 (https://doi.org/10.1016/j.cell.2019.02.035).

> The reason for removal from AADR is that we accidentally released data from these individuals that should only be accessible through a Data Access Committee hosted at the official data repository: the European Genome-Phenome Archive (https://www.ebi.ac.uk/ega/home) accession EGAS00001003054.  We deeply apologize to the stakeholders of this study for this accidental data release. We request that researchers do not use the data available through decommissioned versions of AADR, and that analyses of genetic data from these 161 individuals must follow the formal data access procedure through EGA.

Here we document the steps undertaken to remove this data from the v66 Poseidon packages.

1. Identify the samples that should be removed from the AADR v66.0 packages with `identify_jacobs_samples.R`. This generates the forge file `remove_jacobs_forgefile.txt`.
2. 