`timescale 1ps/1ps
module dis_test;
  reg s_clk;
  reg l_clk;
  reg m_clk;
  
  always #1 s_clk = ~s_clk;
  always #10 m_clk = ~m_clk;
  reg[3:0] layer_index;
  reg[3:0] p_index;
  wire all_done;
  reg need_act;
  reg dis_en;
  reg rst;
  
 distributor dis(
.l_clk(l_clk),
.m_clk(m_clk),
.s_clk(s_clk),
.rst(rst),
.en(dis_en),
.layer_index(layer_index),
.all_done(all_done),
.need_act(need_act),
.p_index_in(p_index)
);

  
  initial
  begin
    s_clk = 0;
    m_clk = 0;
    p_index <= 0;
    layer_index <= 0;
    rst <= 1'b0;
    dis_en <= 1'b0;
    need_act <= 1'b0;
    
    #10
    rst<= 1'b1;
    dis_en <= 1'b1;
    
  end
endmodule