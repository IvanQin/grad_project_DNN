module distributor(l_clk,m_clk,p_index,rst,en);
  parameter A_WIDTH = 4; // the index_width of the index of P e.g. if A_WIDTH = 4, there will be 16 elements in p_ram array (16 elements in input_vector_a).
  parameter D_WIDTH = 16;
  parameter W_ADDR_WIDTH = 10; // the max width of the index of weight matrix, e.g. W_ADDR_WIDTH = 10, the weight matrix cannot have more than 2^10=1024 elements
  parameter IDLE = 3'b000, FETCH_P = 3'b001, FETCH_VZ = 3'b010, SEND = 3'b011, COMPARE = 3'b100;
  input l_clk; // clock with long period, need change
  input m_clk;// clock with medium period, need change
  input en;
  input rst;
  input[A_WIDTH-1:0] p_index; // p[p_index] and p[p_index+1] should be the start/end index of the V,J vector
  reg[2:0] current_state;
  reg[2:0] next_state;
  reg[A_WIDTH-1:0] p_ram_even_r_addr;
  reg[A_WIDTH-1:0] p_ram_odd_r_addr;
  wire[W_ADDR_WIDTH-1:0] p_ram_even_data_out;
  wire[W_ADDR_WIDTH-1:0] p_ram_odd_data_out;
  wire[D_WIDTH-1:0] v_data_out_w;
  wire[A_WIDTH-1:0] z_data_out_w; // actually z is the number of the zeros (so it is non-negative integer under 16)
  reg[D_WIDTH-1:0] v_data_out;
  reg[A_WIDTH-1:0] z_data_out; //actually z is the number of the zeros (so it is non-negative integer under 16)
  reg[W_ADDR_WIDTH-1:0] start_index; // start index of the V,J vector to get weight from them, for the present column of input vector a
  reg[W_ADDR_WIDTH-1:0] end_index;  // end index of the V,J vector to get weight from them, for the present column of input vector a
  reg[W_ADDR_WIDTH-1:0] iter_index; // interation pointer between start and end
  reg[W_ADDR_WIDTH-1:0] z_actual_offset; // judge which Process Unit handle the number (mod 4) e.g. if a weight matrix is N*M, then 0 <= z_actual_offset < M
  wire iter_over;
  wire PU0_buffer_full;
  wire PU1_buffer_full;
  wire PU2_buffer_full;
  wire PU3_buffer_full;
  reg w_en_PU0;
  reg w_en_PU1;
  reg w_en_PU2;
  reg w_en_PU3;
  assign iter_over = (iter_index == end_index);
  always @(posedge l_clk or negedge rst)
  begin
    if (!rst)
      current_state <= IDLE;
    else current_state <= next_state;
  end
  
  always @(current_state,en)
  begin
    next_state <= 3'bxxx;
    case (current_state)
        IDLE:
        begin
          if (en)
            next_state <= FETCH_P;
          else next_state <= IDLE;
        end
        FETCH_P:
        begin
          next_state <= FETCH_VZ;
        end
        FETCH_VZ:
        begin
          next_state <= SEND;
        end
        SEND:
        begin
          if (iter_over)
            next_state <= FETCH_VZ;
          else next_state <= IDLE;
        end
        default:;
      endcase
  end
  
  always @(posedge l_clk or negedge rst)
  begin
    if (!rst)
      begin
        z_actual_offset <= -1;
        w_en_PU0 <= 0;
        w_en_PU1 <= 0;
        w_en_PU2 <= 0;
        w_en_PU3 <= 0;
      end
    else
      case (next_state)
        FETCH_P:
        begin
          if (p_index[0]) // p_index is odd
            begin
              p_ram_even_r_addr <= p_index + 1'b1;
              p_ram_odd_r_addr <= p_index;
              start_index <= p_ram_odd_data_out;
              end_index <= p_ram_even_data_out;
            end
          else // p_index is even
            begin
              p_ram_even_r_addr <= p_index + 1'b1;
              p_ram_odd_r_addr <= p_index;
              start_index <= p_ram_even_data_out;
              end_index <= p_ram_odd_data_out;
            end  
        iter_index <= start_index;  
        end
        FETCH_VZ:
        begin
          z_actual_offset <= z_actual_offset + 1 + z_data_out;
          v_data_out <= v_data_out_w;
          z_data_out <= z_data_out_w;
        end
        SEND:
        begin
          case (z_actual_offset[1:0])
            2'b00: w_en_PU0 <= 1;
            2'b01: w_en_PU1 <= 1;
            2'b10: w_en_PU2 <= 1;
            2'b11: w_en_PU3 <= 1;
            default:;
          endcase
          iter_index <= iter_index + 1; // iteration index plus one every cycle
        end
      endcase
  end
  ram p_ram_even(.clk(m_clk),.data_out(p_ram_even_data_out),.r_addr(p_ram_even_r_addr));
  ram p_ram_odd(.clk(m_clk),.data_out(p_ram_odd_data_out),.r_addr(p_ran_odd_r_addr));
  ram v_ram(.clk(m_clk),.data_out(v_data_out_w),.r_addr(iter_index));
  ram z_ram(.clk(m_clk),.data_out(z_data_out_w),.r_addr(iter_index));
  fifo PU0_buffer(.clk(m_clk),.rst(rst),.w_en(w_en_PU0),.data_in(v_data_out),.index_in(z_actual_offset),.fifo_full(PU0_buffer_full)); // full needs a full signal (maybe a LED)
  fifo PU1_buffer(.clk(m_clk),.rst(rst),.w_en(w_en_PU1),.data_in(v_data_out),.index_in(z_actual_offset),.fifo_full(PU1_buffer_full));
  fifo PU2_buffer(.clk(m_clk),.rst(rst),.w_en(w_en_PU2),.data_in(v_data_out),.index_in(z_actual_offset),.fifo_full(PU2_buffer_full));
  fifo PU3_buffer(.clk(m_clk),.rst(rst),.w_en(w_en_PU3),.data_in(v_data_out),.index_in(z_actual_offset),.fifo_full(PU3_buffer_full));
endmodule