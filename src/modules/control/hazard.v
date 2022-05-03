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

    //Load stall위한 input
    input [6:0] mem_opcode,
    input [4:0] ex_rs1,
    input [4:0] ex_rs2,
    input [4:0] mem_rd,

    input [6:0] ex_opcode,
    input ex_memwrite,
    input ex_regwrite, //load추가 후 control쪽에도 이들 추가해줘야함

    input rstn,      //초기 stopclk값 문제때문에 추가....

    input clk,


    ////////////////////output///////////////////////
    output reg [DATA_WIDTH-1:0] NEXT_PC,
    //branch나 jump일어나는 경우 이 contorl signal을 0으로
    output reg id_mem_write_real,
    output reg id_reg_write_real,
    output reg [DATA_WIDTH-1:0] if_instruction_real, //add x0 x0 x0넣음
    // 32'b0000000_00000_00000_000_00000_0110011

    //Load stall위한 output
    output reg stopclk, // PC, ID/IF , IF/EX register를 latching하기 위해, stopclk이 1이면 clk에 0넣어주고, 0이면 clk에 원래 clk넣어줌

    output reg ex_memwrite_real,
    output reg ex_regwrite_real //load추가 후 control쪽에도 이들 추가해줘야함!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    //생각해보니 나머지는 control쪽에서 담당하고 이 output은 stall에서만 담당해도 되는 것 같은데???
);


reg stopclk_1;
reg stopclk_2;
///////////////////////////Load data forwarding, Stall//////////////

reg done;  //추가

//NEXT_PC의 경우 애초에 이 Hazard 모듈에서 나오고, input이 MEM stage까지 있으므로 IF/ID, ID/EX latching하면 NEXT_PC는 고정될것
always@(posedge clk) begin
    done <= 0;
end

always@(*) begin
    if(mem_opcode == 7'b0000011 && ex_rs1 == mem_rd && ex_rs1 != 0 && ex_opcode != 7'b1101111 && done == 0) begin
        //이 경우는 forwarding과 다르게 rs1,2를 실제 사용하는지 여부도 중요함... cycle을 낭비할 수 있기 때문임
        //rs1을 사용하지 않는 경우는 JAL인 경우! =>rs2의 경우 I-type와 JALR도 사용하지 않음
        ///MEM 단계가 load이고, EX의 rs1이 rd와 같고, x0가 아니면 stall해야함
        //MEM은 계속 진행되어 한 사이클 뒤에 Data forwarding 모듈이 EX-WB관계를 캐치해서 ALU에 해당 데이터 forwarding 해줄것

        //근데 진짜 만약에 ex_rs1이랑 ex_rd가 같고 ex_opcode가 Load이면 무한 stall이 되는 것 아닌가??????????
        //ex가 control signal만 0이 되어 MEM으로 들어가는거니까... 이건 나중에 생각해!!!!!!

        ex_memwrite_real = 0;
        ex_regwrite_real = 0;
        stopclk_1 = 1; ///?????????????????? clk은 어떻게 해야하지????????
        done = 1;
    end
    else begin
        ex_memwrite_real = ex_memwrite;
        ex_regwrite_real = ex_regwrite;
        stopclk_1 = 0;////????????????????????????????????????????????????????????????????????????????????
    end

    if(mem_opcode == 7'b0000011 && ex_rs2 == mem_rd && ex_rs2 != 0 && ex_opcode != 7'b1101111 && ex_opcode != 7'b0010011 && ex_opcode !=7'b1100111) begin
        //rs2의 경우 I type도 rs2를 사용하지 않으므로 만약 I type이고, rs2와 MEM의 rd같으면 굳이 stall할 필요 없음!
        //게다가 JALR도 rs2사용하지 않으므로 이것까지 빼줘야함!!!
        ///MEM 단계가 load이고, EX의 rs1이 rd와 같고, x0가 아니면 stall해야함
        //MEM은 계속 진행되어 한 사이클 뒤에 Data forwarding 모듈이 캐치해서 ALU에 해당 데이터 forwarding 해줄것
        ex_memwrite_real = 0;
        ex_regwrite_real = 0;
        stopclk_2 = 1; ///?????????????????? clk은 어떻게 해야하지????????
    end
    else begin
        ex_memwrite_real = ex_memwrite;
        ex_regwrite_real = ex_regwrite;
        stopclk_2 =0;////????????????????????????????????????????????????????????????????????????????????
    end
end

always@(*) begin
    if(rstn == 1'b0) begin
        stopclk = 0;
        done=0;  ///추가
    end
    else begin
        if(stopclk_1 | stopclk_2 == 1'b1) begin
            stopclk = 1;
        end
        else begin
            stopclk = 0;
        end
    end
end


////////////////////////////control hazard, flush/////////////////////////
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
