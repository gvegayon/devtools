clear all
set more off
set trace off
mata mata clear
// cd i:/george/comandos_paquetes_librerias/stata/devtools
set matastrict on

mata mata mlib create ldevtools, replace
do devtools.mata
do dt_capture.mata
mata mata mlib add ldevtools dt_*()

mata dt_moxygen(("devtools.mata","dt_capture.mata"), "devtools.hlp")

mata dt_install_on_the_fly("devtools")
