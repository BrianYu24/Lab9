/************************************************************************
Avalon-MM Interface for AES Decryption IP Core

Dong Kai Wang, Fall 2017

For use with ECE 385 Experiment 9
University of Illinois ECE Department

Register Map:

 0-3 : 4x 32bit AES Key
 4-7 : 4x 32bit AES Encrypted Message
 8-11: 4x 32bit AES Decrypted Message
   12: Not Used
	13: Not Used
   14: 32bit Start Register
   15: 32bit Done Register

************************************************************************/

module avalon_aes_interface (
	// Avalon Clock Input
	input logic CLK,
	
	// Avalon Reset Input
	input logic RESET,
	
	// Avalon-MM Slave Signals
	input  logic AVL_READ,					// Avalon-MM Read
	input  logic AVL_WRITE,					// Avalon-MM Write
	input  logic AVL_CS,						// Avalon-MM Chip Select
	input  logic [3:0] AVL_BYTE_EN,		// Avalon-MM Byte Enable
	input  logic [3:0] AVL_ADDR,			// Avalon-MM Address
	input  logic [31:0] AVL_WRITEDATA,	// Avalon-MM Write Data
	output logic [31:0] AVL_READDATA,	// Avalon-MM Read Data
	
	// Exported Conduit
	output logic [31:0] EXPORT_DATA		// Exported Conduit Signal to LEDs

);
	
	logic[31:0] Reg[16];
	logic[31:0] WriteData;
	logic Done;
	logic[127:0] Decrypt_Data;
	
	AES aes (
		.Clk, .RESET, .AES_START(Reg[14][0]), .AES_DONE(Done),
		.AES_KEY({Reg[0],Reg[1],Reg[2],Reg[3]}),
		.AES_MSG_ENC({Reg[4],Reg[5],Reg[6],Reg[7]}),
		.AES_MSG_DEC(Decrypt_Data),
	);
	
	
	always_ff @(posedge CLK)
	begin
		if (RESET)
		begin
			for (int i = 0; i<16; i++)
			{
				Reg[i] <= 32'b0;
			}
		end
		
		else if(AVL_WRITE && AVL_CS)
			Reg[AVL_ADDR] <= WriteData;
		
		else if(Done)
		begin
			Reg[15][0] = Done;
			Reg[8] = Decrypt_Data[127:96];
			Reg[9] = Decrypt_Data[95:64];
			Reg[10] = Decrypt_Data[63:32];
			Reg[11] = Decrypt_Data[31:0];
		end
			
		else if(AVL_READ && AVL_CS)
			AVL_READDATA <= REG[AVL_ADDR];
		
	end
	
	
	always_comb 
	begin
		
		case (byteenable)
			1111: WriteData = AVL_WRITEDATA;
			1100: WriteData = {AVL_WRITEDATA[31:16],{16{1'b0}}};
			0011: WriteData = {{16{1'b0}},AVL_WRITEDATA[15:0]};
			1000: WriteData = {AVL_WRITEDATA[31:24],{24{1'b0}}};
			0100: WriteData = {{8{1'b0}},AVL_WRITEDATA[23:16],{16{1'b0}}};
			0010: WriteData = {{16{1'b0}},AVL_WRITEDATA[15:8],{8{1'b0}}};
			0010: WriteData = {{24{1'b0}},AVL_WRITEDATA[7:0]};
		endcase
		
	end
	

endmodule
