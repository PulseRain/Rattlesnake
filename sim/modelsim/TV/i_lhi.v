module single_port_ram_sim_high #(parameter ADDR_WIDTH, DATA_WIDTH ) (
    input  wire [ADDR_WIDTH - 1 : 0]         addr,
    input  wire [DATA_WIDTH - 1 : 0]         din,
    input  wire [DATA_WIDTH / 8 - 1 : 0]     write_en,
    input  wire                              clk,
    output reg [DATA_WIDTH - 1 : 0]          dout
);
    reg [DATA_WIDTH - 1 : 0] mem [(1<<ADDR_WIDTH)-1:0];
    genvar i;
    generate
        for (i = 0; i < (DATA_WIDTH / 8); i = i + 1) begin : gen_proc
            always @(posedge clk) begin
                if (write_en[i]) begin
                    mem[(addr)][8 * (i + 1) - 1 : 8 * i] <= din[8 * (i + 1) - 1 : 8 * i];
                end
            end
        end
    endgenerate
 
    always @(posedge clk) begin
        dout <= mem[addr];
    end
 
initial begin
end
endmodule
 
 
 
module single_port_ram_sim_low #(parameter ADDR_WIDTH, DATA_WIDTH ) (
    input  wire [ADDR_WIDTH - 1 : 0]         addr,
    input  wire [DATA_WIDTH - 1 : 0]         din,
    input  wire [DATA_WIDTH / 8 - 1 : 0]     write_en,
    input  wire                              clk,
    output reg [DATA_WIDTH - 1 : 0]          dout
);
    reg [DATA_WIDTH - 1 : 0] mem [(1<<ADDR_WIDTH)-1:0];
    genvar i;
    generate
        for (i = 0; i < (DATA_WIDTH / 8); i = i + 1) begin : gen_proc
            always @(posedge clk) begin
                if (write_en[i]) begin
                    mem[(addr)][8 * (i + 1) - 1 : 8 * i] <= din[8 * (i + 1) - 1 : 8 * i];
                end
            end
        end
    endgenerate
 
    always @(posedge clk) begin
        dout <= mem[addr];
    end
 
initial begin
end
endmodule
