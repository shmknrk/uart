`resetall
`default_nettype none

`include "config.vh"

module uart (
    input  wire clk_i ,
    input  wire rst_ni,
    input  wire rxd_i ,
    output wire txd_o
);

    localparam CLK_FREQ_MHZ = `CLK_FREQ_MHZ;
    localparam BAUD_RATE    = `BAUD_RATE   ;
    localparam FIFO_DEPTH   = `FIFO_DEPTH  ;

    // UART
    wire       uart_rvalid;
    wire       fifo_wready;
    wire [7:0] uart_rdata ;
    wire       fifo_rvalid;
    wire       uart_wready;
    wire [7:0] fifo_rdata ;

    // Clock and Reset Siganls
    wire clk  ;
    wire rst_n;
`ifdef NO_IP
    assign clk = clk_i;
    reg r_rst_n1 = 1'b0, r_rst_n2 = 1'b0;
    always @(posedge clk) begin
        r_rst_n1 <= rst_ni  ;
        r_rst_n2 <= r_rst_n1;
    end
    assign rst_n = r_rst_n2;
`else
    wire locked;
    clk_wiz_0 clk_wiz_0 (
        .clk_out1(aclk   ),
        .reset   (!rst_ni),
        .locked  (locked ),
        .clk_in1 (aclk_i )
    );
    reg r_rst_n1 = 1'b0, r_rst_n2 = 1'b0;
    always @(posedge aclk) begin
        r_rst_n1 <= (rst_ni && locked);
        r_rst_n2 <= r_rst_n1          ;
    end
    assign rst_n = r_rst_n2;
`endif

    // UART Receiver
    uart_rx #(
        .CLK_FREQ_MHZ(CLK_FREQ_MHZ),
        .BAUD_RATE   (BAUD_RATE   )
    ) uart_rx0 (
        .clk_i   (clk        ),
        .rst_ni  (rst_n      ),
        .rxd_i   (rxd_i      ),
        .rvalid_o(uart_rvalid),
        .rready_i(fifo_wready),
        .rdata_o (uart_rdata )
    );

    // FIFO
    fifo #(
        .DATA_WIDTH(8         ),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) fifo0 (
        .clk_i        (clk        ),
        .rst_ni       (rst_n      ),
        .fifo_wvalid_i(uart_rvalid),
        .fifo_wready_o(fifo_wready),
        .fifo_wdata_i (uart_rdata ),
        .fifo_rvalid_o(fifo_rvalid),
        .fifo_rready_i(uart_wready),
        .fifo_rdata_o (fifo_rdata )
    );

    // UART Transmitter
    uart_tx #(
        .CLK_FREQ_MHZ(CLK_FREQ_MHZ),
        .BAUD_RATE   (BAUD_RATE   )
    ) uart_tx0 (
        .clk_i   (clk        ),
        .rst_ni  (rst_n      ),
        .txd_o   (txd_o      ),
        .wvalid_i(fifo_rvalid),
        .wready_o(uart_wready),
        .wdata_i (fifo_rdata )
    );

endmodule

`resetall
