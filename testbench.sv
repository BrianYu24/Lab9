module testbench();

timeunit 10ns;

timeprecision 1ns;


logic CLK;
logic RESET;
logic AES_START;
logic AES_DONE;
logic [127:0] AES_KEY;
logic [127:0] AES_MSG_ENC;
logic [127:0] AES_MSG_DEC;


 always begin : CLOCK_GENERATION
 
 #1 CLK = ~CLK;
 
 end
 
 initial begin
	CLK = 0;
 end

 
 AES tp(.*);
 
 initial begin: TEST_VECTORS
 
 RESET = 1;
 AES_START= 0;
 AES_KEY = 128'h000102030405060708090a0b0c0d0e0f;
 AES_MSG_ENC = 128'hdaec3055df058e1c39e814ea76f6747e;
 
 //test case 1
 #2 RESET = 0;
 #2 AES_START = 1;
 


 
 

 
 end

endmodule 