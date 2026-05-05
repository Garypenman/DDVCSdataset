#!/bin/bash

# ----------------------------
# Beam energy grids
# ----------------------------
LEP_E_LIST=(9)
HAD_E_LIST=(100 130 275)
LEP_HEL_LIST=(-1 1)

# Hadron polarisation vectors
# Format must match generator expectation: Px|Py|Pz$
HAD_POL_LIST=("0.|0.|0.$")


# Decay channels
# Generator expects: e- (ee) or mu- (mumu)
DECAY_TYPE_LIST=("e-" "mu-")

export DATE=$(date +%F)
export DESC="DDVCS scan"
export NEVENTS=1000000
export SUBPROCESS=ALL

export Q2_RANGE="0.0|10.0"
export T_RANGE="-2.|-0.0001"
export Q2P_RANGE="2.|18."
export PHI_RANGE=

for LEP_E in "${LEP_E_LIST[@]}"; do
    for HAD_E in "${HAD_E_LIST[@]}"; do
	for LEP_HEL in "${LEP_HEL_LIST[@]}"; do
#	    for HAD_POL in "${HAD_POL_LIST[@]}"; do
	    for DECAY_TYPE in "${DECAY_TYPE_LIST[@]}"; do
		
		export LEP_E HAD_E LEP_HEL HAD_POL DECAY_TYPE
		
		# Human-readable decay tag
		if [[ "$DECAY_TYPE" == "e-" ]]; then
			DECAY_TAG="ee"
		elif [[ "$DECAY_TYPE" == "mu-" ]]; then
		    DECAY_TAG="mumu"
		fi
		
		case "$LEP_HEL" in
		    1)
			LEP_HEL_TAG="plus"
			;;
		    -1)
			LEP_HEL_TAG="minus"
			;;
		    *)
			echo "ERROR: Unknown LEP_HEL value: $LEP_HEL"
			exit 1
			;;
		esac
		
#		POL_TAG=$(echo "$HAD_POL" | tr '|.$' '_')

		TAG="${LEP_E}x${HAD_E}_DDVCS_${DECAY_TAG}_h${LEP_HEL_TAG}"
		export HISTO_FILE="output/${TAG}.root"
		export OUT_FILE="output/${TAG}.hepmc"
		
		envsubst < ddvcs.template.xml > scenarios/EIC_${TAG}.xml
		echo "Created steering_${TAG}.xml"
		
	    done
	done
    done
done
