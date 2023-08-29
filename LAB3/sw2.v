// On the big mdule box, the counters do not output unless they had received an enable at some point. This is why the startup & reset sequnce is E + CLR (S0), then CLR (S9), then base state (S1). S9 was added later when it was discovered that is was necessary, hence the out of order numbering
// on DE10, CLK causes internal state change & output change prior to all CLK events completing on 74 series module. This is a race condition, and breaks counter CLR, as CLR is positive edge triggered on the module. This is corrected by making the state machine negative edge triggered. not required for FPGA only implementation

module stopwatch_controller(input CLK, input RST, input SS, input CS, input SA, output ADDLATCH, output ME, output MW, output MEMLATCH, output LD, output E, output CLR, output MUXC);

reg [3:0] state;
wire SS_int;
wire CS_int;
wire SA_int;

initial begin
	state = 0;
end

localparam S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4, S5 = 5, S6 = 6, S7 = 7, S8 = 8, S9 = 9;

assign ME = 1'b0;
assign E = (state == S0 || state == S3 || state == S4 || state == S5 );
assign MUXC = !(state == S6 ||state == S7 || state == S8);
assign ADDLATCH = (state == S4 || state == S7);
assign MEMLATCH = (state == S6);
assign LD = (state != S8);
assign MW = (state != S5);
assign CLR = !(state == S0 || state == S9 || state == S2);

debounce SS_PB(.sig_in(SS), .CLK(CLK), .reset(RST), .sig_out(SS_int));
debounce CS_PB(.sig_in(CS), .CLK(CLK), .reset(RST), .sig_out(CS_int));
debounce SA_sig(.sig_in(~SA), .CLK(CLK), .reset(RST), .sig_out(SA_int));					// if SA is not debounced then memory is written at the same adress with the same value on each CLK. Could be source of error, but not having this did result in correct function in testing.

always @(negedge CLK) begin
	if (!RST)
		state <= S0;
	else begin
		case (state)
			S0:
				state <= S9;
			S1:
				if (SS_int)
					state <= S2;
				else if (CS_int)
					state <= S7;
			S2:
				state <= S3;
			S3:
				if (SS_int)
					state <= S1;
				else if (SA_int)
					state <= S4;
			S4:
				state <= S5;
			S5:
				state <= S3;
			S6:
				if (SS_int)
					state <= S8;
				else if (CS_int)
					state <= S1;
				else if (SA_int)
					state <= S7;
			S7:
				state <= S6;
			S8:
				state <= S3;
			S9:
				state <= S1;
			default:
				state <= S0;
		endcase
	end
end

endmodule

module debounce (input sig_in, input CLK, input reset, output sig_out);

	//reg sig_last;
	reg D1;
	reg D2;
	always @ (posedge CLK) begin				// resets for active low operation
		if (!reset) begin
			D1 <= 1;
			D2 <= 1;
		end
		else begin
			//D1 <= sig_in != sig_last;
			D1 <= sig_in;							// comment this, and uncomment the other 3 lines in this module to instead use toggle SS and CS inputs, like the switchboards in CII 6116
			D2 <= D1;
			//sig_last = sig_in;
		end
	end
	assign sig_out = !D1 & D2;

endmodule
