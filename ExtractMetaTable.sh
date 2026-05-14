#!/usr/bin/env bash

dir="${1:-output}"   # default = output if not given

#echo "ebeam,pbeam,decay,subprocess,helicity,sigma,dsigma"

printf '\\'"begin{table}[]\n"
printf '\\'"centering\n"
printf '\\'"begin{tabular}{cccccc}\n"
#printf "E_e & E_p & decay & mode & helicity & \\sigma & \\Delta\\sigma \\\\\n"
printf "\$E_e\$ [GeV] & \$E_p\$ [GeV] & decay & mode & \$\\sigma\$ [nb] & \$\\Delta\\sigma\$ [nb] %s\n" \ '\\'
printf "\\hline\n"

for f in "$dir"/*.hepmc; do
  [ -e "$f" ] || continue

  base=$(basename "$f" .hepmc)

  # --- Parse filename ---
  # Format: 9x130_DDVCS_mumu_BHONLY_hplus

  #IFS='_' read -r beam process decay subprocess helicity <<< "$base"
  IFS='_' read -r beam process decay a b <<< "$base"

  # Detect whether subprocess is present
  if [[ "$b" == "" ]]; then
      # Format: beam_DDVCS_decay_helicity
      subprocess="ALL"
      helicity="$a"
  else
      # Format: beam_DDVCS_decay_subprocess_helicity
      subprocess="$a"
      helicity="$b"
  fi

  # Split beam
  ebeam=${beam%x*}
  pbeam=${beam#*x}

  # --- Extract cross section ---
  read sigma dsigma < <(
   tail -n 10 "$f" | awk '
      /integrated_cross_section_value/ {val=$3}
      /integrated_cross_section_uncertainty/ {err=$3}
      END {print val, err}
    '
  )

  
  # Clean helicity
  [ "$helicity" = "hplus" ] && helicity="+"
  [ "$helicity" = "hminus" ] && helicity="-" && continue
  
  # Clean subprocess
  [ "$subprocess" = "BHONLY" ] && subprocess="BH"
  [ "$subprocess" = " " ] && subprocess="ALL"

  # Clean decay
  [ $decay = "mumu" ] && decay="\$\\mu\\mu\$"
  
  # --- Print row ---
#  printf "%s & %s & %s & %s & %s & %.2f & %.2f \\\\\n" \
#	 "$ebeam" "$pbeam" "$decay" "$subprocess" "$helicity" "$sigma" "$dsigma"
  printf "%s & %s & %s & %s & %.2f & %.2f %s\n" \
	 "$ebeam" "$pbeam" "$decay" "$subprocess" "$sigma" "$dsigma" '\\'

done
printf '\\'"end{tabular}\n"
printf '\\'"caption{Caption}\n"
printf '\\'"label{tab:placeholder}\n"
printf '\\'"end{table}\n"
