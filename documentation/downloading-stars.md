# Downloading a Star Catalog

LOST can identify against the Yale Bright Star Catalog (BSC, HR numbers) or
Hipparcos-1 (HIP numbers). BSC is the default. Databases are built from whichever
catalog `CatalogRead()` loads; rebuild the `.dat` after switching.

# Automatically

Run `make bright-star-catalog.tsv` from the base directory of LOST to generate
`bright-star-catalog.tsv`. Simply running `make` will do this as well.

For Hipparcos-1 (VizieR `I/239/hip_main`, Johnson V ≤ 7, J2000 RA/Dec):

```shell
make hipparcos-catalog.tsv
```

Then point LOST at it before `database` or `pipeline`:

```shell
export LOST_HIP_PATH=hipparcos-catalog.tsv
./lost database --max-stars 20000 --min-mag 7 --kvector --output hip-kvector.dat
```

The Hipparcos extract is about 15,000 stars. The default `--max-stars 10000` will
drop the dimmest unless you raise it. Printed star IDs will be HIP numbers.

# Manually (BSC)

I recommend using http://vizier.cfa.harvard.edu/viz-bin/VizieR-3?-source=I/50. VizieR is a web
interface for accessing about a bajillion different catalogs of stellar objects. This specific
catalog is the "Brightest Stars Catalog". It contains about 9,000 stars, which are all that any
relatively cheap camera is likely to pick up.

First, go over to the little "Preferences" box on the left. Near the top, set the max rows to
"unlimited" and the output style to `|-separated values`. Make sure that `J2000` is checked and that
the `Decimal` option is selected. This tells the database to convert into a standard stellar
coordinate system.

Then, see the `"target"` box near the top of the center. Write `"0+0"`, `"J2000"`, `360 deg`. This field is
for people who want to only fetch stars from a certain slice of the sky, but we want to download the
whole thing!

In the main panel, you should check the `HR`, `Multiple`, and `VMag` boxes, which correspond to a
unique ID for the star, an indicator whether the star is binary (or more), and star brightness.
Uncheck the others.

Then hit "Submit" and download your stars!

After downloading, remove all the lines from the file that aren't data; there's some header-y stuff
near the top.

# Manually (Hipparcos)

Use http://vizier.cfa.harvard.edu/viz-bin/VizieR-3?-source=I/239/hip_main (Hipparcos-1, not
Hipparcos-2). Same VizieR preferences as BSC: unlimited rows, `|-separated values`, J2000 decimal
coordinates, whole sky.

Check `HIP` and `Vmag`. Constrain `Vmag` to `<=7` so the catalog stays under the 16-bit pair-index
limit used in the k-vector database. Uncheck the others.

The data lines should look like `ra|dec|HIP|Vmag`. Save as `hipparcos-catalog.tsv` and set
`LOST_HIP_PATH`.
