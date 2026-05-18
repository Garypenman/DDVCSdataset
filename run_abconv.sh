#!/bin/bash

# ============================================================
# run_abconv.sh
#
# Custom afterburner + conversion script for DDVCSdataset
#
# - Converts .hepmc ? rootfiles/
# - Afterburns ? afterburned/
# - Applies correct beam configuration per dataset
# - Runs hiacc/hidiv scans for selected configs
# ============================================================

mkdir -p rootfiles
mkdir -p afterburned

# ---- Function to map beam ? afterburn configs ----
get_configs() {

    beam="$1"

    case "$beam" in

        # --- Well-defined ---
        9x130)
            echo ":ip6_ep_130x9"
            ;;

        # --- Study both hiacc and hidiv ---
        9x100)
            echo "hiacc:ip6_hiacc_100x9 hidiv:ip6_hidiv_100x9"
            ;;

        9x275)
            echo "hiacc:ip6_hiacc_275x9 hidiv:ip6_hidiv_275x9"
            ;;

        # --- Deprecated / ignore ---
        10x100|10x130|18x275)
            echo ""
            ;;

        *)
            echo ""
            ;;
    esac
}

# ============================================================
# MAIN LOOP
# ============================================================

for f in *.hepmc; do

    # Remove extension
    base="${f%.hepmc}"

    # Extract beam config (first token before "_")
    beam="${base%%_*}"

    echo "-------------------------------------------"
    echo "File: $f"
    echo "Beam: $beam"

    # ========================================================
    # 1. Conversion step
    # ========================================================

    rootfile="rootfiles/${base}.hepmc3.tree.root"

    if [ ! -f "$rootfile" ]; then
        echo "Converting ? $rootfile"
        ~/hepmc3ascii2root/install/bin/hepmc3ascii2root "$f" "$rootfile"
    else
        echo "Conversion exists ? skipping"
    fi

    # ========================================================
    # 2. Afterburner config selection
    # ========================================================

    configs=$(get_configs "$beam")

    if [ -z "$configs" ]; then
        echo "Skipping afterburn (unsupported or deprecated beam)"
        continue
    fi

    # ========================================================
    # 3. Run afterburner for each config
    # ========================================================

    for cfgpair in $configs; do

        label="${cfgpair%%:*}"
        abcfg="${cfgpair##*:}"
	
        
	if [ -z "$label" ]; then
	    outbase="afterburned/ab_${base}"
	else
	    outbase="afterburned/ab_${base}_${label}"
	fi
	outfile="${outbase}.hepmc3.tree.root"
	
        # --- Check if already valid ---
        if [ -f "$outfile" ]; then
            size=$(stat -c%s "$outfile")

            if [ "$size" -gt 1000000 ]; then
                echo "$outfile exists (valid), skipping"
                continue
            else
                echo "Found small/invalid file ? reprocessing"
            fi
        fi

        echo "Afterburning [$label] using $abcfg"
        echo " ? Output: $outfile"

        abconv -p "$abcfg" "$f" -o "$outbase" --plot-off

        # --- Verify output ---
        if [ -f "$outfile" ]; then
            size=$(stat -c%s "$outfile")

            if [ "$size" -lt 1000000 ]; then
                echo "WARNING: afterburn likely failed for $outfile (size too small)"
            fi
        else
            echo "ERROR: afterburn failed to produce $outfile"
        fi

    done

done

echo "-------------------------------------------"
echo "Done."
