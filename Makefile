SRC = $(wildcard src/*.vhd)
Flags = --std=08

all:
	ghdl -a $(Flags) $(SRC)
	ghdl -e $(Flags) ctrl_unit
	ghdl -r $(Flags) Ctrl_unit --wave=testbench.ghw --stop-time=10us
	mv testbench.ghw ./test/waveforms/testbench.ghw