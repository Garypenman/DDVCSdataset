#!/bin/bash
set -e

# ============================================================
# make_xml.sh
#
# Generates DDVCS XML steering files + a run manifest.
#
# Supports:
#  - physics scans via lists (energies, helicities, decays, pol)
#  - single or split runs
#  - dry-run mode (no files written)
#
# ============================================================


# ============================================================
# Safety / mode flags
# ============================================================

DRY_RUN=0
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=1
else
    mkdir -p output
    mkdir -p output/histos
fi


# ============================================================
# Helper functions
# ============================================================

msg() {
  echo "[make_xml] $*"
}

do_or_echo() {
  if [[ "$DRY_RUN" == "1" ]]; then
    msg "DRY-RUN: $*"
  else
    eval "$@"
  fi
}

MERGE_PLAN="merge_plan.sh"
if [[ "$DRY_RUN" == "1" ]]; then
  msg "Would create merge plan: $MERGE_PLAN"
else
  echo "#!/bin/bash" > "$MERGE_PLAN"
  echo "# Auto-generated merge plan" >> "$MERGE_PLAN"
  echo "set -e" >> "$MERGE_PLAN"
  echo "" >> "$MERGE_PLAN"
  chmod +x "$MERGE_PLAN"
fi


# ============================================================
# ===================== EDIT HERE ONLY =======================
# Physics scan definitions (these map directly to XML params)
# ============================================================


# --- Allowed beam configs ---
ALLOWED_CONFIGS=(
  9x100
  9x130
  9x275
#  10x100
#  10x130
#  18x275
)

LEP_E_LIST=(9 10 18)
HAD_E_LIST=(100 130 275)
LEP_HEL_LIST=(1 -1)              # 1 or -1
DECAY_TYPE_LIST=("e-" "mu-")        # "e-" (ee) or "mu-" (mumu)
HAD_POL_LIST=("0.|0.|0.$")    # future-proofed

SUBPROCESS_LIST=("ALL" "BH")

# Kinematic ranges (strings copied verbatim into XML)
Q2_RANGE="0.0|10.0"
T_RANGE="-2.|-0.0001"
Q2P_RANGE="2.|18."
PHI_RANGE="0.0|6.28318"
PHIS_RANGE="0.0|6.28318"
PHIL_RANGE="0.0|6.28318"
THETAL_RANGE="0.031416|3.110177"
Y_RANGE="0.0|1.0"
XBJ_RANGE="0.0|1.0"


# ============================================================
# Run control
# ============================================================

MODE="single"            # single | split
NEVENTS_TOTAL=1000000
NSPLIT=20                # only used if MODE=split


# ============================================================
# Derived run control (do not edit)
# ============================================================

if [[ "$MODE" == "split" ]]; then
  NEVENTS_PER_RUN=$((NEVENTS_TOTAL / NSPLIT))
else
  NSPLIT=1
  NEVENTS_PER_RUN=$NEVENTS_TOTAL
fi


# ============================================================
# Manifest setup
# ============================================================

MANIFEST="runs.manifest.csv"

if [[ "$DRY_RUN" == "1" ]]; then
  msg "Would create manifest: $MANIFEST"
else
  echo "job_id,xml,nevents,hepmc,root" > "$MANIFEST"
fi


# ============================================================
# Main generation loop
# ============================================================

JOB=0
NCONFIGS=0
TOTAL_JOBS=0

