module process_unit(
  s_clk,
  m_clk,
  rst,
  finish_enable,
  a, // one of the multiple number from queue
  b, // one of the multiple number from queue
  dest_data_in,
  dest_data_out,
  weight_index,// if the weight matrix is N*M, then 0 <= weight_index < M
  weight_index_out,
  fetch_enable,
  read_en,
  write_en, // active when needs to store data in the memory
  read_buffer_en,
  sum, // sum = sum + a*b
);
//dest_reg dest1(.clk(s_clk),.rst(rst),.index_in(weight_index),.w_en(right_en),.data_out(dest_data_in),.data_in(dest_data_out),.r_en(read_en));

parameter IDLE = 3'b000, FETCH = 3'b001, GET = 3'b010, MUL = 3'b011, ACC = 3'b100, STORE = 3'b101,OUT = 3'b110;
parameter I_WIDTH = 4;
parameter D_WIDTH = 16; 
input s_clk;
input m_clk;
input rst;
input fetch_enable;
input[15:0] a;
input[15:0] b;
output reg finish_enable;
output reg read_buffer_en;
input[I_WIDTH-1:0] weight_index;
output wire[I_WIDTH-1:0] weight_index_out;
//input finish_enable;
input[2*D_WIDTH-1:0] dest_data_in;
output read_en; // every read_en should be connected to 1 bit(4 bit total) of the port 'read_en' of dest_reg
output write_en; // every write_en should be connected to 1 bit(4 bit total) of the port 'read_en' of dest_reg
output reg[2*D_WIDTH-1:0] dest_data_out;
output reg[31:0] sum;
//reg [I_WIDTH-1:0] weight_index;
reg[2:0] current_state;
reg[2:0] next_state;
reg[15:0] a_m;
reg[15:0] b_m;
reg[31:0] sum_m;
wire[31:0] product_m;
wire[31:0] sum_o;
reg cin;
wire cout;
reg mul_en;
reg acc_en;
reg write_en;
reg read_en;

assign weight_index_out = weight_index;
always @(posedge m_clk or negedge rst)
begin
  if (!rst)
    current_state <= IDLE;
  else
    current_state <= next_state;
end

always @(current_state,finish_enable,fetch_enable)
begin
  next_state = IDLE;
  case (current_state)
    IDLE:
      begin
      if (fetch_enable)
        next_state = FETCH;
      else next_state = IDLE;
      end
    FETCH:
    next_state = GET;
    GET:
    next_state = MUL;
    MUL:
    next_state = ACC;
    ACC:
    next_state = STORE;
    STORE:
    //if (finish_enable)
      next_state = OUT;
    //else next_state = IDLE;
    OUT:
      next_state = IDLE;
    default: 
    next_state = IDLE;
  endcase    
end

always @(posedge m_clk or negedge rst)
begin
  if (!rst)
    begin
    a_m <= 32'bz;
    b_m <= 32'bz;
    sum_m <= 32'h0;
    sum <= 16'h0;
    cin <= 1'b0;
    mul_en <= 1'b0;
    acc_en <= 1'b0;
    read_en <= 1'b0;
    write_en <= 1'b0;
    finish_enable <= 1'b1;
    end
  else
    begin
      case (next_state)
        IDLE:
        begin
          a_m <= 32'bz;
          b_m <= 32'bz;
          sum_m <= 32'h0;
          sum <= 16'h0;
          cin <= 1'b0;
          mul_en <= 1'b0;
          acc_en <= 1'b0;
          read_en <= 1'b0;
          write_en <= 1'b0;
          read_buffer_en <= 1'b0;
          finish_enable <= 1'b1;
        end
        FETCH:
        begin
          finish_enable <= 1'b0;
          read_en <= 1'b1;
          read_buffer_en <=1'b1;
        end
        GET:
        begin
          a_m <= a;
          b_m <= b;
          sum_m <= dest_data_in;
        end
        MUL: // enable the multiple module
        begin
          read_en <= 1'b0;
          acc_en <= 1'b0;
          mul_en <= 1'b1;
        end
        ACC: // enable the accumulation module and disable the multiple module
        begin
          mul_en <= 1'b0;
          acc_en <= 1'b1;
        end
        STORE:
        begin
          acc_en <= 1'b0;
          write_en <= 1'b1;
          dest_data_out <= sum_o;
        end
        OUT: // need modify
        begin
          finish_enable <= 1'b1;
          //write_en <= 1'b0;
          sum <= sum_o[31:16];
        end
        default: ;
      endcase
    end
end

always @(posedge s_clk)
begin
  if (read_buffer_en) // avoid repeated read from the fifo, which will cause the pointer of the fifo to minusru
    read_buffer_en <= 1'b0;
end
multiple mul1 (.a(a_m),.b(b_m), .product(product_m),.clk(s_clk),.rst(rst),.en(mul_en));
adder add1(.a(sum_m),.b(product_m),.cin(cin), .cout(cout), .sum(sum_o), .clk(s_clk), .rst(rst),.en(acc_en));// sum_m is fetched in FETCH
//dest_reg dest1(.clk(s_clk),.rst(rst),.index_in(weight_index),.w_en(right_en),.data_out(dest_data_in),.data_in(dest_data_out),.r_en(read_en));
// do not include dest_reg in process_unit module because there is only one dest_reg
endmodule









