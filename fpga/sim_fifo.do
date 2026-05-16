catch "vcom -quiet -work work -2008 -explicit -stats=none D:/Documents/Fpga/Simulation/Crc32/Fifo.vhdl" comperror
if [expr {${comperror}!=""}] then {
	quit -f
}

catch "vcom -quiet -work work -2008 -explicit -stats=none D:/Documents/Fpga/Simulation/Crc32/TestFifo.vhdl" comperror
if [expr {${comperror}!=""}] then {
	quit -f
}

vsim -quiet TestFifo
run -all
quit -f