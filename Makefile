SRC = $(wildcard src/*.vhd)
Flags = --std=08

all:
	ghdl -a $(Flags) $(SRC)
	ghdl -e $(Flags) alu_test
	ghdl -r $(Flags) alu_test --wave=testbench.ghw --stop-time=10us
	mv testbench.ghw ./test/waveforms/testbench.ghw