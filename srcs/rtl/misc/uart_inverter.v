module uart_inverter(
	input tx_dest,
	input tx_src,
	output rx_src,
	output rx_dest
);
	assign rx_src = tx_dest;
	assign rx_dest = tx_src;

endmodule
