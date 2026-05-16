catch "vcom -quiet -work work -2008 -explicit -stats=none D:/Documents/Fpga/Simulation/Crc32/UartTxBuffered.vhdl" comperror
if [expr {${comperror}!=""}] then {
	quit -f
}

catch "vcom -quiet -work work -2008 -explicit -stats=none D:/Documents/Fpga/Simulation/Crc32/UartRxBuffered.vhdl" comperror
if [expr {${comperror}!=""}] then {
	quit -f
}

catch "vcom -quiet -work work -2008 -explicit -stats=none D:/Documents/Fpga/Simulation/Crc32/TestUartBuffered.vhdl" comperror
if [expr {${comperror}!=""}] then {
	quit -f
}

vsim -quiet TestUartBuffered
run -all
quit -f