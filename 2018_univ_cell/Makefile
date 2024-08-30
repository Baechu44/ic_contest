BAK = *.bak
LOG = *.log *.history *.key *.fsdb out_log.txt novas.rc novas.conf *.sdf.X *.vcd
INCA_libs = INCA_libs
cad_dir = spyglass-* nWaveLog* BSSLib.lib* simv.daidir csrc xcelium.d vfastLog
TB ?= tb1

sim: 
	vcs testfixture.v LCD_CTRL.v +define+$(TB) -full64 -R -debug_access+all +v2k +neg_tchk

clean:
	-rm -f ${BAK} ${LOG} simv
	-rm -rf ${INCA_libs} ${cad_dir} 
