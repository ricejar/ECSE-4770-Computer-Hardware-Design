module stopwatch_controller(input SS,
                            input CS,
                            input RST,
                            input SA,
                            input CLK,
                            output ADDLATCH,
                            output ME,
                            output MW,
                            output MEMLATCH,
                            output LD,
                            output E,
                            output CLR,
                            output MUXC);
    parameter STOP  = 0;
    parameter COUNT = 1;
    parameter WAIT  = 2;
    parameter SHOW  = 3;
    parameter SAVE  = 4;
    parameter SSD   = 5;
    parameter CSD   = 6;
    reg ADDLATCH_TMP;
    reg ME_TMP;
    reg MW_TMP;
    reg MEMLATCH_TMP;
    reg LD_TMP;
    reg E_TMP;
    reg CLR_TMP;
    reg MUXC_TMP;
    reg [2:0] state;
    reg SSS, CSS;
    initial begin
        ADDLATCH_TMP = 0; // Keep latch at logic low.
        MEMLATCH_TMP = 0;
        ME_TMP       = 1; // Set to enable RAM to reset data.
        MW_TMP       = 1; // Set to write mode to save 0.
        LD_TMP       = 1; // Active low, so set high to inactive.
        E_TMP        = 0; // Stop the counter
        CLR_TMP      = 0; // Clear the counter.
        MUXC_TMP     = 1; // Select the cleared counter output.
        SSS          = 0;
        CSS          = 0;
    end
    always @(*) begin
        ADDLATCH_TMP <= CLK;
        MEMLATCH_TMP <= CLK;
    end
    
    always @(state) begin
        case (state)
            SSD: begin
                $display("DEB: SSD");
            end
            CSD: begin
                $display("DEB: CSD");
            end
            STOP: begin
                $display("STOP");
                ME_TMP   <= 0; // Enable memory
                MW_TMP   <= 1; // Diable memory write
                E_TMP    <= 0; // Stop the counter
                MUXC_TMP <= 1; // Show the counter value
            end
            COUNT: begin
                $display("COUNT");
                ME_TMP   <= 0; // Enable memory
                MW_TMP   <= 1; // Memory read-only
                E_TMP    <= 1; // Start the counter
                MUXC_TMP <= 1; // show the counter value
            end
            WAIT: begin
                $display("WAIT");
                ME_TMP   <= 0; // Enable memory
                MW_TMP   <= 1; // Memory read-only
                E_TMP    <= 0; // Stop the counter
                MUXC_TMP <= 0; // Show the ram output
            end
            SHOW: begin
                $display("SHOW");
                ME_TMP   <= 0; // Enable memory
                MW_TMP   <= 1; // Memory read-only
                E_TMP    <= 0; // Stop the counter
                MUXC_TMP <= 0; // Show the ram output
            end
            SAVE: begin
                $display("SAVE");
                ME_TMP   <= 0; // Enable memory
                MW_TMP   <= 0; // Memory write
                E_TMP    <= 1; // Counter enabled
                MUXC_TMP <= 1; // Show the counter output
            end
        endcase
    end
    
    assign ADDLATCH = ADDLATCH_TMP;
    assign ME       = ME_TMP;
    assign MW       = MW_TMP;
    assign MEMLATCH = MEMLATCH_TMP;
    assign LD       = LD_TMP;
    assign E        = E_TMP;
    assign CLR      = CLR_TMP;
    assign MUXC     = MUXC_TMP;
    
    always @(posedge CLK) begin
        if (RST) begin
            state <= STOP;
            if (SS) begin
                state <= COUNT;
            end
        end
            if (SS || CS) begin
                if (SS) begin
                    SSS   <= 1;
                    state <= SSD;
                end
                else begin
                    CSS   <= 1;
                    state <= CSD;
                end
            end
                case(state)
                    STOP: begin
                        if (SSS && !SS) begin
                            CLR_TMP <= 0; // Clear the counter
                            LD_TMP  <= 1; // Do not load counter
                            SSS     <= 0; // Change SSS back to 0
                            state   <= COUNT;
                        end
                        else if (CSS && !CS) begin
                            CLR_TMP <= 1; // Do not clear the counter
                            LD_TMP  <= 1; // Do not load counter
                            CSS     <= 0; // Change CSS back to 0
                            state   <= WAIT;
                        end
                        else begin
                            CLR_TMP <= 1; // Hold the counter value
                            LD_TMP  <= 1; // Do not load counter
                            state   <= STOP;
                        end
                    end
                    COUNT: begin
                        if (SA) begin
                            CLR_TMP <= 1; // Do not clear counter
                            LD_TMP  <= 1; // Do not load counter
                            state   <= SAVE;
                        end
                        else if (SSS && !SS) begin
                            CLR_TMP <= 1; // Do not clear counter
                            LD_TMP  <= 1; // Do not load counter
                            SSS     <= 0; // Change SSS back to 0
                            state   <= STOP;
                        end
                        else begin
                            CLR_TMP <= 1; // Do not clear counter
                            LD_TMP  <= 1; // Do not load counter
                            state   <= COUNT;
                        end
                    end
                    SAVE: begin
                        CLR_TMP <= 1; // Do not clear counter
                        LD_TMP  <= 1; // Do not load counter
                        state   <= COUNT;
                    end
                    WAIT: begin
                        if (CSS && !CS) begin
                            CLR_TMP <= 1; // Do not clear counter
                            LD_TMP  <= 1; // Do not load counter
                            CSS     <= 0; // Change CSS back to 0
                            state   <= STOP;
                        end
                        else if (SSS && !SS) begin
                            CLR_TMP <= 1; // Do not clear counter
                            LD_TMP  <= 0; // Load counter
                            SSS     <= 0; // Change SSS back to 0
                            state   <= COUNT;
                        end
                        else if (SA) begin
                            CLR_TMP <= 1; // Do not clear counter
                            LD_TMP  <= 1; // Do not load counter
                            state   <= SHOW;
                        end
                        else begin
                            CLR_TMP <= 1; // Do not clear counter
                            LD_TMP  <= 1; // Do not load counter
                            state   <= WAIT;
                        end
                    end
                    SHOW: begin
                        CLR_TMP <= 1; // Do not clear counter
                        LD_TMP  <= 1; // Do not load counter
                        state   <= WAIT;
                    end
                endcase
    end
endmodule
