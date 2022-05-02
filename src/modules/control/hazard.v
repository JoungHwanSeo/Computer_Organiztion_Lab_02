// hazard.v

// This module determines if pipeline stalls or flushing are required

// TODO: declare propoer input and output ports and implement the
// hazard detection unit

module hazard
#(parameter DATA_WIDTH = 32) (
    /////////////////input//////////////////
    input [DATA_WIDTH-1:0] ex_alu_result, //JALR의 경우...
    input [DATA_WIDTH-1:0] ex_branch_target, // PC + sext(imm)으로 branch/JAL커버가능
    input ex_branch_taken,
    input [1:0] ex_jump,
    input [DATA_WIDTH-1:0] if_pc_plus_4,

    //id에 있는 명령어 flush하기 위함
    input id_mem_write,
    input id_reg_write,

    input [DATA_WIDTH-1:0] if_instruction,

    ////////////////////output///////////////////////
    output reg [DATA_WIDTH-1:0] NEXT_PC,
    //branch나 jump일어나는 경우 이 contorl signal을 0으로
    output reg id_mem_write_real,
    output reg id_reg_write_real,
    output reg [DATA_WIDTH-1:0] if_instruction_real //add x0 x0 x0넣음
    // 32'b0000000_00000_00000_000_00000_0110011
);

always@(*) begin
    case(ex_jump)
        2'b01: begin //branch
            if(ex_branch_taken == 1) begin
                NEXT_PC = ex_branch_target;
                id_mem_write_real = 0;
                id_reg_write_real = 0;
                if_instruction_real = 32'b0000000_00000_00000_000_00000_0110011;
            end
            else begin
                NEXT_PC = if_pc_plus_4;  //branch가 taken이 아닌경우
                id_mem_write_real = id_mem_write;
                id_reg_write_real = id_reg_write;
                if_instruction_real = if_instruction;
            end
        end 
        2'b11:begin //JAL
            NEXT_PC = ex_branch_target;
            id_mem_write_real = 0;
            id_reg_write_real = 0;
            if_instruction_real = 32'b0000000_00000_00000_000_00000_0110011;
        end
        2'b10:begin
            NEXT_PC = ex_alu_result;
            id_mem_write_real = 0;
            id_reg_write_real = 0;
            if_instruction_real = 32'b0000000_00000_00000_000_00000_0110011;
        end
        default: begin
            NEXT_PC = if_pc_plus_4; // branch, jump아닌경우
            id_mem_write_real = id_mem_write;
            id_reg_write_real = id_reg_write;
            if_instruction_real = if_instruction;
        end
    endcase
end

endmodule
