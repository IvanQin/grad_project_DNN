module distributor(l_clk,m_clk,s_clk,rst,en,layer_index,all_done,need_act,p_index_in); // 1 layer will invoke 1 distributor
  parameter A_WIDTH = 4; // the index_width of the index of P e.g. if A_WIDTH = 4, there will be 16 elements in p_ram array (16 elements in input_vector_a).
  parameter D_WIDTH = 16;
  // W_ADDR_WIDTH = I_WIDTH in PU and Reg
  parameter W_ADDR_WIDTH = 4; // the max width of the index of weight matrix, e.g. W_ADDR_WIDTH = 10, the weight matrix cannot have more than 2^10=1024 elements
  parameter IDLE = 4'b0000, INIT_BIAS = 4'b0001, INIT_P = 4'b0010, GET_INDEX = 4'b0011, FETCH_VZ = 4'b0100, SEND = 4'b0101, WAIT = 4'b0110, PROCESS = 4'b0111, COPY = 4'b1000;
  input l_clk; // clock with long period, need change
  input m_clk;// clock with medium period, need change
  input s_clk;
  input en;
  input rst;
  input need_act; // the data in this layer needs activation
  input[3:0] layer_index; // at most 15 layers in the NN
  output reg all_done;
  wire done; //
  input[A_WIDTH-1:0] p_index_in; // p[p_index] and p[p_index+1] should be the start/end index of the V,J vector
  reg[A_WIDTH-1:0] p_index;
  reg[A_WIDTH-1:0] vec_index; // the current index of the input vector (EQUALS TO P_INDEX)
  wire[A_WIDTH-1:0] vec_length;
  reg[3:0] current_state;
  reg[3:0] next_state;
  reg[A_WIDTH-1:0] p_ram_even_r_addr;
  reg[A_WIDTH-1:0] p_ram_odd_r_addr;
  wire[W_ADDR_WIDTH-1:0] p_ram_even_data_out;
  wire[W_ADDR_WIDTH-1:0] p_ram_odd_data_out;
  wire[D_WIDTH-1:0] v_data_out_w;
  wire[A_WIDTH-1:0] z_data_out_w; // actually z is the number of the zeros (so it is non-negative integer under 16)
  wire[D_WIDTH-1:0] bias_data_out_w;
  reg[D_WIDTH-1:0] v_data_out;
  reg[A_WIDTH-1:0] z_data_out; //actually z is the number of the zeros (so it is non-negative integer under 16)
  reg[D_WIDTH-1:0] bias_data_out;
  reg[W_ADDR_WIDTH-1:0] start_index; // start index of the V,J vector to get weight from them, for the present column of input vector a
  reg[W_ADDR_WIDTH-1:0] end_index;  // end index of the V,J vector to get weight from them, for the present column of input vector a
  reg[W_ADDR_WIDTH-1:0] iter_index; // interation pointer between start and end
  reg[W_ADDR_WIDTH-1:0] z_actual_offset; // judge which Process Unit handle the number (mod 4) e.g. if a weight matrix is N*M, then 0 <= z_actual_offset < M
  wire PU0_buffer_full;
  wire PU1_buffer_full;
  wire PU2_buffer_full;
  wire PU3_buffer_full;
  wire PU0_buffer_empty;
  wire PU1_buffer_empty;
  wire PU2_buffer_empty;
  wire PU3_buffer_empty;
  
  wire[D_WIDTH-1:0] weight_0;
  wire[D_WIDTH-1:0] weight_1;
  wire[D_WIDTH-1:0] weight_2;
  wire[D_WIDTH-1:0] weight_3;
  
  wire[A_WIDTH-1:0] weight_index_0;
  wire[A_WIDTH-1:0] weight_index_1;
  wire[A_WIDTH-1:0] weight_index_2;
  wire[A_WIDTH-1:0] weight_index_3;
  
  wire[2*D_WIDTH-1:0] sum0,sum1,sum2,sum3;
  wire[D_WIDTH-1:0] in_vec; // connection between the input_ram and the PU
  reg[D_WIDTH-1:0]  in_vec_reg;
  reg w_en_PU0;
  reg w_en_PU1;
  reg w_en_PU2;
  reg w_en_PU3;
  
  reg set_en;
  reg act_en;
  
  wire[W_ADDR_WIDTH-1:0] w_PU2Reg_0,w_PU2Reg_1,w_PU2Reg_2,w_PU2Reg_3;
  wire[2*D_WIDTH-1:0] reg_data_raw_out_0,reg_data_raw_out_1,reg_data_raw_out_2,reg_data_raw_out_3;
  wire[2*D_WIDTH-1:0] reg_data_raw_in_0,reg_data_raw_in_1,reg_data_raw_in_2,reg_data_raw_in_3;
  wire[D_WIDTH-1:0] reg_data_out_0,reg_data_out_1,reg_data_out_2,reg_data_out_3;
  reg read_reg_0,read_reg_1,read_reg_2,read_reg_3;
  wire read_reg_raw_0,read_reg_raw_1,read_reg_raw_2,read_reg_raw_3;
  wire write_reg_0,write_reg_1,write_reg_2,write_reg_3;
  wire read_buffer_en0,read_buffer_en1,read_buffer_en2,read_buffer_en3;
  
  reg finish_copy;
  reg copy;
  reg[A_WIDTH-1:0] copy_addr;
  reg[A_WIDTH-1:0] copy_addr_input;
  wire[D_WIDTH-1:0] copy_data;
  wire[A_WIDTH-1:0] output_vec_length;
  reg r_en;
  reg input_w_en;
  reg[3:0] copy_counter;
  
  wire all_fifo_empty;
  reg copy_state;
  
  
  reg[D_WIDTH-1:0] idle_data_in;
  reg[A_WIDTH-1:0] idle_data_in_4;
  reg idle_w_en;
  reg[A_WIDTH-1:0] idle_w_addr;
  wire finish_enable0,finish_enable1,finish_enable2,finish_enable3;
  wire PU_finish;
  
  assign iter_over = ((iter_index == end_index) && (end_index != 0));  // end_index is actually out of range, end_index = 0 means state = IDLE
  assign done = ((vec_index == vec_length) && (vec_index != 0)); // done = '1' means status can go to IDLE, the process of this layer is done
  assign PU_finish = (finish_enable0 && finish_enable1 && finish_enable2  && finish_enable3);
  assign fetch_en_0 = ~PU0_buffer_empty; // if the fifo is not empty, the fetch_enable will keep high
  assign fetch_en_1 = ~PU1_buffer_empty;
  assign fetch_en_2 = ~PU2_buffer_empty;
  assign fetch_en_3 = ~PU3_buffer_empty;

  assign all_fifo_empty = (PU0_buffer_empty && PU1_buffer_empty && PU2_buffer_empty && PU3_buffer_empty);
    
  always @(posedge m_clk or negedge rst)
  begin
    if (!rst)
      current_state <= IDLE;
    else current_state <= next_state;
  end
  
  always @(current_state,en,iter_over,all_fifo_empty,finish_copy,done,PU_finish)
  begin
    next_state <= 3'bxxx;
    case (current_state)
        IDLE://0
        begin
          if (en)
            next_state <= INIT_BIAS;
          else next_state <= IDLE;
        end
        INIT_BIAS: // repeat only once per layer
        begin
          next_state <= INIT_P;
        end
        INIT_P: // repeat n times per layer (n equals to the input vector length
        begin
          if (~done)
            next_state <= GET_INDEX;
          else next_state <= WAIT;
        end
        GET_INDEX:
        begin
         next_state <= FETCH_VZ;
        end
        FETCH_VZ:
        begin
          next_state <= SEND;
        end
        SEND:
        begin
          if (~iter_over) // iteration keeps going
            next_state <= FETCH_VZ;
          else next_state <= INIT_P;
        end
        WAIT:
        begin
          if (all_fifo_empty && PU_finish)
            next_state <= PROCESS;
          else next_state <= WAIT;
        end
        PROCESS:
        begin
          next_state <= COPY;
        end
        COPY:
        begin
          copy_state <= 0;
          if (finish_copy)
            next_state <= IDLE;
          else next_state <= COPY;
        end
        default:;
      endcase
  end

  always @(posedge m_clk or negedge rst)
  begin
    if (!rst)
      begin
        z_actual_offset <= -1;
        w_en_PU0 <= 0;
        w_en_PU1 <= 0;
        w_en_PU2 <= 0;
        w_en_PU3 <= 0;
        p_ram_even_r_addr <= 0;
        p_ram_odd_r_addr <= 0;
        start_index <= 0;
        end_index <= 0;
        iter_index <= 0;
        vec_index <= -1;
        r_en <= 0;
        input_w_en <= 0;
        copy_addr <= -1;
        copy_addr_input <= 0;
        copy_counter <= 0;
        all_done <= 0;
        p_index <= 0;
        finish_copy <= 0;
      end
    else
      case (next_state)
        IDLE://0
        begin
          z_actual_offset <= -1;
          w_en_PU0 <= 0;
          w_en_PU1 <= 0;
          w_en_PU2 <= 0;
          w_en_PU3 <= 0;
          p_ram_even_r_addr <= 0;
          p_ram_odd_r_addr <= 0;
          start_index <= 0;
          end_index <= 0;
          iter_index <= 0;
          vec_index <= -1;
          r_en <= 0;
          input_w_en <= 0;
          copy_addr <= -1;
          copy_addr_input <= 0;
          copy_counter <= 0;
          all_done <= 0;
          finish_copy <= 0;
          
        end
        INIT_BIAS://1
        begin
          // init bias in the dest reg
          p_index <= p_index_in;
          set_en <= 1'b1;
          bias_data_out <= bias_data_out_w;
        end
        INIT_P://2
        begin
          // a new column begins,so offset should be -1
          z_actual_offset <= -1;
          // fetch p from the p_ram
          if (p_index[0]) // p_index is odd
            begin
              p_ram_even_r_addr <= p_index + 1'b1;
              p_ram_odd_r_addr <= p_index;
            end
          else // p_index is even
            begin
              p_ram_even_r_addr <= p_index;
              p_ram_odd_r_addr <= p_index + 1'b1;
            end   
        /* prepare for the next element in input vector*/
        vec_index <= vec_index + 1'b1;
        end
        GET_INDEX://3
        begin
          if (p_index[0]) // p_index is odd
            begin
              start_index <= p_ram_odd_data_out;
              end_index <= p_ram_even_data_out;
              iter_index <= p_ram_odd_data_out;
            end
          else // p_index is even
            begin
              start_index <= p_ram_even_data_out;
              end_index <= p_ram_odd_data_out;
              iter_index <= p_ram_even_data_out;
            end  
          /* prepare for the next element in input vector*/ 
           p_index <= p_index + 1'b1; 
           in_vec_reg <= in_vec;
        end
        FETCH_VZ://4
        begin
          z_actual_offset <= z_actual_offset + 1 + z_data_out_w;
          //v_data_out <= v_data_out_w;
          //z_data_out <= z_data_out_w;
        end
        SEND://5
        begin
          case (z_actual_offset[1:0])
            2'b00: w_en_PU0 <= 1;
            2'b01: w_en_PU1 <= 1;
            2'b10: w_en_PU2 <= 1;
            2'b11: w_en_PU3 <= 1;
            default:;
          endcase
          iter_index <= iter_index + 1; // iteration index plus one every cycle, the index is used to find weight
        end
        PROCESS://7
        begin
          if (need_act)
            act_en <= 1'b1;
        end
        COPY://8
        begin
          copy <= 1'b1;
        end
      endcase
  end
  
  always @(posedge s_clk) // avoid repeating write to fifo
  begin
    if (w_en_PU0)
      w_en_PU0 <= 0;
    if (w_en_PU1)
      w_en_PU1 <= 0;
    if (w_en_PU2)
      w_en_PU2 <= 0;
    if (w_en_PU3)
      w_en_PU3 <= 0;
  end
  
  always @(posedge s_clk) // avoid repeating activating the data in dest_reg
  begin
    if (act_en)
      act_en <= 1'b0;
  end
  
  always @(posedge s_clk)
  begin
    all_done <= finish_copy;
  end

  always @(posedge s_clk)
  begin
    if (set_en)
      set_en <= 1'b0;
  end
  
  always @(posedge s_clk) // copy data from dest_reg to input_ram
  begin
    if (copy)
      begin
        copy_state <= ~copy_state;
        case (copy_state)
          1'b1:
          begin
            //read from dest_reg
            r_en <= 1'b1;
            input_w_en <= 1'b0;
          end
          1'b0:
          begin
            // copy_addr plus by itself
            copy_addr <= copy_addr + 1; 
            copy_addr_input <= copy_addr;
           //write to input ram
            copy_counter <= copy_counter + 1;
            if (copy_counter >= 1)
              input_w_en <= 1'b1;    
          end
        endcase
        if (copy_counter > output_vec_length)
          begin
          finish_copy <= 1'b1;
          input_w_en <= 1'b0;
          r_en <= 1'b0;
          copy <= 1'b0;
          end
      end
    end
  
  input_ram input_ram(.clk(s_clk),.rst(rst),.data_in(copy_data),.w_addr(copy_addr_input),.data_out(in_vec),.r_addr(vec_index),.w_en(input_w_en));
  layer_ram layer_ram(.clk(s_clk),.rst(rst),.data_out(vec_length),.r_addr(layer_index),.data_in(idle_data_in_4),.w_en(idle_w_en),.w_addr(idle_w_addr));
  output_ram output_ram(.clk(s_clk),.rst(rst),.data_out(output_vec_length),.r_addr(layer_index),.data_in(idle_data_in_4),.w_en(idle_w_en),.w_addr(idle_w_addr));
  p_ram p_ram_even(.clk(s_clk),.rst(rst),.data_out(p_ram_even_data_out),.r_addr(p_ram_even_r_addr),.data_in(idle_data_in_4),.w_en(idle_w_en),.w_addr(idle_w_addr)); // the thing stored in p_ram_even and p_ram_odd is same
  p_ram p_ram_odd(.clk(s_clk),.rst(rst),.data_out(p_ram_odd_data_out),.r_addr(p_ram_odd_r_addr),.data_in(idle_data_in_4),.w_en(idle_w_en),.w_addr(idle_w_addr));
  v_ram v_ram(.clk(s_clk),.rst(rst),.data_out(v_data_out_w),.r_addr(iter_index),.data_in(idle_data_in),.w_en(idle_w_en),.w_addr(idle_w_addr));
  z_ram z_ram(.clk(s_clk),.rst(rst),.data_out(z_data_out_w),.r_addr(iter_index),.data_in(idle_data_in_4),.w_en(idle_w_en),.w_addr(idle_w_addr));
  bias_ram bias_ram(.clk(s_clk),.rst(rst),.data_out(bias_data_out_w),.r_addr(layer_index),.data_in(idle_data_in),.w_en(idle_w_en),.w_addr(idle_w_addr));
  fifo PU0_buffer(.clk(s_clk),.rst(rst),.w_en(w_en_PU0),.data_in(v_data_out_w),.index_in(z_actual_offset),.data_out(weight_0),.index_out(weight_index_0),.fifo_full(PU0_buffer_full), .fifo_empty(PU0_buffer_empty),.r_en(read_buffer_en0)); // full needs a full signal (maybe a LED)
  fifo PU1_buffer(.clk(s_clk),.rst(rst),.w_en(w_en_PU1),.data_in(v_data_out_w),.index_in(z_actual_offset),.data_out(weight_1),.index_out(weight_index_1),.fifo_full(PU1_buffer_full), .fifo_empty(PU1_buffer_empty),.r_en(read_buffer_en1));
  fifo PU2_buffer(.clk(s_clk),.rst(rst),.w_en(w_en_PU2),.data_in(v_data_out_w),.index_in(z_actual_offset),.data_out(weight_2),.index_out(weight_index_2),.fifo_full(PU2_buffer_full), .fifo_empty(PU2_buffer_empty),.r_en(read_buffer_en2));
  fifo PU3_buffer(.clk(s_clk),.rst(rst),.w_en(w_en_PU3),.data_in(v_data_out_w),.index_in(z_actual_offset),.data_out(weight_3),.index_out(weight_index_3),.fifo_full(PU3_buffer_full), .fifo_empty(PU3_buffer_empty),.r_en(read_buffer_en3));
  process_unit PU0(.s_clk(s_clk),.m_clk(m_clk),.rst(rst),.fetch_enable(fetch_en_0),.weight_index_out(w_PU2Reg_0),.a(in_vec_reg),.b(weight_0),.weight_index(weight_index_0),.sum(sum0),.dest_data_in(reg_data_raw_out_0),.dest_data_out(reg_data_raw_in_0),.read_en(read_reg_raw_0),.write_en(write_reg_0),.read_buffer_en(read_buffer_en0),.finish_enable(finish_enable0));
  process_unit PU1(.s_clk(s_clk),.m_clk(m_clk),.rst(rst),.fetch_enable(fetch_en_1),.weight_index_out(w_PU2Reg_1),.a(in_vec_reg),.b(weight_1),.weight_index(weight_index_1),.sum(sum1),.dest_data_in(reg_data_raw_out_1),.dest_data_out(reg_data_raw_in_1),.read_en(read_reg_raw_1),.write_en(write_reg_1),.read_buffer_en(read_buffer_en1),.finish_enable(finish_enable1));
  process_unit PU2(.s_clk(s_clk),.m_clk(m_clk),.rst(rst),.fetch_enable(fetch_en_2),.weight_index_out(w_PU2Reg_2),.a(in_vec_reg),.b(weight_2),.weight_index(weight_index_2),.sum(sum2),.dest_data_in(reg_data_raw_out_2),.dest_data_out(reg_data_raw_in_2),.read_en(read_reg_raw_2),.write_en(write_reg_2),.read_buffer_en(read_buffer_en2),.finish_enable(finish_enable2));
  process_unit PU3(.s_clk(s_clk),.m_clk(m_clk),.rst(rst),.fetch_enable(fetch_en_3),.weight_index_out(w_PU2Reg_3),.a(in_vec_reg),.b(weight_3),.weight_index(weight_index_3),.sum(sum3),.dest_data_in(reg_data_raw_out_3),.dest_data_out(reg_data_raw_in_3),.read_en(read_reg_raw_3),.write_en(write_reg_3),.read_buffer_en(read_buffer_en3),.finish_enable(finish_enable3));
  dest_reg dest2(
  .clk(s_clk),
  .rst(rst),
  .set(set_en),
  .act(act_en),
  .bias(bias_data_out),
  .index_in0(w_PU2Reg_0),
  .index_in1(w_PU2Reg_1),
  .index_in2(w_PU2Reg_2),
  .index_in3(w_PU2Reg_3),
  .data_out_raw0(reg_data_raw_out_0),
  .data_out_raw1(reg_data_raw_out_1),
  .data_out_raw2(reg_data_raw_out_2),
  .data_out_raw3(reg_data_raw_out_3),
  .data_out0(reg_data_out_0),
  .data_out1(reg_data_out_1),
  .data_out2(reg_data_out_2),
  .data_out3(reg_data_out_3),
  .data_in0(reg_data_raw_in_0),
  .data_in1(reg_data_raw_in_1),
  .data_in2(reg_data_raw_in_2),
  .data_in3(reg_data_raw_in_3),
  .w_en0(write_reg_0),
  .w_en1(write_reg_1),
  .w_en2(write_reg_2),
  .w_en3(write_reg_3),
  .r_en0(read_reg_0),
  .r_en1(read_reg_1),
  .r_en2(read_reg_2),
  .r_en3(read_reg_3),
  .r_raw_en0(read_reg_raw_0),
  .r_raw_en1(read_reg_raw_1),
  .r_raw_en2(read_reg_raw_2),
  .r_raw_en3(read_reg_raw_3),
  .data_out(copy_data),
  .r_en(r_en),
  .index_in(copy_addr)
  );
  
  /*initial
  begin
    $readmemb("input_ram.txt",input_ram);
    $readmemb("v.txt",v_ram);
    $readmemb("z.txt",z_ram);
    $readmemb("layer_ram.txt",layer_ram);
    $readmemb("p_even.txt",p_ram_even);
    $readmemb("p_odd.txt",p_ram_odd);
    $readmemb("bias.txt",bias_ram);
  end*/
endmodule