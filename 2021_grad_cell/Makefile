BAK = *.bak
LOG = *.log *.history *.key *.fsdb out_log.txt novas.rc novas.conf *.sdf.X *.vcd
INCA_libs = INCA_libs
cad_dir = spyglass-* nWaveLog* BSSLib.lib* simv.daidir csrc xcelium.d vfastLog

sim: 
	vcs -R -full64 -sverilog tb.sv geofence.v +access+r +vcs+fsdbon 

clean:
	-rm -f ${BAK} ${LOG} simv
	-rm -rf ${INCA_libs} ${cad_dir} 
