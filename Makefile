SRC = $(wildcard src/*.vhd)
Flags = --std=08

all:
	ghdl -a $(Flags) $(SRC)
	ghdl -e $(Flags) reg_file_teste
	ghdl -r $(Flags) reg_file_teste --wave=testbench.ghw --stop-time=10us
	mv testbench.ghw ./test/waveforms/testbench.ghw