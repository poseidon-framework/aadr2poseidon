#!/bin/bash

trident forge -d ~/agora/aadr-archive/AADR_v66_HO_compatibility --forgeFile ~/agora/aadr2poseidon/AADR66.p1_adjustments/remove_jacobs_forgefile.txt --preserve --zip -o ~/agora/aadr-archive/AADR_v66_p1_HO_compatibility
trident rectify -d ~/agora/aadr-archive/AADR_v66_p1_HO_compatibility --checksumAll

trident forge -d ~/agora/aadr-archive/AADR_v66_HO --forgeFile ~/agora/aadr2poseidon/AADR66.p1_adjustments/remove_jacobs_forgefile.txt --preserve --zip -o ~/agora/aadr-archive/AADR_v66_p1_HO
trident rectify -d ~/agora/aadr-archive/AADR_v66_p1_HO --checksumAll

trident forge -d ~/agora/aadr-archive/AADR_v66_1240K --forgeFile ~/agora/aadr2poseidon/AADR66.p1_adjustments/remove_jacobs_forgefile.txt --preserve --zip -o ~/agora/aadr-archive/AADR_v66_p1_1240K
trident rectify -d ~/agora/aadr-archive/AADR_v66_p1_1240K --checksumAll

trident forge -d ~/agora/aadr-archive/AADR_v66_2M_compatibility --forgeFile ~/agora/aadr2poseidon/AADR66.p1_adjustments/remove_jacobs_forgefile.txt --preserve --zip -o ~/agora/aadr-archive/AADR_v66_p1_2M_compatibility
trident rectify -d ~/agora/aadr-archive/AADR_v66_p1_2M_compatibility --checksumAll

trident forge -d ~/agora/aadr-archive/AADR_v66_2M --forgeFile ~/agora/aadr2poseidon/AADR66.p1_adjustments/remove_jacobs_forgefile.txt --preserve --zip -o ~/agora/aadr-archive/AADR_v66_p1_2M
trident rectify -d ~/agora/aadr-archive/AADR_v66_p1_2M --checksumAll




