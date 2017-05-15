module nn_top (s_clk,m_clk,l_clk,rst,en);
  input s_clk;
  input m_clk;
  input l_clk;
  input en;
  input rst;
  parameter IDLE = 4'b0000, CONV1 = 4'b0001, ACTIVE = 4'b0010, OUT = 4'b0011;
  reg[3:0] current_state;
  reg[3:0] next_state;
  reg[3:0] layer_index;
  reg[3:0] p_index;
  reg dis_en;
  reg need_act;
  wire all_done;
  always @(posedge l_clk or negedge rst)
  begin
    if (!rst)
      current_state <= IDLE;
    else current_state <= next_state;
  end
  
  always @(current_state, en, all_done)
  begin
    next_state <= 4'bxxxx;
    case (current_state)
      IDLE:
      begin
        if (en)
          next_state <= IDLE;
        else
          next_state <= CONV1;
      end
      CONV1:
      begin
        if (all_done)
          next_state <= OUT;
        else next_state <= CONV1;
      end
      OUT:
      begin
        next_state <= IDLE;
      end
      default:;
    endcase
  end
  
  always @(posedge l_clk or negedge rst)
  begin
    if (!rst)
      begin
        dis_en <= 1'b0;
        layer_index <= 0;
        need_act <= 0;
      end
    else
      case (next_state)
        IDLE:
        begin
          dis_en <= 1'b0;
          layer_index <= 0;
          need_act <= 0;
        end
        CONV1:
        begin
          layer_index <= layer_index + 1;
          dis_en <= 1'b1;
        end
        OUT:
        begin
          dis_en <= 1'b0;
        end
        default:;
      endcase
  end
  
  always @(posedge s_clk)
  begin
    if (dis_en)
      dis_en <= 1'b0;
  end
  
distributor dis(
.m_clk(m_clk),
.s_clk(s_clk),
.rst(rst),
.en(dis_en),
.layer_index(layer_index),
.all_done(all_done),
.need_act(need_act),
.p_index_in(p_index)
);
  
endmodule