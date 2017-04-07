module multiple(a,b,product,clk,rst,en);
  input[15:0] a;
  input[15:0] b;
  input clk;
  input rst;
  input en;
  output reg [31:0] product;
  reg[31:0] tmp_p;
  reg[1:0] current_state;
  reg[1:0] next_state;
  parameter IDLE = 2'b00, MUL = 2'b01, CPS = 2'b10, OUT = 2'b11;
  always @(posedge clk or negedge rst)
    begin
      if (!rst)
        current_state <= IDLE;
      else
        current_state <= next_state;
    end
  
  always @(current_state,en)
    begin
      next_state = 2'bxx;
      case (current_state)
        IDLE: 
          if (en)
            next_state = MUL;
          else
            next_state = IDLE;
        MUL:
          next_state = CPS;
        CPS:
          next_state = OUT;
        OUT:
          next_state = IDLE;
      endcase
    end
  
  always @(posedge clk or negedge rst)
    begin
      if (!rst)
        tmp_p <= 32'h00000000;
      else
        begin
          case (next_state)
            MUL:
              begin
                tmp_p <= a[14:0]*b[14:0];
              end
            CPS:
              begin
                tmp_p[31] <= a[15] ^ b[15];
              end
            OUT:
              product <= tmp_p;
            default: ;
          endcase
        end
    end
  endmodule
      
  