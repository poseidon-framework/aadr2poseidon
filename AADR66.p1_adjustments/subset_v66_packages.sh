#!/bin/bash

trident forge -d ~/agora/aadr-archive/AADR_v66_2M --forgeFile ~/agora/aadr2poseidon/AADR66.p1_adjustments/remove_jacobs_forgefile.txt --preservePyml --zip -o ~/agora/aadr-archive/AADR_v66_p1_2M
trident rectify -d ~/agora/aadr-archive/AADR_v66_p1_2M --checksumAll

