module process_unit(
  s_clk,
  m_clk,
  rst,
  fetch_enable,
  a,
  b,
  weight_index,// if the weight matrix is N*M, then 0 <= weight_index < M
  finish_enable,
  sum
);
parameter IDLE = 3'b000, FETCH = 3'b001, MUL = 3'b010, ACC = 3'b011, STORE = 3'b100, OUT = 3'b101;
parameter I_WIDTH = 4;

input s_clk;
input m_clk;
input rst;
input fetch_enable;
input[15:0] a;
input[15:0] b;
input[I_WIDTH-1:0] weight_index;
input finish_enable;
output reg[15:0] sum;
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
reg dest_data_out;
wire dest_data_in;
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
    if (finish_enable)
      next_state = OUT;
    else 
      begin
      if (fetch_enable)
        next_state = FETCH;
      else next_state = IDLE;
      end
    FETCH:
    next_state = MUL;
    MUL:
    next_state = ACC;
    ACC:
    next_state = STORE;
    STORE:
    if (finish_enable)
      next_state = OUT;
    else next_state = IDLE;
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
        end
        FETCH:
        begin
          a_m <= a;
          b_m <= b;
          read_en <= 1'b1;
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
        end
        OUT: // need modify
        begin
          write_en <= 1'b0;
          sum <= sum_m[31:16];
        end
        default: ;
      endcase
    end
end
multiple mul1 (.a(a_m),.b(b_m), .product(product_m),.clk(s_clk),.rst(rst),.en(mul_en));
adder add1(.a(sum_m),.b(product_m),.cin(cin), .cout(cout), .sum(sum_o), .clk(s_clk), .rst(rst),.en(acc_en));
dest_reg dest1(.clk(s_clk),.rst(rst),.index_in(weight_index),.w_en(right_en),.data_out(dest_data_in),.data_in(dest_data_out),.r_en(read_en));
endmodule









