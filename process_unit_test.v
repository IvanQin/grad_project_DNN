`timescale 1ps/1ps
module process_unit_test;
  reg s_clk;
  reg m_clk;
  reg rst;
  reg fetch_enable;
  reg[15:0] a;
  reg[15:0] b;
  reg set;
  reg act;
  reg[15:0] bias;
  reg finish_enable;
  wire[31:0] sum;
  reg[3:0] index_in;
  wire w_en0,w_en1,w_en2,w_en3;
  wire r_en0,r_en1,r_en2,r_en3;
  wire r_raw_en0,r_raw_en1,r_raw_en2,r_raw_en3;
  wire[31:0] data_out;
  wire[31:0] data_in;
  wire read_en;
  wire write_en;
  wire[3:0] index_trans;
  assign r_raw_en0 = read_en;
  assign w_en0 = write_en;
  parameter ZERO_1 = 1'b0,ZERO_4 = 4'b0000,ZERO_16 = 16'h0000,ZERO_32 = 32'h00000000;
  wire[15:0] data_out0,data_out1,data_out2,data_out3;
  wire[31:0] data_out_raw_1,data_out_raw_2,data_out_raw_3;
  wire PU0_buffer_empty;
  wire PU0_buffer_full;
  wire fetch_en_0;
  wire[3:0] weight_index_0;
  assign fetch_en_0 = ~PU0_buffer_empty;
  assign index_trans = weight_index_0;
  wire[15:0] weight_0;
  wire read_buffer_en;
  wire[3:0] index_PU2Reg;
  reg w_en_PU0;
  reg[15:0] v_data_out;
  reg[3:0] z_actual_offset;
  reg[9:0] vec_index;
  reg r_en;
  wire [15:0] copy_data;
  reg input_w_en;
  reg finish_copy;
  reg [3:0] output_vec_length;
  reg [3:0] copy_addr;
  reg [3:0] copy_addr_input;
  reg copy;
  ram input_ram(.clk(s_clk),.rst(rst),.data_in(copy_data),.w_addr(copy_addr_input),.data_out(in_vec),.r_addr(vec_index),.w_en(input_w_en));

  fifo PU0_buffer(
  .clk(s_clk),
  .rst(rst),
  .r_en(read_buffer_en),
  .w_en(w_en_PU0),
  .data_in(v_data_out),
  .index_in(z_actual_offset),
  .data_out(weight_0),
  .index_out(weight_index_0),
  .fifo_full(PU0_buffer_full),
  .fifo_empty(PU0_buffer_empty)); // full needs a full signal (maybe a LED)
  process_unit PU0 (.s_clk(s_clk),
  .m_clk(m_clk),
  .rst(rst),
  .fetch_enable(fetch_en_0),
  .weight_index_out(index_PU2Reg),
  .finish_enable(finish_enable),
  .a(in_vec),
  .b(weight_0),
  .sum(sum),
  .dest_data_in(data_out),
  .dest_data_out(data_in),
  .read_en(read_en),
  .write_en(write_en),
  .weight_index(index_trans),
  .read_buffer_en(read_buffer_en)
  );
  dest_reg dest_reg1(.clk(s_clk),.rst(rst),
  .index_in0(index_PU2Reg),
  .index_in1(ZERO_4),
  .index_in2(ZERO_4),
  .index_in3(ZERO_4),
  .data_out_raw0(data_out),
  .data_out_raw1(data_out_raw_1),
  .data_out_raw2(data_out_raw_2),
  .data_out_raw3(data_out_raw_3),
  .data_out0(data_out0),
  .data_out1(data_out1),
  .data_out2(data_out2),
  .data_out3(data_out3),
  .data_in0(data_in),
  .data_in1(ZERO_32),
  .data_in2(ZERO_32),
  .data_in3(ZERO_32),
  .w_en0(w_en0),
  .w_en1(w_en1),
  .w_en2(w_en2),
  .w_en3(w_en3),
  .r_en0(r_en0),
  .r_en1(r_en1),
  .r_en2(r_en2),
  .r_en3(r_en3),  
  .r_raw_en0(r_raw_en0),
  .r_raw_en1(r_raw_en1),
  .r_raw_en2(r_raw_en2),
  .r_raw_en3(r_raw_en3),
  .bias(bias),
  .act(act),
  .set(set),
  .data_out(copy_data),
  .r_en(r_en),
  .index_in(copy_addr)
  );
  
  always #1 s_clk = ~s_clk;
  always #5 m_clk = ~m_clk;
  always @(posedge s_clk)
  begin
    if (w_en_PU0)
      w_en_PU0 <= 1'b0;
  end
  
  /*
  test copy from dest_reg to input ram
  */

  reg[3:0] copy_counter;
  always @(posedge s_clk) // copy data from dest_reg to input_ram
  begin
    if (copy)
      begin
        //read from dest_reg
        r_en <= 1'b1;
        //write to input ram
        copy_addr_input <= copy_addr;
        if (copy_counter >= 1)
          input_w_en <= 1'b1;      
        // copy_addr plus by itself
        copy_addr <= copy_addr + 1; 
        copy_counter <= copy_counter + 1;
        if (copy_counter > output_vec_length)
          begin
          finish_copy <= 1'b1;
          input_w_en <= 1'b0;
          r_en <= 1'b0;
          copy <= 1'b0;
          end
      end
  end
  

  initial
  begin
    s_clk = 1'b0;
    m_clk = 1'b0;
    finish_copy = 1'b0;
    rst = 1'b0;
    fetch_enable = 1'b0;
    finish_enable = 1'b0;
    index_in = 4'b0001;
    bias = 16'h8001;
    set = ZERO_1;
    act = ZERO_1;
    vec_index = 0;
    input_w_en = 0;
    r_en = 0;
    copy = 0;
    output_vec_length = 4'h3;
    copy_addr = -1;
    copy_addr_input = 0;
    copy_counter = 0;
    #5
    copy = 1;
    /*
    #5 rst=1'b1;
    #5 w_en_PU0 = 1'b1;
    vec_index = 1;
    z_actual_offset = 4'h1;
    v_data_out = 16'h0001;
    #10 w_en_PU0 = 1'b1;
    vec_index = 2;
    z_actual_offset = 4'h2;
    v_data_out = 16'h0002;
    #10 w_en_PU0 = 1'b1;
    vec_index = 3;
    z_actual_offset = 4'h3;
    v_data_out = 16'h0003;
    */
    /*
    #10 rst = 1'b1;
    #5 set = 1'b1;
    #5 set = 1'b0;
    #5 act = 1'b1;
    #5 act = 1'b0;*/
    /*
    #10 rst = 1'b1;
    #5 a = 16'h00ab; b = 16'h0057;
    #5 fetch_enable = 1'b1;
    #10 fetch_enable = 1'b0;
    #60 a = 16'h0145; b = 16'h8059;
    #5 fetch_enable = 1'b1;
    #10 fetch_enable = 1'b0;
    #40 finish_enable = 1'b1;
    #10 finish_enable = 1'b0;*/
  end
  
  
  
endmodule
