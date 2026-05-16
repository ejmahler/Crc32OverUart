catch "vcom -quiet -work work -2008 -explicit -stats=none D:/Documents/Fpga/Simulation/Crc32/TopCrc32OverUart.vhdl" comperror
if [expr {${comperror}!=""}] then {
	quit -f
}

catch "vcom -quiet -work work -2008 -explicit -stats=none D:/Documents/Fpga/Simulation/Crc32/TestTopCrc32OverUart.vhdl" comperror
if [expr {${comperror}!=""}] then {
	quit -f
}

vsim -quiet TestTopCrc32OverUart
run -all
quit -f