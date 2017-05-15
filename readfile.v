module readfile();
  reg [7:0] mem[0:3];
  reg [7:0] a;
  initial
  begin
    $readmemb("1.txt",mem);
    #5 a<=mem[0];
  end
endmodule