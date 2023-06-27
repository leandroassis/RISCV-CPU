SRC = $(wildcard *.vhd)
Flags = --std=08

all:
	ghdl -a $(Flags) $(SRC)
	ghdl -e $(Flags) STA_teste
	ghdl -r $(Flags) STA_teste --wave=testbench.ghw --stop-time=10us