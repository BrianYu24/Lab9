/************************************************************************
AES Decryption Core Logic

Dong Kai Wang, Fall 2017

For use with ECE 385 Experiment 9
University of Illinois ECE Department
************************************************************************/

module AES (
	input	 logic CLK,
	input  logic RESET,
	input  logic AES_START,
	output logic AES_DONE,
	input  logic [127:0] AES_KEY,
	input  logic [127:0] AES_MSG_ENC,
	output logic [127:0] AES_MSG_DEC
);

logic [1407:0] KeySchedule;
logic [127:0] curKey, curState, nextState, invShiftRowsOut, invSubBytesOut;
logic [32:0] mixWord[3:0];
logic [3:0] count;
logic [2:0] FUNC;
logic [1:0] word;

AES_Controller controller_inst(.*);

KeyExpansion keyExpansion_inst (
	.clk(CLK),
	.Cipherkey(AES_KEY),
	.KeySchedule
);

assign curKey = KeySchedule[count*127+127:count*127];

InvShiftRows invShiftRows_inst (
	.data_in(curState), 
	.data_out(invShiftRowsOut)
);

SubBytes subBytes_inst (
	.clk(CLK),
	in(curState),
	out(invSubBytesOut)
);

InvMixColumns invMixColumns (
	in(curState[word*32+32:word*32]),
	out(mixWord[word])
);

always_ff @ (posedge CLK)
begin
	if(RESET)
		AES_MSG_DEC <= 127'b0;
	else if(AES_START)
	begin
		AES_MSG_DEC <= 127'b0;
		state <= nextState;
	end
	else
	begin
		AES_MSG_DEC <= state;
		state <= nextState;
	end
end

always_comb
begin
	case (FUNC):
		2'd0:
			nextState = curState;
		2'd2:
			nextState = curState^curKey;
		2'd3:
			nextState = invShiftRowsOut;
		2'd4:
			nextState = invSubBytesOut;
		2'd5:
			if(word == 3)
				nextState = {mixWord[0],mixWord[1],mixWord[2],mixWord[3]}'
			else
				nextState = curState;
		default:
			nextState = curState;
	endcase
end


endmodule

module AES_Controller (
	input logic CLK,
	input logic RESET,
	input logic AES_START,
	output logic AES_DONE,
	output logic [2:0] FUNC,
	output logic [1:0] word,
	output logic [3:0] count
);

	// FUNC: 0 - Halt, 2 - AddRoundKey, 3 - InvShiftRows, 4 - InvSubBytes, 5 - MixColumns
	
	enum logic [3:0] {Halted, AddRoundKey, InvShiftRows, InvSubBytes, InvMixColumns1, InvMixColumns2, InvMixColumns3, InvMixColumns4} State, Next_state;

	always_ff @ (posedge CLK)
	begin
		if(RESET)
		begin
			State <= Halted;
			count <= 4'b0;
		end
		else if(State == InvShiftRows)
		begin
			State <= Next_state;
			count <= count+1;
		end
		else
			State <= Next_state;
	end

	always_comb
	begin
		Next_state = State;
		
		AES_DONE = 1'b0;
		word = 2'b0;
		FUNC = 3'b0;
		
		unique case (State)
			Halted :
				if (AES_START)
					Next_state = AddRoundKey;
			
			AddRoundKey :
				if(count == 0)
					Next_state = InvShiftRows;
				else if(count == 9)
					Next_state = Halted;
				else
					Next_state = InvMixColumns1;
					
			InvShiftRows :
				Next_state = InvSubBytes;
			
			InvSubBytes :
				Next_state = AddRoundKey;
			
			InvMixColumns1 :
				Next_state = InvMixColumns2;
			InvMixColumns2 :
				Next_state = InvMixColumns3;
			InvMixColumns3 :
				Next_state = InvMixColumns4;
			InvMixColumns4 :
				Next_state = InvShiftRows;
		endcase
		
		case (State)
			Halted:
				count = 4'b0;
				AES_DONE = 1'b1;
			
			AddRoundKey:
				FUNC = 3'd2;
			
			InvShiftRows:
				FUNC = 3'd3;
			
			InvSubBytes:
				FUNC = 3'd4;
			
			InvMixColumns1:
				FUNC = 3'd5;
				word = 2'd0;
			
			InvMixColumns2:
				FUNC = 3'd5;
				word = 2'd1;
			
			InvMixColumns3:
				FUNC = 3'd5;
				word = 2'd2;
			
			InvMixColumns4:
				FUNC = 3'd5;
				word = 2'd3;
				
			default: ;
		endcase
	end
endmodule
