module alu(
    input wire [31:0] rs1_data,
    input wire [31:0] rs2_data,
    input wire [31:0] imm,
    input wire [31:0] pc,
    input wire [6:0] opcode,
    input wire [6:0] funct7,
    input wire [2:0] funct3,
    input wire [4:0] shamt,
    output reg [31:0] alu_result
);

    always @(*) begin

	if (
	    opcode == 7'b0110111 // LUI
        ) begin
	    alu_result = imm;

	end else if (
	    opcode == 7'b0010111 || // AUIPC
            opcode == 7'b1101111 || // JAL
	    opcode == 7'b1100011    // B-type
        ) begin  
	    alu_result = pc + imm;

	end else if (
	    opcode == 7'b1100111 || // JALR
	    opcode == 7'b0000011 || // load instruction
            opcode == 7'b0100011    // store instruction
        ) begin
	    alu_result = rs1_data + imm;

        // I-type
	end else if (opcode == 7'b0010011) begin
	    if (funct3 == 3'b0) begin // ADDI
		alu_result = rs1_data + imm;
            end else if (funct3 == 3'b010) begin // SLTI
	        alu_result = $signed(rs1_data) < $signed(imm) ? 32'b1 : 32'b0;
            end else if (funct3 == 3'b011) begin // SLTIU
	        alu_result = rs1_data < imm ? 32'b1 : 32'b0;
	    end else if (funct3 == 3'b100) begin // XORI
	        alu_result = rs1_data ^ imm;
	    end else if (funct3 == 3'b110) begin // ORI
		alu_result = rs1_data | imm;
	    end else if (funct3 == 3'b111) begin // ANDI
		alu_result = rs1_data & imm;
	    end else if (funct3 == 3'b001 && funct7[5] == 0) begin // SLLI
		alu_result = rs1_data << shamt;
	    end else if (funct3 == 3'b101 && funct7[5] == 0) begin // SRLI
		alu_result = rs1_data >> shamt;
	    end else if (funct3 == 3'b101 && funct7[5] == 1) begin // SRAI
		alu_result = $signed(rs1_data) >>> shamt;
	    end else begin
		alu_result = 32'b0;
	    end

        // R-type	
        end else if (opcode == 7'b0110011) begin
	    if (funct3 == 3'b000 && funct7[5] == 0) begin // ADD
		alu_result = rs1_data + rs2_data;
	    end else if (funct3 == 3'b000 && funct7[5] == 1) begin // SUB
		alu_result = rs1_data - rs2_data;
	    end else if (funct3 == 3'b001 && funct7[5] == 0) begin // SLL
		alu_result = rs1_data << rs2_data[4:0];
	    end else if (funct3 == 3'b010 && funct7[5] == 0) begin // SLT
		alu_result = $signed(rs1_data) < $signed(rs2_data) ? 32'b1 : 32'b0;
	    end else if (funct3 == 3'b011 && funct7[5] == 0) begin // SLTU
		alu_result = rs1_data < rs2_data ? 32'b1 : 32'b0;
	    end else if (funct3 == 3'b100 && funct7[5] == 0) begin // XOR
		alu_result = rs1_data ^ rs2_data;
	    end else if (funct3 == 3'b101 && funct7[5] == 0) begin // SRL
		alu_result = rs1_data >> rs2_data[4:0];
	    end else if (funct3 == 3'b101 && funct7[5] == 1) begin // SRA
		alu_result = $signed(rs1_data) >>> rs2_data[4:0];
	    end else if (funct3 == 3'b110 && funct7[5] == 0) begin // OR
		alu_result = rs1_data | rs2_data;
	    end else if (funct3 == 3'b111 && funct7[5] == 0) begin // AND
		alu_result = rs1_data & rs2_data;
	    end else begin
		alu_result = 32'b0;
	    end

	end else begin
	    alu_result = 32'b0;
	end
    end
endmodule


