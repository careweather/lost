#!/bin/sh
# Download Hipparcos-1 (I/239/hip_main) from VizieR: J2000 RA/Dec, HIP, Vmag ≤ 7.
# Output: hipparcos-catalog.tsv  (ra|dec|HIP|Vmag)
#
# Alternately, follow documentation/downloading-stars.md

set -e

curl -sS 'https://vizier.cds.unistra.fr/viz-bin/asu-tsv' \
    --data-urlencode '-source=I/239/hip_main' \
    --data-urlencode '-out.max=unlimited' \
    --data-urlencode '-out.form=| -Separated-Values' \
    --data-urlencode '-out.add=_RAJ,_DEJ' \
    --data-urlencode '-oc.form=dec' \
    --data-urlencode '-out=HIP' \
    --data-urlencode '-out=Vmag' \
    --data-urlencode 'Vmag=<=7' \
    | grep -E '^[[:space:]]*[0-9]+\.[0-9]+' > hipparcos-catalog.tsv
