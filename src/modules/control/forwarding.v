// forwarding.v

// This module determines if the values need to be forwarded to the EX stage.

// TODO: declare propoer input and output ports and implement the
// forwarding unit

module forwarding (
    input [4:0] ex_rs1,
    input [4:0] ex_rs2,
    input [4:0] mem_rd,
    input [4:0] wb_rd,
    input [6:0] mem_opcode,//opcode도 계속 pipeline해야하나...
    input [6:0] wb_opcode,

    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);

/////////////Load의 경우????????

always@(*) begin
    ///////////////////////rs1///////////////////////
    if(ex_rs1 == mem_rd && ex_rs1 != 0 && mem_opcode != 7'b1100011 && mem_opcode !=7'b0100011 && mem_opcode != 7'b0000011) begin
        //ALU에 들어갈 rs1이 뒤의 rd와 같고, rs1이 x0가 아니고, mem이 Store, Branch아니면(No Write), 그리고 Load아니면 [거리 1]
        forwardA = 2'b01; //Mem에서 Hazard..
    end
    else if(ex_rs1 == wb_rd && ex_rs1 != 0 && wb_opcode != 7'b1100011 && wb_opcode !=7'b0100011) begin
        //이 경우 거리가 2로 load아니라는 조건 필요 없음
        forwardA = 2'b10; //WB에서 hazard 
    end
    else begin
        forwardA = 2'b00;
    end

    ////////////////////////rs2////////////////////////////
    if(ex_rs2 == mem_rd && ex_rs2 != 0 && mem_opcode != 7'b1100011 && mem_opcode !=7'b0100011 && mem_opcode != 7'b0000011) begin
        //ALU에 들어갈 rs2가 뒤의 rd와 같고, rs1이 x0가 아니고, mem이 Store, Branch아니면(No Write), 그리고 Load아니면 [거리 1]
        forwardB = 2'b01; //Mem에서 Hazard..
    end
    else if(ex_rs2 == wb_rd && ex_rs2 != 0 && wb_opcode != 7'b1100011 && wb_opcode !=7'b0100011) begin
        forwardB = 2'b10; //WB에서 hazard
    end
    else begin
        forwardB = 2'b00;
    end

end

endmodule
