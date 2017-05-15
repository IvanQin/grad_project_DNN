module nzaa_tb;
  
  reg clk_h;
  reg rst_n;
  reg clear;
  reg [4:0] th;
  reg [15:0] data_in;
  reg [255:0] weight_in;
  reg last_line;
  reg wr;
  wire [255:0] data_out;
  
  reg [15:0] data_mem[0:4095];
  reg [255:0] weight_mem[0:258047];
  
  integer i;
  integer j;
  integer f;
  
  nzaa nzaa_inst(clk_h, rst_n, clear, th, data_in, weight_in, last_line, wr, data_out);
  
 	initial begin
	  rst_n = 1;	
		clk_h = 1;
	end
	
	always
	#2 clk_h = ~clk_h;
	
  reg [100*8:1] filename;
  integer ii;	

	
//	initial
//  begin
//    $readmemb("D:/software/Deep_Learning_Tools/MatConvNet/matconvnet-1.0-beta20/examples/aprx_git/CNN/matlab/aprx/fc8_x.txt",data_mem);
//    $readmemb("D:/software/Deep_Learning_Tools/MatConvNet/matconvnet-1.0-beta20/examples/aprx_git/CNN/matlab/aprx/fc8_w.txt",weight_mem);
//  end
	
	initial begin
//	  $dumpfile("nzaa_px.vcd");
//    $dumpvars(0,nzaa_tb);
	  th = 5'b11111;
	  wr = 1'b0;
	  clear = 1'b0;
	  last_line = 1'b0;
	  rst_n = 0;
	  #8 rst_n = 1;
    $readmemb("./data/fc8_w.txt",weight_mem);