for LEP_E in "${LEP_E_LIST[@]}"; do
    for HAD_E in "${HAD_E_LIST[@]}"; do
	config="${LEP_E}x${HAD_E}"

	# --- Check if config is allowed ---
	if [[ ! " ${ALLOWED_CONFIGS[*]} " =~ " ${config} " ]]; then
	    echo "Skipping invalid config: $config"
	    continue
	fi
	
	for SUBPROCESS in "${SUBPROCESS_LIST[@]}"; do
	    for DECAY_TYPE in "${DECAY_TYPE_LIST[@]}"; do
		for LEP_HEL in "${LEP_HEL_LIST[@]}"; do
		    for HAD_POL in "${HAD_POL_LIST[@]}"; do

			NCONFIGS=$((NCONFIGS + 1))

			# --------------------------
			# Human-readable tags
			# --------------------------

			case "$LEP_HEL" in
			    1)  LEP_HEL_TAG="plus" ;;
			    -1)  LEP_HEL_TAG="minus" ;;
			    *)
				echo "ERROR: unknown LEP_HEL = $LEP_HEL"
				exit 1
				;;
			esac

			if [[ "$DECAY_TYPE" == "e-" ]]; then
			    DECAY_TAG="ee"
			elif [[ "$DECAY_TYPE" == "mu-" ]]; then
			    DECAY_TAG="mumu"
			else
			    echo "ERROR: unknown DECAY_TYPE = $DECAY_TYPE"
			    exit 1
			fi

			if [[ "$SUBPROCESS" == "ALL" ]]; then
			    SUBPROCESS_TAG=""
			elif [[ "$SUBPROCESS" == "BH" ]]; then
			    SUBPROCESS_TAG="bhonly_"
			else
			    echo "ERROR: unknown SUBPROCESS = $SUBPROCESS"
			    exit 1
			fi

			#POL_TAG=$(echo "$HAD_POL" | tr '|.$' '_')
			BASE_TAG="${LEP_E}x${HAD_E}_ddvcs_${DECAY_TAG}_${SUBPROCESS_TAG}h${LEP_HEL_TAG}"
			#BASE_TAG+=p${POL_TAG}"
			
			# --------------------------
			# Split runs if requested
			# --------------------------
			SPLIT_HEPMC_FILES=()
			SPLIT_ROOT_FILES=()
			FINAL_HEPMC="output/${BASE_TAG}.hepmc"
			FINAL_ROOT="output/histos/${BASE_TAG}.root"

			
			if [[ -f "$FINAL_HEPMC" ]]; then
			    msg "Skipping ${BASE_TAG} (final HEPMC already exists)"
			    continue
			fi
			
			
			for ((i=0; i<NSPLIT; i++)); do

			    RUN_TAG=$(printf "r%02d" "$i")

			    if [[ "$NSPLIT" -eq 1 ]]; then
				TAG="${BASE_TAG}"
			    else
				RUN_TAG=$(printf "r%02d" "$i")
				TAG="${BASE_TAG}_${RUN_TAG}"
			    fi
			    
			    XML="scenarios/${TAG}.xml"
			    OUT_FILE="output/${TAG}.hepmc"
			    HISTO_FILE="output/histos/${TAG}.root"

			    SPLIT_HEPMC_FILES+=("$OUT_FILE")
			    SPLIT_ROOT_FILES+=("$HISTO_FILE")

			    export SUBPROCESS
			    export LEP_E HAD_E LEP_HEL DECAY_TYPE HAD_POL
			    export Y_RANGE Q2_RANGE T_RANGE Q2P_RANGE XBJ_RANGE
			    export PHI_RANGE PHIS_RANGE PHIL_RANGE THETAL_RANGE
			    export NEVENTS="$NEVENTS_PER_RUN"
			    export OUT_FILE HISTO_FILE
			    export DATE="$(date +%F)"
			    export DESC="DDVCS auto-generated"

			    #	    if [[ -f "$XML" ]]; then
			    #	      msg "Skipping ${XML} (steering card already exists)"
			    #	      continue
			    #	    fi
			    
			    do_or_echo "envsubst < ddvcs.template.xml > $XML"

			    JOB=$(printf "%04d" $((10#$JOB + 1)))
			    TOTAL_JOBS=$((TOTAL_JOBS + 1))

			    LINE="$JOB,$XML,$NEVENTS,$OUT_FILE,$HISTO_FILE"

			    if [[ "$DRY_RUN" == "1" ]]; then
				msg "Would add to manifest: $LINE"
			    else
				echo "$LINE" >> "$MANIFEST"
			    fi

			done
			if [[ "$NSPLIT" -gt 1 ]]; then

			    HEPMC_LIST="${SPLIT_HEPMC_FILES[*]}"
			    ROOT_LIST="${SPLIT_ROOT_FILES[*]}"
			    
			    if [[ "$DRY_RUN" == "1" ]]; then
				msg "Would add merge step for ${BASE_TAG}"
				msg "  HEPMC -> ${FINAL_HEPMC}"
				msg "  ROOT  -> ${FINAL_ROOT}"
			    else
				{
				    echo ""
				    echo "echo \"Merging ${BASE_TAG}\""
				    echo "# Merge HEPMC"
				    echo "cat ${HEPMC_LIST} > ${FINAL_HEPMC}"
				    echo ""
				    echo "# Merge ROOT (requires hadd)"
				    echo "hadd -f ${FINAL_ROOT} ${ROOT_LIST}"
				} >> "$MERGE_PLAN"
			    fi
			    
			fi
		    done
		done
	    done
	done
    done
done

# ============================================================
# Dry-run summary
# ============================================================

if [[ "$DRY_RUN" == "1" ]]; then
  echo
  echo "========== DRY-RUN SUMMARY =========="
  echo "Configs scanned      : $NCONFIGS"
  echo "Splits per config    : $NSPLIT"
  echo "Total jobs           : $TOTAL_JOBS"
  echo "Events per job       : $NEVENTS_PER_RUN"
  echo "Total events/config  : $NEVENTS_TOTAL"
  echo "===================================="
fi

msg "Done."
