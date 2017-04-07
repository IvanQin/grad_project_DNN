module ReLU(clk,rst,data_in,data_out);
  parameter D_WIDTH = 16;
  input clk;
  input rst;
  input [D_WIDTH-1:0] data_in;
  output reg[D_WIDTH-1:0] data_out;
  always @(posedge clk or negedge rst)
  begin
    if (!rst)
      data_out <= 0;
    else 
      begin
        if(data_in[D_WIDTH-1])
          data_out <= 0;
        else data_out <= data_in;
      end
  end
endmodule