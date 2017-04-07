`timescale 1ps/1ps
module process_unit_test;
  reg s_clk;
  reg m_clk;
  reg rst;
  reg fetch_enable;
  reg[15:0] a;
  reg[15:0] b;
  reg finish_enable;
  wire[15:0] sum;
  
  process_unit PU1 (.s_clk(s_clk),.m_clk(m_clk),.rst(rst),.fetch_enable(fetch_enable),.a(a),.b(b),.finish_enable(finish_enable), .sum(sum));
  
  always #1 s_clk = ~s_clk;
  always #5 m_clk = ~m_clk;
  initial
  begin
    s_clk = 1'b0;
    m_clk = 1'b0;
    rst = 1'b0;
    fetch_enable = 1'b0;
    finish_enable = 1'b0;
    #10 rst = 1'b1;
    #5 a = 16'h0002; b = 16'h0003;
    #5 fetch_enable = 1'b1;
    #10 fetch_enable = 1'b0;
    #60 a = 16'h0003; b = 16'h0005;
    #5 fetch_enable = 1'b1;
    #10 fetch_enable = 1'b0;
    #40 finish_enable = 1'b1;
    #10 finish_enable = 1'b0;
  end
  
  
  
endmodule
