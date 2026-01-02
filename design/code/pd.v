module pd(
  input clock,
  input reset
);
    // -------------FETCH--------------
    wire [31:0] f_pc;
    reg [31:0] f_counter_pc;
    wire stall;

    assign stall = (ltu_hazard || wd_hazard);

    localparam START_ADDRESS = 32'h01000000;
    
    imemory #() imem(
	.clock(clock),
	.address(f_pc),
	.data_in(32'b0),
	.read_write(1'b0),
	.enable(!stall && !reset),
	.data_out(d_insn)
    );

    wire pc_jump;
    assign pc_jump = (
        e_br_taken ||
        e_opcode == 7'b1101111 || // JAL
	e_opcode == 7'b1100111    // JALR
    );

    always @ (posedge clock) begin
	if (reset) begin
	    f_counter_pc <= START_ADDRESS;
	end else if (!stall) begin
	    f_counter_pc <= f_pc + 4;
	end
    end
    assign f_pc = pc_jump ? e_alu_res : f_counter_pc;

    // ------------DECODE-------------
    wire [6:0] d_opcode;
    wire [4:0] d_rd;
    wire [4:0] d_rs1;
    wire [4:0] d_rs2;
    wire [2:0] d_funct3;
    wire [6:0] d_funct7;
    wire [31:0] d_imm;
    wire [4:0] d_shamt;
    reg [31:0] d_pc;
    wire [31:0] d_insn;

    always @ (posedge clock) begin
	if (reset) begin
	    d_pc <= 32'b0;
	end else if (!stall) begin
	    d_pc <= f_pc;
	end
    end
    
    decoder decoder(
	.reset(reset),
	.inst(d_insn),
	.d_opcode(d_opcode),
	.d_rd(d_rd),
	.d_rs1(d_rs1),
	.d_rs2(d_rs2),
	.d_funct3(d_funct3),
	.d_funct7(d_funct7),
	.d_imm(d_imm),
	.d_shamt(d_shamt)
    );
    
    // Register file
    
    wire r_write_enable;
    wire [4:0] r_write_destination;
    wire [31:0] r_write_data;

    wire [4:0] r_read_rs1;
    wire [4:0] r_read_rs2;

    assign r_read_rs1 = d_rs1;
    assign r_read_rs2 = d_rs2;

    register_file register_file(
        .clock(clock),
	.addr_rs1(r_read_rs1),
	.addr_rs2(r_read_rs2),
	.addr_rd(r_write_destination),
	.data_rd(r_write_data),
	.data_rs1(e_rs1_data),
	.data_rs2(e_rs2_data),
	.write_enable(r_write_enable),
	.reset(reset)
    );

    wire d_uses_rs2;
    assign d_uses_rs2 = (
	d_opcode == 7'b0110011 || // R-type
	d_opcode == 7'b1100011 || // B-type
	d_opcode == 7'b0100011    // S-type
    );

    wire d_uses_rs1;
    assign d_uses_rs1 = (
	d_uses_rs2             ||
	d_opcode == 7'b0010011 || // I-type
	d_opcode == 7'b0000011 || // Load instructions
	d_opcode == 7'b1100111    // JALR
    );

    wire ltu_hazard;
    assign ltu_hazard = (
	(e_rd != 5'b0) &&
	(e_opcode == 7'b0000011) && // Load instr
	(
	     (d_uses_rs1 && (d_rs1 == e_rd)) ||
	     (d_uses_rs2 && (d_rs2 == e_rd) && (d_opcode != 7'b0100011))
	)
    );
    wire wd_hazard;
    assign wd_hazard = (
	(w_destination != 5'b0) &&
        (
	    ((w_destination == d_rs1) && (d_rs1 != e_rd) && (d_rs1 != m_rd)) ||
	    ((w_destination == d_rs2) && (d_rs2 != e_rd) && (d_rs2 != m_rd))
        )
    );
    
    
    // ---------------EXECUTE-------------
    
    reg [31:0] e_pc;
    reg [6:0] e_opcode;
    reg [4:0] e_rd;
    reg [4:0] e_rs1;
    reg [4:0] e_rs2;
    wire [31:0] e_rs1_data;
    wire [31:0] e_rs2_data;
    reg [2:0] e_funct3;
    reg [6:0] e_funct7;
    reg [31:0] e_imm;
    reg [4:0] e_shamt;
    reg [31:0] e_alu_opr1;
    reg [31:0] e_alu_opr2;
    wire e_br_taken;
    wire [31:0] e_alu_res;
    reg e_nop;

    wire e_rs1_use_mx;
    wire e_rs1_use_wx;
    wire e_rs2_use_mx;
    wire e_rs2_use_wx;
    wire e_can_use_mx;
    wire e_can_use_wx;

    assign e_can_use_mx = (
	m_opcode == 7'b0110011 || // R-type
	m_opcode == 7'b0010011 || // I-type
	m_opcode == 7'b0110111 || // LUI
	m_opcode == 7'b0010111 || // AUIPC
	m_opcode == 7'b1101111 || // JAL
	m_opcode == 7'b1100111    // JALR
    ) && (m_rd != 5'b0);
    assign e_rs1_use_mx = e_can_use_mx && (e_rs1 == m_rd);
    assign e_rs2_use_mx = e_can_use_mx && (e_rs2 == m_rd);

    assign e_can_use_wx = w_enable && (w_destination != 5'b0);
    assign e_rs1_use_wx = e_can_use_wx && (e_rs1 == w_destination);
    assign e_rs2_use_wx = e_can_use_wx && (e_rs2 == w_destination);

    always @(*) begin
	if (e_nop) begin
	    e_alu_opr1 = 32'b0;
	end else if (e_rs1_use_mx) begin
   	    e_alu_opr1 = m_alu_res;
        end else if (e_rs1_use_wx) begin
            e_alu_opr1 = w_data;
	end else begin
	    e_alu_opr1 = e_rs1_data;
	end
    end
    always @(*) begin
	if (e_nop) begin
	   e_alu_opr2 = 32'b0;
	end else if (e_rs2_use_mx) begin
	   e_alu_opr2 = m_alu_res;
	end else if (e_rs2_use_wx) begin
	   e_alu_opr2 = w_data;
	end else begin
	    e_alu_opr2 = e_rs2_data;
	end
    end

    always @ (posedge clock) begin
	if (reset || wd_hazard || ltu_hazard || pc_jump) begin
	    e_opcode <= 7'b0010011;
	    e_rd <= 5'b0;
	    e_funct3 <= 3'b0;
	    e_funct7 <= 7'b0;
	    e_imm <= 32'b0;
	    e_shamt <= 5'b0;
	    e_rs1 <= 5'b0;
	    e_rs2 <= 5'b0;
	end else begin
	    e_pc <= d_pc;
	    e_opcode <= d_opcode;
            e_rd <= d_rd;
	    e_funct3 <= d_funct3;
	    e_funct7 <= d_funct7;
	    e_imm <= d_imm;
	    e_shamt <= d_shamt;
	    e_rs1 <= d_rs1;
	    e_rs2 <= d_rs2;
	end
	e_nop <= (wd_hazard || ltu_hazard || reset || pc_jump);
    end

    
    alu alu(
        .rs1_data(e_alu_opr1),
	.rs2_data(e_alu_opr2),
	.imm(e_imm),
        .pc(e_pc),
	.opcode(e_opcode),
	.funct7(e_funct7),
	.funct3(e_funct3),
	.shamt(e_shamt),
	.alu_result(e_alu_res)
    );

    branch_comp branch_comp(
	.rs1_data(e_alu_opr1),
	.rs2_data(e_alu_opr2),
	.opcode(e_opcode),
	.funct3(e_funct3),
	.branch_taken(e_br_taken)
    );


    // ---------------MEMORY--------------
   
    reg [4:0] m_rd;
    reg [31:0] m_pc;
    reg [31:0] m_alu_res;
    reg [31:0] m_address;
    reg [4:0] m_rs1;
    reg [4:0] m_rs2;
    reg [31:0] m_rs2_data;
    reg m_rw;
    reg [1:0] m_size_encoded;
    wire [31:0] m_data;
    reg [6:0] m_opcode;
    reg m_is_unsigned;

    wire m_use_wm;
    wire m_can_use_wm;

    assign m_can_use_wm = (
	( // Any inst writing to a reg
	    w_opcode == 7'b0000011 || // Load inst
	    w_opcode == 7'b0110011 || // R-type
	    w_opcode == 7'b0010011 || // I-type
	    w_opcode == 7'b0110111 || // LUI
	    w_opcode == 7'b0010111 || // AUIPC
	    w_opcode == 7'b1101111 || // JAL
	    w_opcode == 7'b1100111    // JALR
	) &&
	m_opcode == 7'b0100011    // Store inst.
    );
    assign m_use_wm = m_can_use_wm && (m_rs2 == w_destination);

    always @ (posedge clock) begin
	if (reset) begin
	    m_rd <= 5'b0;
	    m_rw <= 1'b0;
	    m_size_encoded <= 2'b0;
	    m_address <= 32'b0;
	    m_rs2_data <= 32'b0;
	    m_is_unsigned <= 1'b0;
	    m_opcode <= 7'b0010011;
	    m_rs1 <= 5'b0;
	    m_rs2 <= 5'b0;
	    m_alu_res <= 32'b0;
	end else begin
	    m_pc <= e_pc;
	    m_rd <= e_rd;
	    m_rw <= e_opcode == 7'b0100011;
	    m_size_encoded <= e_funct3[1:0];
	    m_address <= e_alu_res;
	    m_rs2_data <= e_alu_opr2;
	    m_is_unsigned <= e_funct3[2];
	    m_opcode <= e_opcode;
	    m_rs1 <= e_rs1;
	    m_rs2 <= e_rs2;
	    m_alu_res <= e_alu_res;
        end
    end
    
    assign m_data = m_use_wm ? w_data : m_rs2_data;

    dmemory dmemory(
	.clock(clock),
	.address(m_address),
	.data_in(m_data),
	.access_size(m_size_encoded),
	.read_write(m_rw),
	.data_out(w_data_out)
    );


    // -----------WRITEBACK-------------

    reg [31:0] w_pc;
    wire w_enable;
    reg [4:0] w_destination;
    reg [31:0] w_data;
    reg [6:0] w_opcode;
    reg [31:0] w_alu_res;
    wire [31:0] w_data_out;
    reg [4:0] w_rs1;
    reg [1:0] w_size_encoded;
    reg w_is_unsigned;

    assign r_write_enable = w_enable;
    assign r_write_data = w_data;
    assign r_write_destination = w_destination;

    always @ (posedge clock) begin
	if (reset) begin
	    w_opcode <= 7'b0010011;
	    w_destination <= 5'b0;
	end else begin
	    w_pc <= m_pc;
	    w_destination <= m_rd;
	    w_opcode <= m_opcode;
	    w_alu_res <= m_alu_res;
	    w_rs1 <= m_rs1;
	    w_size_encoded <= m_size_encoded;
	    w_is_unsigned <= m_is_unsigned;
	end
    end

    assign w_enable = (
        w_opcode == 7'b0000011 || // Load instructions
	w_opcode == 7'b0010011 || // I-type ALU instructions
	w_opcode == 7'b0010111 || // AUIPC
	w_opcode == 7'b0110111 || // LUI
	w_opcode == 7'b1101111 || // JAL
	w_opcode == 7'b1100111 || // JALR
	w_opcode == 7'b0110011    // R-type
    );

    always @ (*) begin
	if (
	    w_opcode == 7'b0010011 || // I-type ALU instructions
	    w_opcode == 7'b0110011 || // R-type
	    w_opcode == 7'b0010111 || // AUIPC
	    w_opcode == 7'b0110111    // LUI
        ) begin
	    w_data = w_alu_res;
	end else if (w_opcode == 7'b0000011) begin // Load instructions
	    if (w_is_unsigned) begin
                w_data = w_data_out;
	    end else begin
		if (w_size_encoded == 2'b00) begin
		    w_data = { {24{w_data_out[7]}}, w_data_out[7:0] };
		end else if (w_size_encoded == 2'b01) begin
		    w_data = { {16{w_data_out[15]}}, w_data_out[15:0] };
		end else begin
		    w_data = w_data_out;
		end
	    end
	end else if (
	    w_opcode == 7'b1101111 || // JAL
	    w_opcode == 7'b1100111    // JALR
        ) begin
	    w_data = w_pc + 4;
        end else begin
            w_data = 32'b0;
	end
    end
    

endmodule
