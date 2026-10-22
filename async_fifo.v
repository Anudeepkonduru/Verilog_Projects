module async_fifo #(parameter AW = 12, DW = 32)
                  ( input wclk,
                    input wrstn,
                    input wen,
                    input [DW-1:0] wdata,
                    input rclk,
                    input rrstn,
                    input ren,
                    output reg [DW-1:0] rdata,
                    output reg  full,
                    output reg empty);

reg sync_wrstn, wrstn_q, sync_rrstn, rrstn_q; //reset sync regs

reg [DW-1:0] ram [(1<<AW)-1:0];       // memory  declaration

//pointers are AW sized to accommodate simultaneous writes and reads
reg [AW:0] wbin, rbin;            // binary pointers
wire [AW:0] wbin_nxt, rbin_nxt;
reg [AW:0] wgry, rgry;              // gray pointers
wire [AW:0] wgry_nxt, rgry_nxt;

reg [AW:0] wck_rptr1, wck_rptr2;    // Synchronized gray pointers
reg [AW:0] rck_wptr1, rck_wptr2;

wire wfull_val, rempty_val;

//write domain

//async reset and sync release
always @ (posedge wclk or negedge wrstn)
begin
    if (!wrstn)
        {sync_wrstn, wrstn_q} <= 0;
    else 
        {sync_wrstn, wrstn_q} <= {wrstn_q, 1'b1};
end

//Syncing read pointers into write domain
always @ (posedge wclk or negedge sync_wrstn)
begin
    if (!sync_wrstn)
        {wck_rptr2, wck_rptr1} <= 0;
    else 
        {wck_rptr2, wck_rptr1} <= {wck_rptr1, rgry};
end

assign wbin_nxt = wbin + {{AW{1'b0}}, wen && ~full};
assign wgry_nxt = (wbin_nxt >> 1) ^ wbin_nxt;

assign wfull_val = (wgry_nxt == {~wck_rptr2[AW:AW-1], 
                                            wck_rptr2[AW-2:0]});

always @ (posedge wclk or negedge sync_wrstn)
begin
    if (!sync_wrstn)
    begin
        wbin <= 'b0;
        wgry <= 'b0;
        full <= 'b1;  //full resets to 1
    end else 
    begin
        wbin <= wbin_nxt;
        wgry <= wgry_nxt;
        full <= wfull_val;
    end
end

always @ (posedge wclk)
begin
    if (wen && ~full)
        ram [wbin[AW-1:0]] <= wdata;
end

//read domain

//async reset and sync release
always @ (posedge rclk or negedge rrstn)
begin
    if (!rrstn)
        {sync_rrstn, rrstn_q} <= 0;
    else 
        {sync_rrstn, rrstn_q} <= {rrstn_q, 1'b1};
end

always @ (posedge rclk or negedge sync_rrstn)
begin
    if (!sync_rrstn)
        {rck_wptr2, rck_wptr1} <= 0;
    else 
        {rck_wptr2, rck_wptr1} <= {rck_wptr1, wgry};
end

assign rbin_nxt = rbin + {{AW{1'b0}}, ren && ~empty};
assign rgry_nxt = (rbin_nxt >> 1) ^ rbin_nxt;

assign rempty_val = (rgry_nxt == rck_wptr2);

always @ (posedge rclk or negedge sync_rrstn)
begin
    if (!sync_rrstn)
    begin
        rbin <= 'b0;
        rgry <= 'b0;
        empty <= 'b1;       // Empty resets to 1
    end else 
    begin
        rbin <= rbin_nxt;
        rgry <= rgry_nxt;
        empty <= rempty_val;
    end
end

always @ (posedge rclk) //FWFT
begin
        rdata <= ram[rbin_nxt[AW-1:0]];
end

endmodule