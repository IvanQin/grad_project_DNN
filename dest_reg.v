`timescale 1ps/1ps
module dest_reg(
  clk,
  rst,
  set,
  bias,
  index_in0,
  index_in1,
  index_in2,
  index_in3,
  index_in,
  r_en,
  w_en0,
  w_en1,
  w_en2,
  w_en3, 
  data_out0,
  data_out1,
  data_out2,
  data_out3,
  data_out,
  data_out_raw0, // 2*DWIDTH
  data_out_raw1, // 2*DWIDTH
  data_out_raw2, // 2*DWIDTH
  data_out_raw3, // 2*DWIDTH
  data_in0,
  data_in1,
  data_in2,
  data_in3,
  r_en0,
  r_en1,
  r_en2,
  r_en3,
  r_raw_en0, // 2*DWIDTH
  r_raw_en1,
  r_raw_en2,
  r_raw_en3,
  act
  );
  parameter I_WIDTH = 4;
  parameter D_WIDTH = 16; 
  input clk;
  input rst;
  input w_en0,w_en1,w_en2,w_en3;
  input r_en0,r_en1,r_en2,r_en3;
  input r_raw_en0,r_raw_en1,r_raw_en2,r_raw_en3;
  input set;
  input act;// the signal of activating the elements in this reg (activation function: ReLU)
  input[I_WIDTH-1:0] index_in0,index_in1,index_in2,index_in3;
  input[I_WIDTH-1:0] index_in;
  input r_en;
  input[2*D_WIDTH-1:0] data_in0,data_in1,data_in2,data_in3; // no truncation when accumulating, so bit width times 2b
  input[D_WIDTH-1:0] bias;
  output reg[D_WIDTH-1:0] data_out0,data_out1,data_out2,data_out3;
  output reg[2*D_WIDTH-1:0] data_out_raw0,data_out_raw1,data_out_raw2,data_out_raw3;
  output reg[D_WIDTH-1:0] data_out;
  reg[2*D_WIDTH-1:0] mem [2**I_WIDTH-1:0];
  integer i;
  always @(posedge clk or negedge rst)
  begin
    if (!rst)
      begin
      data_out0 <= 0;
      data_out1 <= 0;
      data_out2 <= 0;
      data_out3 <= 0;
      end
    else 
      begin
        /* read truncated data*/
        if (r_en0) // if you want to read data, set the r_en
          data_out0 <= mem[index_in0][2*D_WIDTH-1:D_WIDTH]; // wrong but unused here !!
        else data_out0 <= 16'bZ;
        if (r_en1) // if you want to read data, set the r_en
          data_out1 <= mem[index_in1][2*D_WIDTH-1:D_WIDTH]; // wrong but unused here !!
        else data_out1 <= 16'bZ;
        if (r_en2) // if you want to read data, set the r_en
          data_out2 <= mem[index_in2][2*D_WIDTH-1:D_WIDTH]; // wrong but unused here !!
        else data_out2 <= 16'bZ;
        if (r_en3) // if you want to read data, set the r_en
          data_out3 <= mem[index_in3][2*D_WIDTH-1:D_WIDTH]; // wrong but unused here !!
        else data_out3 <= 16'bZ;
          
        /* read raw data */
        if (r_raw_en0) // if you want to read data, set the r_raw_en
          data_out_raw0 <= mem[index_in0][2*D_WIDTH-1:0];
        else data_out_raw0 <= 32'bZ;
        if (r_raw_en1) // if you want to read data, set the r_raw_en
          data_out_raw1 <= mem[index_in1][2*D_WIDTH-1:0];
        else data_out_raw1 <= 32'bZ;
        if (r_raw_en2) // if you want to read data, set the r_raw_en
          data_out_raw2 <= mem[index_in2][2*D_WIDTH-1:0];
        else data_out_raw2 <= 32'bZ;
        if (r_raw_en3) // if you want to read data, set the r_raw_en
          data_out_raw3 <= mem[index_in3][2*D_WIDTH-1:0];
        else data_out_raw3 <= 32'bZ;
      end
  end
  
  always @(posedge clk)
  begin
    if (r_en)
      data_out <= {mem[index_in][31],mem[index_in][23:9]};
    else data_out <= 16'bz;
  end
  
  always @(posedge clk)
  begin
    if (w_en0)
      mem[index_in0] <= data_in0;
    if (w_en1)
      mem[index_in1] <= data_in1;
    if (w_en2)
      mem[index_in2] <= data_in2;
    if (w_en3)
      mem[index_in3] <= data_in3;
  end
  
  always @(posedge clk) // dont know how long it will take to set all this value
  begin
    if (set) // set will init the mem with bias
      for (i=0;i<2**I_WIDTH;i=i+1)
      begin
        mem[i][31] <= bias[15];
        mem[i][23:9] <= bias[14:0];
      end
  end
  
  always @(posedge clk) // activiate the elements in this register
  begin
    if (act)
      for (i=0;i<2**I_WIDTH;i=i+1)
      begin
        mem[i] <= (mem[i][2*D_WIDTH-1] == 1)?0:mem[i];
      end
  end
  integer fp_w;
  initial
  begin
    $readmemb("ram_init.txt",mem);
    #40 fp_w = $fopen("ram_res.txt","w");
    for (i=0;i<16;i=i+1)
    begin
      $fwrite(fp_w,"%b\n",mem[i]);
      end
    $fclose(fp_w);
    end
endmodule
  
