#!/bin/bash

# Centroid-file pipeline input: error cases and a generate-centroids-only round-trip.

set -x

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

echo 'Mutually exclusive with --png and --generate'
./lost pipeline --centroids "$tmp_dir/stars.xy" --png /dev/null 2>&1 | grep ERROR || exit 1
./lost pipeline --centroids "$tmp_dir/stars.xy" --generate 1 2>&1 | grep ERROR || exit 1

echo 'Missing sensor resolution'
printf '10 10\n' > "$tmp_dir/one.xy"
./lost pipeline --centroids "$tmp_dir/one.xy" --fov 20 2>&1 | grep ERROR || exit 1
./lost pipeline --centroids "$tmp_dir/one.xy" --x-resolution 1024 2>&1 | grep ERROR || exit 1

echo '--centroid-algo is illegal with --centroids'
./lost pipeline --centroids "$tmp_dir/one.xy" --x-resolution 1024 --y-resolution 1024 --centroid-algo cog 2>&1 | grep ERROR || exit 1

echo '--x-resolution is only valid with --centroids'
./lost pipeline --generate 1 --x-resolution 1024 2>&1 | grep ERROR || exit 1

echo 'Empty file'
: > "$tmp_dir/empty.xy"
./lost pipeline --centroids "$tmp_dir/empty.xy" --x-resolution 1024 --y-resolution 1024 --fov 20 2>&1 | grep ERROR || exit 1

echo 'Comment-only file is empty'
printf '# just a comment\n\n' > "$tmp_dir/comments.xy"
./lost pipeline --centroids "$tmp_dir/comments.xy" --x-resolution 1024 --y-resolution 1024 --fov 20 2>&1 | grep ERROR || exit 1

echo 'Centroid outside the sensor'
printf '2000 10\n' > "$tmp_dir/outside.xy"
./lost pipeline --centroids "$tmp_dir/outside.xy" --x-resolution 1024 --y-resolution 1024 --fov 20 2>&1 | grep ERROR || exit 1

echo 'Missing y coordinate'
printf '12\n' > "$tmp_dir/bad-line.xy"
./lost pipeline --centroids "$tmp_dir/bad-line.xy" --x-resolution 1024 --y-resolution 1024 --fov 20 2>&1 | grep ERROR || exit 1

echo 'Plot-output needs an image'
printf '10 10\n20 20\n30 30\n40 40\n' > "$tmp_dir/four.xy"
./lost pipeline --centroids "$tmp_dir/four.xy" --x-resolution 1024 --y-resolution 1024 --fov 20 --plot-output /dev/null 2>&1 | grep -Fe '--plot-output' || exit 1

echo 'Build a k-vector database for the round-trip'
./lost database \
  --max-stars 5000 \
  --kvector \
  --kvector-min-distance 0.2 \
  --kvector-max-distance 15 \
  --kvector-distance-bins 10000 \
  --output "$tmp_dir/db.dat" || exit 1

echo 'Dump generated centroids'
./lost pipeline \
  --generate 1 \
  --generate-centroids-only \
  --generate-x-resolution 1024 \
  --generate-y-resolution 1024 \
  --fov 20 \
  --generate-ra 88 \
  --generate-de 7 \
  --generate-roll 0 \
  --generate-seed 394859 \
  --print-input-centroids "$tmp_dir/printed-centroids.txt" \
  --print-expected-attitude "$tmp_dir/expected-attitude.txt" || exit 1

grep 'input_centroid_.*_x ' "$tmp_dir/printed-centroids.txt" | awk '{print $2}' > "$tmp_dir/xs"
grep 'input_centroid_.*_y ' "$tmp_dir/printed-centroids.txt" | awk '{print $2}' > "$tmp_dir/ys"
paste "$tmp_dir/xs" "$tmp_dir/ys" > "$tmp_dir/stars.xy"
test -s "$tmp_dir/stars.xy" || exit 1

echo 'Solve from the centroid file'
lost_output=$(
  ./lost pipeline \
    --centroids "$tmp_dir/stars.xy" \
    --x-resolution 1024 \
    --y-resolution 1024 \
    --fov 20 \
    --database "$tmp_dir/db.dat" \
    --star-id-algo py \
    --attitude-algo dqm \
    --print-actual-centroids \
    --print-attitude
) || exit 1

echo "$lost_output" | grep 'num_actual_centroids' || exit 1
echo "$lost_output" | grep 'attitude_known 1' || exit 1

expected_ra=$(awk '/^expected_attitude_ra / { print $2 }' "$tmp_dir/expected-attitude.txt")
expected_de=$(awk '/^expected_attitude_de / { print $2 }' "$tmp_dir/expected-attitude.txt")
expected_roll=$(awk '/^expected_attitude_roll / { print $2 }' "$tmp_dir/expected-attitude.txt")
actual_ra=$(echo "$lost_output" | awk '/^attitude_ra / { print $2 }')
actual_de=$(echo "$lost_output" | awk '/^attitude_de / { print $2 }')
actual_roll=$(echo "$lost_output" | awk '/^attitude_roll / { print $2 }')

python3 -c '
import sys

def wrap_diff(a, b):
    d = abs(a - b) % 360.0
    return min(d, 360.0 - d)

expected_ra, expected_de, expected_roll, actual_ra, actual_de, actual_roll = map(float, sys.argv[1:])
ok = (
    wrap_diff(expected_ra, actual_ra) < 1.0
    and abs(expected_de - actual_de) < 1.0
    and wrap_diff(expected_roll, actual_roll) < 1.0
)
if not ok:
    sys.stderr.write("attitude mismatch: expected %s %s %s got %s %s %s\n" % (
        expected_ra, expected_de, expected_roll, actual_ra, actual_de, actual_roll))
    sys.exit(1)
' "$expected_ra" "$expected_de" "$expected_roll" "$actual_ra" "$actual_de" "$actual_roll"

echo 'Stdin (--centroids -) works'
echo "$lost_output" > /dev/null
stdin_output=$(
  ./lost pipeline \
    --centroids - \
    --x-resolution 1024 \
    --y-resolution 1024 \
    --fov 20 \
    --database "$tmp_dir/db.dat" \
    --star-id-algo py \
    --attitude-algo dqm \
    --print-attitude < "$tmp_dir/stars.xy"
) || exit 1
echo "$stdin_output" | grep 'attitude_known 1' || exit 1

set +x
echo '

Centroid-file input tests PASSED'
exit 0
