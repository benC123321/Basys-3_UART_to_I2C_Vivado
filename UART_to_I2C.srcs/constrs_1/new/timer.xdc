# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
#	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK100MHZ]
	
#set_property PACKAGE_PIN V17 [get_ports {data[0]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {data[0]}]
#set_property PACKAGE_PIN V16 [get_ports {data[1]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {data[1]}]
#set_property PACKAGE_PIN W16 [get_ports {data[2]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {data[2]}]
#set_property PACKAGE_PIN W17 [get_ports {data[3]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {data[3]}]
#set_property PACKAGE_PIN W15 [get_ports {data[4]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {data[4]}]
#set_property PACKAGE_PIN V15 [get_ports {data[5]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {data[5]}]
#set_property PACKAGE_PIN W14 [get_ports {data[6]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {data[6]}]
#set_property PACKAGE_PIN W13 [get_ports {data[7]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {data[7]}]
	
##Sch name = JA1
set_property PACKAGE_PIN J1 [get_ports I2C_clk_out]					
	set_property IOSTANDARD LVCMOS33 [get_ports I2C_clk_out]

##Sch name = JA2
set_property PACKAGE_PIN L2 [get_ports I2C_data_out]					
	set_property IOSTANDARD LVCMOS33 [get_ports I2C_data_out]
	

#set_property PACKAGE_PIN J1 [get_ports TxD_debug]					
#	set_property IOSTANDARD LVCMOS33 [get_ports TxD_debug]
##Sch name = JA3
set_property PACKAGE_PIN J2 [get_ports UART_DATA_READY]					
	set_property IOSTANDARD LVCMOS33 [get_ports UART_DATA_READY]

set_property PACKAGE_PIN B18 [get_ports RxD]						
	set_property IOSTANDARD LVCMOS33 [get_ports RxD]
	
set_property PACKAGE_PIN A18 [get_ports TxD]						
	set_property IOSTANDARD LVCMOS33 [get_ports TxD]
