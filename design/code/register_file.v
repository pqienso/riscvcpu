module register_file #()
(
    input wire clock,
    input wire [4:0] addr_rs1,
    input wire [4:0] addr_rs2,
    input wire [4:0] addr_rd,
    input wire [31:0] data_rd,
    output reg [31:0] data_rs1,
    output reg [31:0] data_rs2,
    input wire write_enable,
    input wire reset
);
    localparam START_ADDRESS = 32'h01000000;
    (* ram_style = "block" *) reg[31:0] reg_file[0:31];

    //---------INIT MEMORY--------------
    integer i;
    initial begin
	for (i = 0; i < 32; i = i+1) begin
	    reg_file[i] = 32'h0;
	end
	reg_file[2] = START_ADDRESS + `MEM_DEPTH;
    end
    //-------------------------------------
     

    always @ (posedge clock) begin
	if (write_enable && addr_rd != 5'b0 && ~reset) begin
	    reg_file[addr_rd] <= data_rd;
	end

	data_rs1 <= reg_file[addr_rs1];
	data_rs2 <= reg_file[addr_rs2];
    end

endmodule
