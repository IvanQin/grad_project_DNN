`timescale 1ps/1ps
module adder_test;
  reg[31:0] a;
  reg[31:0] b;
  reg cin;
  wire cout;
  wire[31:0] sum;
  reg clk;
  reg rst;
  adder adder1(.a(a),.b(b),.cin(cin), .cout(cout), .sum(sum), .clk(clk), .rst(rst)); // port with () is the port of the test module
  always #1 clk = ~clk;
  initial 
    begin
      #0 clk=1'b0; cin = 1'b0;
      #5 rst=1'b0;
      #10 rst = 1'b1;
      #15 a = 32'h80000001; b = 32'h80000002;
    end
  endmodule
