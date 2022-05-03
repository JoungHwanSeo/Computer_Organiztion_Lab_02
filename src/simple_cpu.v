// simple_cpu.v
// a pipelined RISC-V microarchitecture (RV32I)

///////////////////////////////////////////////////////////////////////////////////////////
//// [*] In simple_cpu.v you should connect the correct wires to the correct ports
////     - All modules are given so there is no need to make new modules
////       (it does not mean you do not need to instantiate new modules)
////     - However, you may have to fix or add in / out ports for some modules
////     - In addition, you are still free to instantiate simple modules like multiplexers,
////       adders, etc.
///////////////////////////////////////////////////////////////////////////////////////////

module simple_cpu
#(parameter DATA_WIDTH = 32)(
  input clk,
  input rstn
);

///////////////////////////////////////////////////////////////////////////////
// TODO:  Declare all wires / registers that are needed
///////////////////////////////////////////////////////////////////////////////
// e.g., wire [DATA_WIDTH-1:0] if_pc_plus_4;

wire stopclk;  ///latching위한 signal!!!

// wire realclk;  //PC, IF/ID , ID/EX에 들어가는 clk

// assign realclk = (stopclk) ? 0 : clk; ///////디버깅시 이거 작동 체크!!!!!!


wire [DATA_WIDTH-1:0] IF_PC_PLUS_4;  //IF에서 PC+4값을 저장할 곳
wire [DATA_WIDTH-1:0] IF_instruction; //일단 예측된 PC에서 바로 나온 instruction
wire [DATA_WIDTH-1:0] IF_PC; //이는 사실상 그냥 PC와 같음

wire [DATA_WIDTH-1:0] ID_PC;
wire [DATA_WIDTH-1:0] ID_PC_PLUS_4;
wire [DATA_WIDTH-1:0] ID_instruction;
wire [DATA_WIDTH-1:0] ID_imm;

////////////////////////////////////single 복붙
////////////////////////////////////
/////////////////////////////////////


// from register file 
// wire [31:0] rs1_out, rs2_out;
// wire [31:0] alu_out;

// 5 bits for each (because there exist 32 registers)
wire [4:0] ID_rs1, ID_rs2, ID_rd;
// wire [4:0] MEM_rs1, MEM_rs2, MEM_rd;
// wire [4:0] WB_rs1, WB_rs2, WB_rd;  //여기까지 필요할까 싶지만.... 필요 없으면 나중에 지워~!

wire [DATA_WIDTH-1:0] ID_sextimm;

wire [6:0] ID_opcode;
wire [6:0] ID_funct7;
wire [2:0] ID_funct3;

wire [31:0] ID_readdata1, ID_readdata2;

// instruction fields
assign ID_opcode = ID_instruction[6:0];

assign ID_funct7 = ID_instruction[31:25];
assign ID_funct3 = ID_instruction[14:12];

// R type
assign ID_rs1 = ID_instruction[19:15];
assign ID_rs2 = ID_instruction[24:20];
assign ID_rd  = ID_instruction[11:7];

/* m_control: control unit */
wire ID_branch;
wire ID_mem_read;
wire ID_mem_to_reg;
wire [1:0] ID_alu_op;
wire ID_mem_write;
wire ID_alu_src;
wire ID_reg_write;
wire [1:0] ID_jump;

wire ID_mem_write_tmp; // 선언 for hazard
wire ID_reg_write_tmp;

////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////single 복붙

///EX stage필요 wire
wire [DATA_WIDTH-1:0] EX_PC;
wire [DATA_WIDTH-1:0] EX_PC_PLUS_4;

wire EX_branch;
wire [1:0] EX_aluop;
wire EX_alusrc;
wire [1:0] EX_jump;

wire EX_memread;
wire EX_memwrite;

wire EX_memtoreg;
wire EX_regwrite;

wire [DATA_WIDTH-1:0] EX_sextimm;
wire [6:0] EX_funct7;
wire [2:0] EX_funct3;
wire [DATA_WIDTH-1:0] EX_readdata1;
wire [DATA_WIDTH-1:0] EX_readdata2;
wire [4:0] EX_rs1;
wire [4:0] EX_rs2;
wire [4:0] EX_rd;
wire [6:0] EX_opcode;  //추가됨!!!

wire [1:0] EX_ForwardA;
wire [1:0] EX_ForwardB;


