catch "vcom -quiet -work work -2008 -explicit -stats=none D:/Documents/Fpga/Simulation/Crc32/UartRx.vhdl" comperror
if [expr {${comperror}!=""}] then {
	quit -f
}

catch "vcom -quiet -work work -2008 -explicit -stats=none D:/Documents/Fpga/Simulation/Crc32/TestUartRx.vhdl" comperror
if [expr {${comperror}!=""}] then {
	quit -f
}

vsim -quiet TestUartRx
run -all
quit -f