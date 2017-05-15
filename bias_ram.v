module bias_ram(clk,rst,w_en,data_in,data_out,w_addr,r_addr);
  parameter D_WIDTH = 16;
  parameter A_WIDTH = 4;
  input clk;
  input w_en;
  input rst;
  input[D_WIDTH-1:0] data_in;
  
  input[A_WIDTH-1:0] w_addr;
  input[A_WIDTH-1:0] r_addr;
  output[D_WIDTH-1:0] data_out;
  
  reg[D_WIDTH-1:0] RAM [2**A_WIDTH-1:0];
  reg[A_WIDTH-1:0] r_addr_reg;
  
  always @(posedge clk)
  begin
    if (w_en)
      begin
        RAM[w_addr] <= data_in;
      end
  end
  
  always @(posedge clk)
  begin
    r_addr_reg <= r_addr;
  end
  /*
  integer i;
  always @(negedge rst)
  begin
    for (i = 0; i <2**A_WIDTH;i=i+1)
    begin
      RAM[i] <= 0;
    end
  end
  */
  assign data_out = RAM[r_addr_reg];
  
  initial
  begin
    $readmemb("bias.txt",RAM);
  end
endmodule
  

