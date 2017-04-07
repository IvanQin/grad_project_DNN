`timescale 1ps/1ps
module multiple_test;
  reg[15:0] a;
  reg[15:0] b;
  wire[31:0] product;
  reg clk;
  reg rst;
  multiple mul1(.a(a),.b(b), .product(product), .clk(clk), .rst(rst)); // port with () is the port of the test module
  always #1 clk = ~clk;
  initial 
    begin
      #0 clk=1'b0;
      #5 rst=1'b0;
      #10 rst = 1'b1;
      #15 a = 16'h801a; b = 16'h8022;
    end
  endmodule