wire [DATA_WIDTH-1:0] EX_ALU_result;
wire EX_check;
wire EX_taken;
wire [DATA_WIDTH-1:0] EX_PC_branch_target;
wire [3:0] EX_ALU_func;
wire [DATA_WIDTH-1:0] EX_ALU_in; //mux선택결과 ALU에 들어가는 값

wire [DATA_WIDTH-1:0] EX_Writedata; //rs2값
//MEM stage 필요 wire
wire [DATA_WIDTH-1:0] MEM_PC_PLUS_4;
wire [DATA_WIDTH-1:0] MEM_PC_target;
wire MEM_taken;
wire MEM_memread;
wire MEM_memwrite;
wire [1:0] MEM_jump;
wire MEM_memtoreg;
wire MEM_regwrite;
wire [DATA_WIDTH-1:0] MEM_alu_result;
wire [DATA_WIDTH-1:0] MEM_writedata;
wire [2:0] MEM_funct3;
wire [4:0] MEM_rd;

wire [6:0] MEM_opcode; //추가됨!!!

/////////////////WB필요 wire
wire[DATA_WIDTH-1:0] WB_PC_PLUS_4;

wire [1:0] WB_jump;
wire WB_memtoreg;
wire WB_regwrite;

wire [DATA_WIDTH-1:0] WB_readdata;
wire [DATA_WIDTH-1:0] WB_alu_result;
wire [4:0] WB_rd;

reg [DATA_WIDTH-1:0] WB_write_data;
wire [DATA_WIDTH-1:0] WB_tmp_write_data;

wire [6:0] WB_opcode; //추가됨!!!
/////////////////////////

// 1) Pipeline registers (wires to / from pipeline register modules)
// 2) In / Out ports for other modules
// 3) Additional wires for multiplexers or other mdoules you instantiate

///////////////////////////////////////////////////////////////////////////////
// Instruction Fetch (IF)
///////////////////////////////////////////////////////////////////////////////

reg [DATA_WIDTH-1:0] PC;    // program counter (32 bits)

assign IF_PC = PC; //사실상 그냥 PC임

wire [DATA_WIDTH-1:0] NEXT_PC;

/* m_next_pc_adder */
adder m_pc_plus_4_adder(
  .in_a   (4),
  .in_b   (PC),

  .result (IF_PC_PLUS_4)
);


////원래이거
// always @(posedge clk) begin
//   if (rstn == 1'b0) begin
//     PC <= 32'h00000000;
//   end
//   else PC <= NEXT_PC;
// end

always @(posedge clk) begin
  if (rstn == 1'b0) begin
    PC <= 32'h00000000;
    // stopclk <= 0; //stall signal 초기화!!!
  end
  else begin
    if(!stopclk) begin
      PC <= NEXT_PC;
    end
    else begin
      PC <= PC;
    end
  end
  // else if(stopclk) begin
  //   PC <= PC;  //latching
  // end
  // else begin
  //   PC <= NEXT_PC;
  // end
end

////////나중에 고쳐야함!!!!!///control hazard해결해야해서...
// assign NEXT_PC = IF_PC_PLUS_4;
///////나중에 고쳐야함!!!!!

wire [DATA_WIDTH-1:0] IF_instruction_tmp; //추가 선언
/* instruction: read current instruction from inst mem */
instruction_memory m_instruction_memory(
  .address    (PC),

  .instruction(IF_instruction_tmp)
);

/* forward to IF/ID stage registers */
ifid_reg m_ifid_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .if_PC          (IF_PC),
  .if_pc_plus_4   (IF_PC_PLUS_4),
  .if_instruction (IF_instruction),

  .stopclk        (stopclk),  //추가

  .id_PC          (ID_PC),
  .id_pc_plus_4   (ID_PC_PLUS_4),
  .id_instruction (ID_instruction)
);


//////////////////////////////////////////////////////////////////////////////////
// Instruction Decode (ID)
//////////////////////////////////////////////////////////////////////////////////

///////////////Load stall위해 임시 wire 추가////////////////
wire EX_memwrite_tmp;
wire EX_regwrite_tmp;
////////////////////////////////////////////////////////

