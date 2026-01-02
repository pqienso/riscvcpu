module decoder(
    input wire reset,
    input wire [31:0] inst,
    output wire [6:0] d_opcode,
    output reg [4:0] d_rd,
    output reg [4:0] d_rs1,
    output reg [4:0] d_rs2,
    output wire [2:0] d_funct3,
    output wire [6:0] d_funct7,
    output reg [31:0] d_imm,
    output wire [4:0] d_shamt
);
    assign d_opcode = reset ? 7'b0010011 : inst[6:0];

    assign d_funct3 = reset ? 3'b0 : inst[14:12];

    assign d_funct7 = reset ? 7'b0 : inst[31:25];

    always @ (*) begin
	if (reset) begin
	    d_imm = 32'b0;
	    d_rs1 = 5'b0;
	    d_rs2 = 5'b0;
	    d_rd = 5'b0;
	
        // LUI, AUIPC
	end else if (
	    d_opcode == 7'b0110111 ||
	    d_opcode == 7'b0010111
	) begin
            d_imm = { inst[31:12], 12'b0 };
	    d_rs1 = 5'b0;
	    d_rs2 = 5'b0;
	    d_rd = inst[11:7];

	// JAL
        end else if (d_opcode == 7'b1101111) begin
	    d_imm = { {12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0 };
	    d_rs1 = 5'b0;
	    d_rs2 = 5'b0;
	    d_rd = inst[11:7];
	
	// B-type
	end else if (d_opcode == 7'b1100011) begin
	    d_imm = { {20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0 };
	    d_rs1 = inst[19:15];
	    d_rs2 = inst[24:20];
	    d_rd = 5'b0;

	// S-type
        end else if (d_opcode == 7'b0100011) begin
	    d_imm = { {21{inst[31]}}, inst[30:25], inst[11:7] };
	    d_rs1 = inst[19:15];
	    d_rs2 = inst[24:20];
	    d_rd = 5'b0;

        // JALR, load instructions, I-type
	end else if (
	    d_opcode == 7'b1100111 ||
            d_opcode == 7'b0000011 || 
            d_opcode == 7'b0010011
	) begin
	    d_imm = { {21{inst[31]}}, inst[30:20] };
	    d_rs1 = inst[19:15];
	    d_rs2 = 5'b0;
	    d_rd = inst[11:7];
	
	// R-type
	end else begin
	    d_imm = 32'b0;
	    d_rs1 = inst[19:15];
	    d_rs2 = inst[24:20];
	    d_rd = inst[11:7];
	end
    end

    assign d_shamt = inst[24:20];
    
endmodule
