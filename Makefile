SRC = $(wildcard src/*.vhd)
Flags = --std=08

all:
	ghdl -a $(Flags) $(SRC)
	ghdl -e $(Flags) test_pc
	ghdl -r $(Flags) test_pc --wave=testbench.ghw --stop-time=10us
	mv testbench.ghw ./test/waveforms/testbench.ghw