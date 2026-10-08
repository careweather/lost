#!/bin/sh
# Download Hipparcos-1 (I/239/hip_main) from VizieR: HIP, Vmag ≤ 7, RA/Dec in the
# J2000 equatorial frame with proper motion applied to the epoch HIP_EPOCH.
# HIP_EPOCH is a Julian year such as 2025.34; it defaults to today's date.
# Output: hipparcos-catalog.tsv  (ra|dec|HIP|Vmag)
#
# Alternately, follow documentation/downloading-stars.md

set -e

if [ -z "$HIP_EPOCH" ]; then
    HIP_EPOCH=$(date -u '+%Y %j' | awk '{ printf "%.2f", $1 + ($2 - 1) / 365.25 }')
fi
echo "Hipparcos positions at epoch J$HIP_EPOCH" >&2

curl -sS 'https://vizier.cds.unistra.fr/viz-bin/asu-tsv' \
    --data-urlencode '-source=I/239/hip_main' \
    --data-urlencode '-out.max=unlimited' \
    --data-urlencode '-out.form=| -Separated-Values' \
    --data-urlencode "-out.add=_RA(J2000,J$HIP_EPOCH),_DE(J2000,J$HIP_EPOCH)" \
    --data-urlencode '-oc.form=dec' \
    --data-urlencode '-out=HIP' \
    --data-urlencode '-out=Vmag' \
    --data-urlencode 'Vmag=<=7' \
    | grep -E '^[[:space:]]*[0-9]+\.[0-9]+' > hipparcos-catalog.tsv
