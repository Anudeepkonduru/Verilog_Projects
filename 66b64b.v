module gbx_66b64b(input clk,
        input rstn,
        input [65:0] tx_in,
        output [63:0] tx_out,
        output tx_pause);

reg [63:0] tx_out_reg;
reg tx_pause_reg;
reg [129:0] merge;

//After 32 cycles, insert wait state in 33rd 
//cycle to send the residue
reg [6:0] fill; 
reg [5:0] count;

always @ (posedge clk or negedge rstn)
begin
if (!rstn)
        begin
        tx_out_reg <= 64'b0;
        tx_pause_reg <= 1'b0;
        merge <= 130'b0;
        fill <= 7'b0;
        count <= 6'b0;
        end else begin
                tx_out_reg <= merge [129:66];
                if (count == 6'd32) begin
                        tx_pause_reg <= 1'b0;
                        count <= 6'b0;
                        fill <= 7'd0;
                        merge <= merge << 64; end
                 else begin
                        tx_pause_reg <= (count == 6'd31);
                        count <= count + 1'b1;
                        merge <= (merge << 64) | ({tx_in,64'b0} >> fill);
                        fill <= fill + 6'd2;  end
                end
end

assign tx_out = tx_out_reg;
assign tx_pause = tx_pause_reg;

endmodule