/* m_hazard: hazard detection unit */
hazard m_hazard(
  // TODO: implement hazard detection unit & do wiring

  /////////////////input/////////////////
  .ex_alu_result(EX_ALU_result),
  .ex_branch_target(EX_PC_branch_target),
  .ex_branch_taken(EX_taken),
  .ex_jump(EX_jump),
  .if_pc_plus_4(IF_PC_PLUS_4),
  .id_mem_write(ID_mem_write_tmp), ///
  .id_reg_write(ID_reg_write_tmp), ///
  .if_instruction(IF_instruction_tmp),

  //Load stall위한 input
  .mem_opcode(MEM_opcode),
  .ex_rs1(EX_rs1),
  .ex_rs2(EX_rs2),
  .mem_rd(MEM_rd),
  .ex_opcode(EX_opcode),
  .ex_memwrite(EX_memwrite_tmp),
  .ex_regwrite(EX_regwrite_tmp),

  .rstn(rstn),

  .clk(clk),

  /////////////////output//////////////
  .NEXT_PC(NEXT_PC),
  .id_mem_write_real(ID_mem_write),
  .id_reg_write_real(ID_reg_write),
  .if_instruction_real(IF_instruction),

  //Load stall위한 output
  .stopclk(stopclk),
  .ex_memwrite_real(EX_memwrite),
  .ex_regwrite_real(EX_regwrite)
);

/* m_control: control unit */
//control signal을 ID단계에서 추출

// wire ID_mem_write_tmp; // 선언 for hazard
// wire ID_reg_write_tmp;

control m_control(
  .opcode(ID_opcode),

  .jump(ID_jump),
  .branch(ID_branch),
  .mem_read(ID_mem_read),
  .mem_to_reg(ID_mem_to_reg),
  .alu_op(ID_alu_op),
  .mem_write(ID_mem_write_tmp),
  .alu_src(ID_alu_src),
  .reg_write(ID_reg_write_tmp)
);

/* m_imm_generator: immediate generator */
immediate_generator m_immediate_generator(
  .instruction(ID_instruction),

  .sextimm    (ID_sextimm)
);

/* m_register_file: register file */
register_file m_register_file(
  .clk        (clk),
  .readreg1   (ID_rs1),
  .readreg2   (ID_rs2),
  .writereg   (WB_rd),  //여기에는 WB_rd가 들어와야 할듯
  .wen        (WB_regwrite),
  .writedata  (WB_write_data),

  .readdata1  (ID_readdata1),
  .readdata2  (ID_readdata2)
);

/* forward to ID/EX stage registers */
idex_reg m_idex_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk          (clk),
  .stopclk      (stopclk),

  .id_PC        (ID_PC),
  .id_pc_plus_4 (ID_PC_PLUS_4),
  .id_jump      (ID_jump),
  .id_branch    (ID_branch),
  .id_aluop     (ID_alu_op),
  .id_alusrc    (ID_alu_src),
  .id_memread   (ID_mem_read),
  .id_memwrite  (ID_mem_write),
  .id_memtoreg  (ID_mem_to_reg),
  .id_regwrite  (ID_reg_write),
  .id_sextimm   (ID_sextimm),
  .id_funct7    (ID_funct7),
  .id_funct3    (ID_funct3),
  .id_readdata1 (ID_readdata1),
  .id_readdata2 (ID_readdata2),
  .id_rs1       (ID_rs1),
  .id_rs2       (ID_rs2),
  .id_rd        (ID_rd),
  .id_opcode    (ID_opcode),  ///내가 추가!!!

  .ex_PC        (EX_PC),
  .ex_pc_plus_4 (EX_PC_PLUS_4),
  .ex_jump      (EX_jump),
  .ex_branch    (EX_branch),
  .ex_aluop     (EX_aluop),
  .ex_alusrc    (EX_alusrc),
  .ex_memread   (EX_memread),
  .ex_memwrite  (EX_memwrite_tmp), ///고침
  .ex_memtoreg  (EX_memtoreg),
  .ex_regwrite  (EX_regwrite_tmp),  //고침
  .ex_sextimm   (EX_sextimm),
  .ex_funct7    (EX_funct7),
  .ex_funct3    (EX_funct3),
  .ex_readdata1 (EX_readdata1),
  .ex_readdata2 (EX_readdata2),
  .ex_rs1       (EX_rs1),
  .ex_rs2       (EX_rs2),
  .ex_rd        (EX_rd),
  .ex_opcode    (EX_opcode)  ///내가 추가!!!
);

