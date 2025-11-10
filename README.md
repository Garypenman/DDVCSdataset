Doubly Deeply Virtual Compton Scattering (DDVCS) with the EpIC generator. Currently focusing on the Low-Q2 limit of (Quasi-real) Timelike Compton Scattering. Input cards are also provided for J/psi production at similar kinematics for the study of background physics and muonID with EpIC.

The EpIC generator is used to generate DDVCS MC events. Currently there are steering cards for ee and mumu @ 18x275 energy configuration, and ee at 10x130. More configs will come in the future.
Author: Paweł Sznajder
Link: https://github.com/pawelsznajder/epic
Installation: https://pawelsznajder.github.io/epic/instalation.html
Usage: https://pawelsznajder.github.io/epic/usage.html

The eStarlight generator is used to generate J/psi MC events. 
Author: eic collaboration
Link: https://github.com/eic/estarlight
Installation: 
Usage:


Files are output from the generators in hepmc ascii format. These must be afterburned (available in eic-shell), and then converted to hepmc root format (availabe in eic software stack)

abconv -p 0 18x275_ddvcs_edecay_hminus.hepmc ab_18x275_ddvcs_edecay_hminus.hepmc
hepmc3ascii2root ab_18x275_ddvcs_edecay_hminus.hepmc ab_18x275_ddvcs_edecay_hminus.root

These afterburned hepmc3 root files are currently available at (with the exception of the 10x130, currently not in the campaign requests)
/gpfs/mnt/gpfs02/eic/gpenman/
under straightforwardly named directories:
DDVCS_18x275/  DDVCS_muon_18x275/  JPsi_18x275/  JPsi_muon_18x275/
