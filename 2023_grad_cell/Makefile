BAK = *.bak
LOG = *.log *.history *.key *.fsdb out_log.txt novas.rc novas.conf *.sdf.X *.vcd
INCA_libs = INCA_libs
cad_dir = spyglass-* nWaveLog* BSSLib.lib* simv.daidir csrc xcelium.d vfastLog

sim: 
	vcs -R -sverilog tb.sv LASER.v +define+P1+USECOLOR +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+LASER.fsdb

all:
	vcs -R -sverilog tb.sv LASER.v +define+USECOLOR +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+LASER.fsdb 

clean:
	-rm -f ${BAK} ${LOG} simv
	-rm -rf ${INCA_libs} ${cad_dir} 
