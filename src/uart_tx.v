`resetall
`default_nettype none

module uart_tx #(
    parameter CLK_FREQ_MHZ   = 100   ,
    parameter BAUD_RATE      = 921600
) (
    input  wire       clk_i   ,
    input  wire       rst_ni  ,
    output wire       txd_o   ,
    input  wire       wvalid_i,
    output reg        wready_o,
    input  wire [7:0] wdata_i
);

    localparam WAIT_COUNT = ((CLK_FREQ_MHZ*1000*1000)/BAUD_RATE);

    // FSM
    reg state, n_state;
    localparam IDLE = 1'b0;
    localparam RUN  = 1'b1;

    reg                                       n_wready_o ;
    reg                    [8:0] data = 9'h1, n_data     ;
    reg                    [3:0] bit_cntr   , n_bit_cntr ;
    reg [$clog2(WAIT_COUNT)-1:0] wait_cntr  , n_wait_cntr;

    assign txd_o = data[0];

    always @(*) begin
        n_wready_o  = wready_o   ;
        n_data      = data       ;
        n_bit_cntr  = bit_cntr   ;
        n_wait_cntr = wait_cntr-1;
        n_state     = state      ;
        casez (state)
            IDLE: begin
                if (wvalid_i) begin // wvalid_i && wready_o
                    n_wready_o  = 1'b0           ;
                    n_data      = {wdata_i, 1'b0};
                    n_bit_cntr  = 4'd9           ;
                    n_wait_cntr = WAIT_COUNT-1   ;
                    n_state     = RUN            ;
                end
            end
            RUN: begin
                if (~|wait_cntr) begin // wait_cntr==0
                    if (~|bit_cntr) begin // bit_cntr==0
                        n_wready_o = 1'b1;
                        n_state    = IDLE;
                    end
                    n_data      = {1'b1, data[8:1]};
                    n_bit_cntr  = bit_cntr-4'd1    ;
                    n_wait_cntr = WAIT_COUNT-1     ;
                end
            end
            default: begin
                n_wready_o = 1'b1;
                n_data     = 9'b1; // txd_o <= 1'b1;
                n_state    = IDLE;
            end
        endcase
    end

    always @(posedge clk_i) begin
        if (!rst_ni) begin
            wready_o  <= 1'b1;
            data      <= 9'b1; // txd_o <= 1'b1;
            state     <= IDLE;
        end else begin
            wready_o  <= n_wready_o ;
            data      <= n_data     ;
            bit_cntr  <= n_bit_cntr ;
            wait_cntr <= n_wait_cntr;
            state     <= n_state    ;
        end
    end

endmodule

`resetall
