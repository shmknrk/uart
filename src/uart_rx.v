`resetall
`default_nettype none

module uart_rx #(
    parameter CLK_FREQ_MHZ   = 100   ,
    parameter BAUD_RATE      = 921600
) (
    input  wire       clk_i   ,
    input  wire       rst_ni  ,
    input  wire       rxd_i   ,
    output reg        rvalid_o,
    input  wire       rready_i,
    output reg  [7:0] rdata_o
);

    localparam WAIT_COUNT = ((CLK_FREQ_MHZ*1000*1000)/BAUD_RATE);

    // FSM
    reg state, n_state;
    localparam IDLE = 1'b0;
    localparam RUN  = 1'b1;

    reg rxd_t , n_rxd_t;
    reg rxd   , n_rxd  ;

    reg                                     n_rvalid_o ;
    reg                    [7:0]            n_rdata_o  ;
    reg                    [7:0] data     , n_data     ;
    reg                    [3:0] bit_cntr , n_bit_cntr ;
    reg [$clog2(WAIT_COUNT)-1:0] wait_cntr, n_wait_cntr;

    always @(*) begin
        n_rxd_t = rxd_i ;
        n_rxd   = rxd_t ;
    end

    always @(posedge clk_i) begin
        if (!rst_ni) begin
            rxd_t <= 1'b1;
            rxd   <= 1'b1;
        end else begin
            rxd_t <= n_rxd_t;
            rxd   <= n_rxd  ;
        end
    end

    always @(*) begin
        n_rvalid_o  = rvalid_o   ;
        n_rdata_o   = rdata_o    ;
        n_data      = data       ;
        n_bit_cntr  = bit_cntr   ;
        n_wait_cntr = wait_cntr-1;
        n_state     = state      ;
        if (rvalid_o && rready_i) begin
            n_rvalid_o = 1'b0;
        end
        casez (state)
            IDLE: begin
                if (~rxd) begin // rxd==1'b0
                    n_bit_cntr  = 4'd9        ;
                    n_wait_cntr = WAIT_COUNT-2;
                    n_state     = RUN         ;
                end
            end
            RUN: begin
                if (wait_cntr==(WAIT_COUNT+1)/2-1) begin
                    if (~|bit_cntr) begin // bit_cntr==0
                        n_rvalid_o = 1'b1;
                        n_rdata_o  = data;
                        n_state    = IDLE;
                    end
                    n_data     = {rxd, data[7:1]};
                    n_bit_cntr = bit_cntr-4'd1   ;
                end
                if (~|wait_cntr) begin // wait_cntr==0
                    n_wait_cntr = WAIT_COUNT-1;
                end
            end
            default: begin
                n_rvalid_o = 1'b0;
                n_state    = IDLE;
            end
        endcase
    end

    always @(posedge clk_i) begin
        if (!rst_ni) begin
            rvalid_o  <= 1'b0;
            state     <= IDLE;
        end else begin
            rvalid_o  <= n_rvalid_o ;
            rdata_o   <= n_rdata_o  ;
            data      <= n_data     ;
            bit_cntr  <= n_bit_cntr ;
            wait_cntr <= n_wait_cntr;
            state     <= n_state    ;
        end
    end

endmodule

`resetall
