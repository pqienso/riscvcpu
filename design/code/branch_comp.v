module branch_comp(
    input wire [31:0] rs1_data,
    input wire [31:0] rs2_data,
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    output reg branch_taken
);
    always @(*) begin

        // B-type
        if (opcode == 7'b1100011) begin
	    if (funct3 == 3'b000) begin // BEQ
                branch_taken = rs1_data == rs2_data ? 1 : 0;
	    end else if (funct3 == 3'b001) begin // BNE
                branch_taken = rs1_data != rs2_data ? 1 : 0;
	    end else if (funct3 == 3'b100) begin // BLT
                branch_taken = $signed(rs1_data) < $signed(rs2_data) ? 1 : 0;
	    end else if (funct3 == 3'b101) begin // BGE
	        branch_taken = $signed(rs1_data) >= $signed(rs2_data) ? 1 : 0;
	    end else if (funct3 == 3'b110) begin // BLTU
	        branch_taken = rs1_data < rs2_data ? 1 : 0;
	    end else if (funct3 == 3'b111) begin // BGEU
	        branch_taken = rs1_data >= rs2_data ? 1 : 0;
	    end else begin
	        branch_taken = 0;
	    end


	end else begin
	    branch_taken = 0;
	end
    end
endmodule
