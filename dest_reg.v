module dest_reg(clk,rst,index_in,w_en,data_out,data_in,r_en);
  parameter I_WIDTH = 4;
  parameter D_WIDTH = 16; 
  input clk;
  input rst;
  input w_en;
  input r_en;
  input[I_WIDTH-1:0] index_in;
  input[D_WIDTH-1:0] data_in;
  output reg[D_WIDTH-1:0] data_out;
  reg[D_WIDTH-1:0] mem [2**I_WIDTH-1:0];
  always @(posedge clk or negedge rst)
  begin
    if (!rst)
      data_out <= 0;
    else 
      begin
        if (r_en) // if you want to read data, set the r_en
          data_out <= mem[index_in];
        else data_out <= 16'bZ;
      end
  end
  
  always @(posedge clk)
  begin
    if (w_en)
      mem[index_in] <= data_in;
  end
endmodule
  
