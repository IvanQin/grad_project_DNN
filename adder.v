module adder (a,b,cin,cout,sum,clk,rst,en);
  input [31:0] a,b;
  input cin;
  input clk;
  input rst;
  input en;
  output cout;
  output reg [31:0] sum; // reg definition is important
  reg[31:0] c_a;
  reg[31:0] c_b;
  reg sig; // the MSB of the compensation sum
  reg [2:0] current_state;
  reg [2:0] next_state;
  reg [31:0] c_sum;
  parameter IDLE = 3'b000, CPS1 = 3'b001, ADD = 3'b010, CPS2 = 3'b011, OUT = 3'b100;
  always @(posedge clk or negedge rst)
    begin 
      if(!rst)
        begin
          current_state <= IDLE;
        end
      else
        begin
          current_state <= next_state;
        end
    end
  always @(current_state,en)
    begin
      next_state = 3'bxxx;
      case (current_state)
        IDLE:
          begin
            if (en)
              next_state = CPS1;
            else
              next_state = IDLE;
          end
        CPS1:// cal compensation for the add
          begin
            next_state = ADD;
          end
        ADD: // execute add
          begin
            next_state = CPS2;
          end
        CPS2: // cal compensation of the result
          begin
          next_state = OUT;
          end
        OUT: // output
          begin
            next_state = IDLE;
          end
        default: next_state = IDLE;
      endcase
    end
  always@(posedge clk or negedge rst)
    begin
      if (!rst)
        begin
          sum<= 32'h0000;
        end
      else
        begin
          case (next_state)
              CPS1: // compensation for the adder
                begin
                  if (a[31]) // msb=1 means negative number 
                    c_a <= 1'b1 + {1'b1,~a[30:0]};
                  else c_a <= a;
                  if (b[31]) // msb=1 means negative number 
                    c_b <= 1'b1 + {1'b1,~b[30:0]};
                  else c_b <= b;
                end
              ADD:
                begin
                  {sig,c_sum} <= c_a + c_b + cin;
                end
              CPS2:
                begin
                  if (c_sum[31])
                    sum <= 1'b1 + {1'b1,~c_sum[30:0]};
                  else sum <= c_sum;
                end
            endcase
        end
    end
  endmodule
  
