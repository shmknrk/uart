`resetall
`default_nettype none

`include "config.vh"

`ifdef VERILATOR
module top(
    input wire clk  ,
    input wire rst_n
);
`else
module top;
    reg clk   = 1'b0; always #1 clk <= !clk;
    reg rst_n = 1'b0;
    initial begin
        #10 rst_n = 1'b1;
    end
`endif

    reg [63:0] sim_cycle = 0;
    always @(posedge clk) begin
        sim_cycle <= sim_cycle+64'h1;
    end

`ifdef TIMEOUT
    always @(negedge clk) begin
        if (sim_cycle>=`TIMEOUT) begin
            $write("Simulation Time Out...\n");
            $finish;
        end
    end
`endif

`ifdef TRACE_VCD
    initial begin
        $dumpfile(`TRACE_VCD_FILE);
        $dumpvars(0);
    end
`endif

`ifdef TRACE_FST
    initial begin
        $dumpfile(`TRACE_FST_FILE);
        $dumpvars(0);
    end
`endif

    localparam CLK_FREQ_MHZ = `CLK_FREQ_MHZ;
    localparam BAUD_RATE    = `BAUD_RATE   ;

    initial begin
        $write("Clock Frequency [MHz]: %d\n", CLK_FREQ_MHZ);
        $write("Baud Rate            : %d\n", (CLK_FREQ_MHZ*1000*1000)/BAUD_RATE);
    end

    reg [7:0] rom [0:15];
    initial begin
        rom[ 0] = "H";
        rom[ 1] = "e";
        rom[ 2] = "l";
        rom[ 3] = "l";
        rom[ 4] = "o";
        rom[ 5] = ",";
        rom[ 6] = " ";
        rom[ 7] = "F";
        rom[ 8] = "P";
        rom[ 9] = "G";
        rom[10] = "A";
        rom[11] = "!";
        rom[12] = "\n";
        rom[13] = 8'h0;
        rom[14] = 8'h0;
        rom[15] = 8'h0;
    end

    reg  [3:0] rom_raddr  ;
    reg        uart_wvalid;
    wire       uart_wready;
    wire [7:0] uart_wdata ;

    assign uart_wdata = rom[rom_raddr];

    always @(posedge clk) begin
        if (!rst_n) begin
            uart_wvalid <= 1'b0;
            rom_raddr   <= 4'h0;
        end else begin
            uart_wvalid <= 1'b1;
            if (uart_wvalid && uart_wready) begin
                rom_raddr <= rom_raddr+4'h1;
            end
        end
    end

    wire txd;
    uart_tx #(
        .CLK_FREQ_MHZ(CLK_FREQ_MHZ),
        .BAUD_RATE   (BAUD_RATE   )
    ) uart_tx0 (
        .clk_i   (clk        ),
        .rst_ni  (rst_n      ),
        .txd_o   (txd        ),
        .wvalid_i(uart_wvalid),
        .wready_o(uart_wready),
        .wdata_i (uart_wdata )
    );

    wire rxd;
    uart uart0 (
        .clk_i (clk  ),
        .rst_ni(rst_n),
        .rxd_i (txd  ),
        .txd_o (rxd  )
    );

    wire       uart_rvalid;
    wire       uart_rready;
    wire [7:0] uart_rdata ;

    assign uart_rready = 1'b1;

    uart_rx #(
        .CLK_FREQ_MHZ(CLK_FREQ_MHZ),
        .BAUD_RATE   (BAUD_RATE   )
    ) uart_rx0 (
        .clk_i   (clk        ),
        .rst_ni  (rst_n      ),
        .rxd_i   (rxd        ),
        .rvalid_o(uart_rvalid),
        .rready_i(uart_rready),
        .rdata_o (uart_rdata )
    );

    always @(negedge clk) begin
        if (uart_rvalid && uart_rready) begin
            $write("%c", uart_rdata);
        end
    end

endmodule

`resetall