//////////////////////////////////////////////////////////////////////////////////
// Execute (EX) 
//////////////////////////////////////////////////////////////////////////////////

/* m_branch_target_adder: PC + imm for branch address */
adder m_branch_target_adder(
  .in_a   (EX_PC),
  .in_b   (EX_sextimm), 

  .result (EX_PC_branch_target)
);
//이걸로 JAL과 Branch까지는 커버 가능 , JALR은 따로 커버해야함
//JALR의 경우 ALU_result가 PC target임!!!!!!!

/* m_branch_control : checks T/NT */
branch_control m_branch_control(
  .branch (EX_branch),
  .check  (EX_check),
  
  .taken  (EX_taken)
);

// reg [DATA_WIDTH-1:0] EX_target_PC;

// always@(*) begin
//   case(EX_jump) 
//     2'b01: EX_target_PC = EX_PC_branch_target;
//     2'b10: EX_target_PC = ALU_result여야함
// end

/* alu control : generates alu_func signal */
alu_control m_alu_control(
  .alu_op   (EX_aluop),
  .funct7   (EX_funct7),
  .funct3   (EX_funct3),

  .alu_func (EX_ALU_func)
);

///최종적으로 alu에 들어갈 wire Forwarding구현하면서 추가하였음
wire [DATA_WIDTH-1:0] alu_in_1;
wire [DATA_WIDTH-1:0] alu_in_2;
/////////////////////////////////////////////////////////////

/* m_alu */
alu m_alu(
  .alu_func (EX_ALU_func),
  .in_a     (alu_in_1), 
  .in_b     (alu_in_2), 

  .result   (EX_ALU_result),
  .check    (EX_check)
);

//imm선택할지 rs2 선택할지 mux!
mux_2x1 m_alu_mux( 
    .select(EX_alusrc),  //EX_alu_src대신 alu_src...ㅋㅋㅋㅋㅋㅋ
    .in1(EX_readdata2),
    .in2(EX_sextimm),

    .out(EX_ALU_in)
);


mux_3x1 alu_in_1_mux(
  .select(EX_ForwardA),
  .in1(EX_readdata1),
  .in2(MEM_alu_result),
  .in3(WB_write_data),  //WB_alu_result -> WB_write_data로 Load까지 cover가능

  .out(alu_in_1)
);

mux_3x1 alu_in_2_mux(
  .select(EX_ForwardB),
  .in1(EX_ALU_in),
  .in2(MEM_alu_result),
  .in3(WB_write_data),  

  .out(alu_in_2)
);


forwarding m_forwarding(
  // TODO: implement forwarding unit & do wiring
  //input
  .ex_rs1     (EX_rs1),
  .ex_rs2     (EX_rs2),
  .mem_rd     (MEM_rd),
  .wb_rd      (WB_rd),
  .mem_opcode (MEM_opcode),
  .wb_opcode  (WB_opcode),

  //output
  .forwardA   (EX_ForwardA),
  .forwardB   (EX_ForwardB)
);

/* forward to EX/MEM stage registers */
exmem_reg m_exmem_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .ex_pc_plus_4   (EX_PC_PLUS_4),
  .ex_pc_target   (EX_PC_branch_target),
  .ex_taken       (EX_taken), 
  .ex_jump        (EX_jump),
  .ex_memread     (EX_memread),
  .ex_memwrite    (EX_memwrite),
  .ex_memtoreg    (EX_memtoreg),
  .ex_regwrite    (EX_regwrite),
  .ex_alu_result  (EX_ALU_result),
  .ex_writedata   (EX_readdata2),  //rs2가 writedata
  ///////write data jump인 경우 PC+4.... 어디서 이를 mux 해줘야..
  .ex_funct3      (EX_funct3),
  .ex_rd          (EX_rd),

  .ex_opcode      (EX_opcode),
  
  .mem_pc_plus_4  (MEM_PC_PLUS_4),
  .mem_pc_target  (MEM_PC_target),
  .mem_taken      (MEM_taken), 
  .mem_jump       (MEM_jump),
  .mem_memread    (MEM_memread),
  .mem_memwrite   (MEM_memwrite),
  .mem_memtoreg   (MEM_memtoreg),
  .mem_regwrite   (MEM_regwrite),
  .mem_alu_result (MEM_alu_result),
  .mem_writedata  (MEM_writedata),
  .mem_funct3     (MEM_funct3),
  .mem_rd         (MEM_rd),

  .mem_opcode     (MEM_opcode)
);


