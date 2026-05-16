catch "vcom -quiet -work work -2008 -explicit -stats=none D:/Documents/Fpga/Simulation/Crc32/ComputeCrc32.vhdl" comperror
if [expr {${comperror}!=""}] then {
	quit -f
}

catch "vcom -quiet -work work -2008 -explicit -stats=none D:/Documents/Fpga/Simulation/Crc32/TestComputeCrc32.vhdl" comperror
if [expr {${comperror}!=""}] then {
	quit -f
}

vsim -quiet TestComputeCrc32
run -all
quit -f