`resetall
`default_nettype none

module fifo #(
    parameter DATA_WIDTH = 8 ,
    parameter FIFO_DEPTH = 16
) (
    input  wire                  clk_i        ,
    input  wire                  rst_ni       ,
    input  wire                  fifo_wvalid_i,
    output reg                   fifo_wready_o,
    input  wire [DATA_WIDTH-1:0] fifo_wdata_i ,
    output wire                  fifo_rvalid_o,
    input  wire                  fifo_rready_i,
    output reg  [DATA_WIDTH-1:0] fifo_rdata_o
);

    reg [DATA_WIDTH-1:0] ram [0:FIFO_DEPTH-1];

    reg   [$clog2(FIFO_DEPTH)-1:0] fifo_waddr , n_fifo_waddr ;
    reg   [$clog2(FIFO_DEPTH)-1:0] fifo_raddr1, n_fifo_raddr1;
    reg [$clog2(FIFO_DEPTH+1)-1:0] fifo_count , n_fifo_count ;

    reg [DATA_WIDTH-1:0] fifo_rdata_t;

    reg fifo_empty_n, n_fifo_empty_n;
    reg fifo_full_n , n_fifo_full_n ;

    reg                  n_fifo_wready_o;
    reg [DATA_WIDTH-1:0] n_fifo_rdata_o ;

    assign fifo_rvalid_o = fifo_empty_n;

    always @(*) begin
        n_fifo_empty_n  = fifo_empty_n ;
        n_fifo_full_n   = fifo_full_n  ;
        n_fifo_waddr    = fifo_waddr   ;
        n_fifo_raddr1   = fifo_raddr1  ;
        n_fifo_count    = fifo_count   ;
        n_fifo_wready_o = fifo_wready_o;
        n_fifo_rdata_o  = fifo_rdata_o ;
        // FIFO Write
        n_fifo_wready_o = (fifo_wvalid_i && !fifo_wready_o && fifo_full_n);
        if (fifo_wvalid_i && fifo_wready_o) begin
            n_fifo_waddr = fifo_waddr+1;
        end
        // FIFO Read
        if (fifo_rvalid_o && fifo_rready_i) begin
            n_fifo_raddr1  = fifo_raddr1+1;
            n_fifo_rdata_o = fifo_rdata_t ;
        end
        if (!fifo_empty_n && fifo_wvalid_i && fifo_wready_o) begin // Forwarding if FIFO is empty
            n_fifo_rdata_o = fifo_wdata_i;
        end
        // FIFO Status
        casez ({fifo_wvalid_i && fifo_wready_o, fifo_rvalid_o && fifo_rready_i})
            2'b10  : begin
                n_fifo_empty_n = 1'b1;
                if (fifo_count==FIFO_DEPTH-1) n_fifo_full_n = 1'b0;
                n_fifo_count = fifo_count+1;
            end
            2'b01  : begin
                if (fifo_count==1) n_fifo_empty_n = 1'b0;
                n_fifo_full_n = 1'b1;
                n_fifo_count  = fifo_count-1;
            end
            default: ;
        endcase
    end

    always @(posedge clk_i) begin
        fifo_rdata_t <= ram[fifo_raddr1];
        if (fifo_wvalid_i && fifo_wready_o) begin
            ram[fifo_waddr] <= fifo_wdata_i;
        end
    end

    always @(posedge clk_i) begin
        if (!rst_ni) begin
            fifo_empty_n  <= 1'b0                                ;
            fifo_full_n   <= 1'b1                                ;
            fifo_wready_o <= 1'b0                                ;
            fifo_rdata_o  <= {DATA_WIDTH{1'b0}}                  ;
            fifo_waddr    <= {$clog2(FIFO_DEPTH){1'b0}}          ;
            fifo_raddr1   <= {{$clog2(FIFO_DEPTH)-1{1'b0}}, 1'b1};
            fifo_count    <= {$clog2(FIFO_DEPTH+1){1'b0}}        ;
        end else begin
            fifo_empty_n  <= n_fifo_empty_n ;
            fifo_full_n   <= n_fifo_full_n  ;
            fifo_wready_o <= n_fifo_wready_o;
            fifo_rdata_o  <= n_fifo_rdata_o ;
            fifo_waddr    <= n_fifo_waddr   ;
            fifo_raddr1   <= n_fifo_raddr1  ;
            fifo_count    <= n_fifo_count   ;
        end
    end

endmodule

`resetall