//    
//    for (ii=1; ii<101; ii=ii+1) begin
//		  // th = 3 -> 2^(-10)
//		  th = 5'b00011;
//	    wr = 1'b0;
//		  $sformat(filename,"./x%0d.txt", ii);
//		  $readmemb(filename,data_mem);
//      $sformat(filename,"./th3o%0d.txt", ii);
//      f = $fopen(filename,"w");
//		  for (j=0; j< 63; j = j + 1) begin
//		    for (i = 0; i < 4096; i = i + 1) begin
//	       data_in = data_mem[i];
//	       weight_in = weight_mem[i+ j*4096];
//	       #10;
//	      end
//	      #10 wr = 1'b1;
//	      #10 wr = 1'b0;
//		    $fwrite(f,"%b\n", data_out);
////		    $display("data_out %d  = %b", j, data_out);
//	      #10 rst_n = 0;
//		    #10 rst_n = 1;
//	    end
//	    $fclose(f);  
//	   end
//    
//    
// 	  for (ii=1; ii<101; ii=ii+1) begin
//		  // th = 4 -> 2^(-10)
//		  th = 5'b00100;
//	    wr = 1'b0;
//		  $sformat(filename,"./x%0d.txt", ii);
//		  $readmemb(filename,data_mem);
//      $sformat(filename,"./th4o%0d.txt", ii);
//      f = $fopen(filename,"w");
//		  for (j=0; j< 63; j = j + 1) begin
//		    for (i = 0; i < 4096; i = i + 1) begin
//	       data_in = data_mem[i];
//	       weight_in = weight_mem[i+ j*4096];
//	       #10;
//	      end
//	      #10 wr = 1'b1;
//	      #10 wr = 1'b0;
//		    $fwrite(f,"%b\n", data_out);
////		    $display("data_out %d  = %b", j, data_out);
//	      #10 rst_n = 0;
//		    #10 rst_n = 1;
//	    end
//	    $fclose(f);  
//	   end
//    
//		for (ii=1; ii<101; ii=ii+1) begin
//		  // th=5, -> 2^(-8)
//		  th = 5'b00101;
//	    wr = 1'b0;
//		  $sformat(filename,"./x%0d.txt", ii);
//		  $readmemb(filename,data_mem);
//      $sformat(filename,"./th5o%0d.txt", ii);
//      f = $fopen(filename,"w");
//		  for (j=0; j< 63; j = j + 1) begin
//		    for (i = 0; i < 4096; i = i + 1) begin
//	       data_in = data_mem[i];
//	       weight_in = weight_mem[i+ j*4096];
//	       #10;
//	      end
//	      #10 wr = 1'b1;
//	      #10 wr = 1'b0;
//		    $fwrite(f,"%b\n", data_out);
////		    $display("data_out %d  = %b", j, data_out);
//	      #10 rst_n = 0;
//		    #10 rst_n = 1;
//	    end
//	    $fclose(f);  
//	   end
//	   
//	   for (ii=1; ii<101; ii=ii+1) begin
//		  // th = 6 , -> 2^(-7)
//		  th = 5'b00110;
//	    wr = 1'b0;
//		  $sformat(filename,"./x%0d.txt", ii);
//		  $readmemb(filename,data_mem);
//      $sformat(filename,"./th6o%0d.txt", ii);
//      f = $fopen(filename,"w");
//		  for (j=0; j< 63; j = j + 1) begin
//		    for (i = 0; i < 4096; i = i + 1) begin
//	       data_in = data_mem[i];
//	       weight_in = weight_mem[i+ j*4096];
//	       #10;
//	      end
//	      #10 wr = 1'b1;
//	      #10 wr = 1'b0;
//		    $fwrite(f,"%b\n", data_out);
////		    $display("data_out %d  = %b", j, data_out);
//	      #10 rst_n = 0;
//		    #10 rst_n = 1;
//	    end
//	    $fclose(f);  
//	   end
	   
	   	for (ii=1; ii<21; ii=ii+1) begin
		  // th = 7, -> 2^(-6)
		  th = 5'b10010;
		  wr = 1'b0;
		  $sformat(filename,"./data/x/x%0d.txt", ii);
		  $readmemb(filename,data_mem);
		  $sformat(filename,"./data/output/thfohs%0d.txt", ii);
		  f = $fopen(filename,"w");
		  for (j=0; j< 63; j = j + 1) begin
			   clear = 1;	    
		    for (i = 0; i < 4096; i = i + 1) begin
				#4 clear = 0;
				last_line = 1'b0;
				data_in = data_mem[i];
				weight_in = weight_mem[i+ j*4096];
	        end
		  #4 last_line = 1'b1;
		  #4 ;
		  #4 ;
	      #4 wr = 1'b1;
	      #4 wr = 1'b0;
		  #4 $fwrite(f,"%b\n", data_out);
//		    $display("data_out %d  = %b", j, data_out);
	    end
	    $fclose(f);  
	   end
	   
//	  #10 wr = 1'b1;
	  $stop;
	  

	end

endmodule


//	  $display("data_out   = %b", data_out);
	  
/* 	  $display("data_out 1  = %b", data_out[15:0]);
	  $display("data_out 2  = %b", data_out[31:16]);
	  $display("data_out 3  = %b", data_out[3*16-1:2*16]);
	  $display("data_out 4  = %b", data_out[4*16-1:3*16]);
	  $display("data_out 5  = %b", data_out[5*16-1:4*16]);
	  $display("data_out 6  = %b", data_out[6*16-1:5*16]);
	  $display("data_out 7  = %b", data_out[7*16-1:6*16]);
	  $display("data_out 8  = %b", data_out[8*16-1:7*16]);
	  $display("data_out 9  = %b", data_out[9*16-1:8*16]);
	  $display("data_out 10 = %b", data_out[10*16-1:9*16]);
	  $display("data_out 11 = %b", data_out[11*16-1:10*16]);
	  $display("data_out 12 = %b", data_out[12*16-1:11*16]);
	  $display("data_out 13 = %b", data_out[13*16-1:12*16]);
	  $display("data_out 14 = %b", data_out[14*16-1:13*16]);
	  $display("data_out 15 = %b", data_out[15*16-1:14*16]);
	  $display("data_out 16 = %b", data_out[16*16-1:15*16]); */
