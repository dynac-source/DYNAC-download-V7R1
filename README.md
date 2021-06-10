# DYNAC-download
DYNAC DOWNLOAD PAGE  for DYNAC V7R1, a Multiparticle Beam Simulation Code for linacs and beam transport lines.

LINUX/MAC and WINDOWS downloads for the simulation code DYNAC V7R1 can be found on this page. Instructions for installation after downloading are in the file: readme.txt . This file is also contained in the full package below.
MODIFICATIONS PERTAINING TO DYNAC V7R1 (1-May-2020)

Modifications to DYNAC V7R1 (text file)

OPERATING SYSTEM REQUIREMENTS FOR DYNAC
DYNAC has been succesfully tested on LINUX (Red Hat 4.4.7-17 and Mint), MAC (Mojave, High Sierra and some older) and WINDOWS (10 and older).
DYNAC needs to be compiled with gfortran, which is available from the gfortran web site. DYNAC has been successfully tested with gfortran/gcc 8.1.0 and older
GNU Plot (ZIP format) for WINDOWS can be obtained from the gnuplot web site.
Using the same link you can find a GNU Plot download for the MAC (download not always required for LINUX, as gnuplot is standard with some flavors of LINUX). On the MAC, it is suggested to install gnuplot with the wxt terminal (e.g. brew install gnuplot --with-wxmac --with-cairo), as it is considerably faster than the aqua terminal.
OPEN ISSUES (1-May-2020)

The charge stripper model requires further development (e.g. energy loss model).

DYNAC V7R1 (FULL PACKAGE)
DYNAC source, data, plot and help files (for WINDOWS, ZIP format)
DYNAC source, data, plot and help files (for LINUX/MAC, tar/gz format)
Note: To unzip the linux/mac version, type: tar xvfz dynacv7r1.tar.gz

DYNAC V7R1 (INDIVIDUAL FILES)
DYNAC User Guide (PDF format) [dynac_UG.pdf](https://github.com/dynac-source/DYNAC-download/files/6633231/dynac_UG.pdf)
DYNAC input file (example) for an electron gun (text format)
DYNAC input file (example) for describing the field in an electron gun (text format; to be used with the egun example above)
DYNAC input file for the SNS H- MEBT (Medium Energy Beam Transport) line and DTL Tank 1 (text format)
DYNAC source (for WINDOWS, ZIP format)
Script to compile the DYNAC source (for WINDOWS, text format, wherby the extension should be renamed from .txt to .bat)
DYNAC source file (for LINUX and MAC, tar/gz format)
Script to compile the DYNAC source (for LINUX and MAC, text format)
dyndat.f90 (used by PLOTIT; source file (V3.1) in text format; save in dynac/plot directory)
Script to compile the dyndat source (for WINDOWS, text format, wherby the extension should be renamed from .txt to .bat)
Script to compile the dyndat source (for LINUX and MAC, text format)
Note: To unzip the linux/mac version of the source, type: tar xvfz dynacv7r1_source.tar.gz
