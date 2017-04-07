module fifo (clk,rst,r_en,w_en,data_in,index_in,data_out,index_out,fifo_empty,fifo_full);
  parameter CAP_WIDTH = 5;
  parameter D_WIDTH = 16;
  parameter I_WIDTH = 4;
  input clk;
  input rst;
  input r_en;
  input w_en;
  input[D_WIDTH-1:0] data_in;
  input[I_WIDTH-1:0] index_in;
  output reg[D_WIDTH-1:0] data_out;
  output reg[I_WIDTH-1:0] index_out;
  output wire fifo_empty;
  output wire fifo_full;
  
  reg[CAP_WIDTH-1:0] read_ptr,write_ptr,counter;
  reg[D_WIDTH-1:0] data_mem [2**CAP_WIDTH-1:0];
  reg[I_WIDTH-1:0] index_mem [2**CAP_WIDTH-1:0];
  always @(posedge clk or negedge rst)
  begin
    if (!rst)
      begin
        read_ptr = 0;
        write_ptr = 0;
        counter = 0;
        index_out = 0;
        data_out = 0;
      end
    else
      case({r_en,w_en})
        2'b00:counter = counter;
        2'b01: // start write
        begin
          data_mem[write_ptr] = data_in;
          index_mem[write_ptr] = index_in;
          counter = counter + 1;
          write_ptr = (write_ptr == 2**CAP_WIDTH - 1)?0:write_ptr + 1;
        end
        2'b10: // start read
        begin
          data_out = data_mem[read_ptr];
          index_out = index_mem[read_ptr];
          counter = counter - 1;
          read_ptr = (read_ptr == 2**CAP_WIDTH - 1)?0:read_ptr + 1;
        end
        2'b11: // read and write
        begin
          if (counter == 0) // directly output
            begin
              data_out = data_in;
              index_out = index_in;
            end
          else
            begin
              data_mem[write_ptr] = data_in;
              index_mem[write_ptr] = index_in;
              data_out = data_mem[read_ptr];
              index_out = index_mem[read_ptr];
              write_ptr = (write_ptr == 2**CAP_WIDTH - 1)?0:write_ptr + 1;
              read_ptr = (read_ptr == 2**CAP_WIDTH - 1)?0:read_ptr + 1;
            end
        end
      endcase
  end
  assign fifo_empty = (counter == 0);
  assign fifo_full = (counter == 15);
endmodule
