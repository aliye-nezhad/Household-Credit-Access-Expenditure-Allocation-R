#!/usr/bin/env bash
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."
root="$PWD"
source_sha="92c5f6162323eb08cee9d51463814542f9a12367"
source_base="https://raw.githubusercontent.com/aliye-nezhad/household-catastrophic-health-expenditure-R/$source_sha/data/raw"
seven_zip="$(command -v 7zz || command -v 7z)"
test -n "$seven_zip" || { echo "7-Zip is required." >&2; exit 1; }
command -v mdb-export >/dev/null
command -v Rscript >/dev/null
command -v curl >/dev/null

mkdir -p reproduced
work="$(mktemp -d "$root/reproduced/.work-XXXXXXXX")"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/inputs" "$work/raw" "$work/results"
for filename in 93.rar R93.rar U93.rar; do
  curl --fail --location --silent --show-error --retry 3 \
    "$source_base/$filename" --output "$work/raw/$filename"
done
(
  cd "$work"
  sha256sum --check "$root/data/source_sha256.txt"
)
"$seven_zip" e "$work/raw/93.rar" -o"$work/inputs" -y >/dev/null
"$seven_zip" e "$work/raw/R93.rar" -o"$work/inputs" -y >/dev/null
"$seven_zip" e "$work/raw/U93.rar" -o"$work/inputs" -y >/dev/null
test -s "$work/inputs/93.mdb"
test -s "$work/inputs/R93.xls"
test -s "$work/inputs/U93.xls"
for table in R93Data U93Data R93P3S13 U93P3S13 \
  R93P3S03 U93P3S03 R93P3S05 U93P3S05 \
  R93P3S07 U93P3S07 R93P3S08 U93P3S08 \
  R93P3S09 U93P3S09 R93P3S11 U93P3S11; do
  mdb-export "$work/inputs/93.mdb" "$table" > "$work/inputs/$table.csv"
  test -s "$work/inputs/$table.csv"
done
Rscript --vanilla code/analysis.R "$work/inputs" "$work/results"
Rscript --vanilla code/extended_analysis.R "$work/inputs" "$work/results"
Rscript --vanilla code/measurement_sensitivity.R "$work/inputs" "$work/results"
Rscript --vanilla code/write_research_note.R "$work/results"
Rscript --vanilla code/validate.R "$work/results"
{
  printf 'Source Git commit: %s\n' "$source_sha"
  sha256sum "$work/raw/93.rar" "$work/raw/R93.rar" "$work/raw/U93.rar"
  sha256sum pixi.lock code/analysis.R code/extended_analysis.R \
    code/measurement_sensitivity.R code/write_research_note.R code/validate.R
} > "$work/results/diagnostics/input_hashes.txt"
run="$root/reproduced/run-$(date -u +%Y%m%dT%H%M%SZ)-$$"
mv "$work/results" "$run"
echo "Validated results: $run"
echo "--- Matched analytical sample (aggregate counts) ---"
cat "$run/diagnostics/sample_linkage.csv"
echo "--- Weighted borrowing-entry prevalence by residence ---"
cat "$run/tables/reported_loan_entries_by_residence.csv"
echo "--- Weighted food budget share by reporting status ---"
cat "$run/tables/budget_composition_by_reporting_status.csv"
echo "--- Model coefficients (first 15 lines) ---"
head -n 15 "$run/tables/regression_coefficients.csv"
echo "--- Annual durable purchase associations ---"
cat "$run/tables/annual_durable_purchase_associations.csv"
echo "--- Annual durable purchases by loan-entry status ---"
cat "$run/tables/annual_durable_purchase_by_reporting_status.csv"
echo "--- Six-sector purchase associations ---"
cat "$run/tables/sector_purchase_associations.csv"
echo "--- Financing-source classifications (aggregate) ---"
cat "$run/tables/financing_source_groups.csv"
echo "--- Measurement and expenditure-control sensitivity ---"
cat "$run/tables/leaveout_primary_robustness.csv"
echo "--- Exclusive loan-type reporting groups ---"
cat "$run/tables/exclusive_loan_reporting_groups.csv"
echo "--- Leave-out expenditure reconciliation ---"
cat "$run/diagnostics/expenditure_leaveout_reconciliation.csv"
echo "--- Monthly sector-spending differences ---"
cat "$run/tables/monthly_sector_spending_differences.csv"
