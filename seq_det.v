module seq_detector(input wire seq, 
        input wire clk,
        input wire rstn,
        output wire det);

reg [1:0] state, nxt_state;

localparam [1:0] s0 = 2'b00;
localparam [1:0] s1 = 2'b01;
localparam [1:0] s2 = 2'b10;
localparam [1:0] s3 = 2'b11;

always @ (posedge clk or negedge rstn)
begin
    if (!rstn)
        state <= 2'b0;
    else 
        state <= nxt_state;
end

always @ (*)
begin
        nxt_state = 2'b0;
        case (state)
            s0: nxt_state = seq ? s1 : s0;
            s1: nxt_state = seq ? s1 : s2;
            s2: nxt_state = seq ? s3 : s0;
            s3: nxt_state = seq ? s1 : s2;
            default : nxt_state = s0;
        endcase
end

assign det = (state == s3) && seq ;

endmodule