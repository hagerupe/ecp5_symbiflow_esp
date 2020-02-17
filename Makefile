all :
	docker build --network=host -t ecp5:local .

run_x11 : 
	x11docker ecp5:local --clipboard --home

run_qtc_verilog :
	x11docker ecp5:local --clipboard --home --hostdisplay /opt/qtverilog/QtcVerilog/bin/QtcVerilog

run :
	docker run --privileged --network=host -it ecp5:local zsh