//////////////////////////////////////////////////////////////////////////////////
// Memory (MEM) 
//////////////////////////////////////////////////////////////////////////////////

reg [1:0]maskmode;
reg sext;

//sext와 maskmode얻기 위한 logic 
//어차피 메모리에 접근하는 명령어는 Load/Store로 한정되어 있음
always@(*) begin
  case (MEM_funct3) //store도 동시에 커버 가능함
  3'b000: begin  //Load byte
    maskmode = 2'b00;
    sext = 1'b0;
  end
  3'b001: begin  //Load half-word
    maskmode = 2'b01;
    sext = 1'b0;
  end
  3'b010: begin  //Load word
    maskmode = 2'b10;
  end
  3'b100: begin //Load unsigned byte
    maskmode = 2'b00;
    sext = 1'b1; 
  end
  3'b101: begin //Load unsigned half-word
    maskmode = 2'b01;
    sext = 1'b1;
  end
  default: begin //이런 input은 없겠지만...
    maskmode = 2'b00;
    sext = 1'b0;
  end
endcase
end

wire [DATA_WIDTH-1:0] MEM_mem_read_data; //데이터 읽은 값

/* m_data_memory : main memory module */
data_memory m_data_memory(
  .clk         (clk),
  .address     (MEM_alu_result),
  .write_data  (MEM_writedata),
  .mem_read    (MEM_memread),
  .mem_write   (MEM_memwrite),
  .maskmode    (maskmode),
  .sext        (sext),

  .read_data   (MEM_mem_read_data)
);

// /////////////////WB필요 wire
// wire[DATA_WIDTH-1:0] WB_PC_PLUS_4;

// wire [1:0] WB_jump;
// wire WB_memtoreg;
// wire WB_regwrite;

// wire [DATA_WIDTH-1:0] WB_readdata;
// wire [DATA_WIDTH-1:0] WB_alu_result;
// wire [4:0] WB_rd;

// wire [DATA_WIDTH-1:0] WB_write_data;
// wire [DATA_WIDTH-1:0] WB_tmp_write_data;
// /////////////////////////


/* forward to MEM/WB stage registers */
memwb_reg m_memwb_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .mem_pc_plus_4  (MEM_PC_PLUS_4),
  .mem_jump       (MEM_jump),
  .mem_memtoreg   (MEM_memtoreg),
  .mem_regwrite   (MEM_regwrite),
  .mem_readdata   (MEM_mem_read_data), //이거랑 alu_result랑 mux해야함
  .mem_alu_result (MEM_alu_result),
  .mem_rd         (MEM_rd),

  .mem_opcode     (MEM_opcode), //추가됨

  .wb_pc_plus_4   (WB_PC_PLUS_4),
  .wb_jump        (WB_jump),  //이거 써서 register update값 조절!!!!!!
  .wb_memtoreg    (WB_memtoreg),
  .wb_regwrite    (WB_regwrite),
  .wb_readdata    (WB_readdata),
  .wb_alu_result  (WB_alu_result),
  .wb_rd          (WB_rd),

  .wb_opcode      (WB_opcode)
);


//이거 순서가 잘 되는지 확인해야.... 이상하면 여기도 한번 보기!!!!!!!
//write data가 잘 되는지........ block/nonblock
mux_2x1 m_mux_2x1(
  .select(WB_memtoreg),
  .in1(WB_alu_result),
  .in2(WB_readdata),

  .out(WB_tmp_write_data) //최종적으로 update되는 data
);

//write data jump도 고려해줘야함!!!!!!!
always@(*) begin
  case(WB_jump)  //EX_jump -> WB_jump....실화냐 이런 실수를...
    2'b00 : WB_write_data = WB_tmp_write_data;
    2'b01 : WB_write_data = WB_tmp_write_data; //branch인 경우인데 이는 어차피 update안됨. 아무거나 넣어줌
    2'b10 : WB_write_data = WB_PC_PLUS_4; //jump
    2'b11 : WB_write_data = WB_PC_PLUS_4; //jump
  endcase
end

//////////////////////////////////////////////////////////////////////////////////
// Write Back (WB) 
//////////////////////////////////////////////////////////////////////////////////


endmodule
