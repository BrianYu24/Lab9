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
logic [31:0] mixWord;
logic [31:0] mixInput;
logic [3:0] count;
logic [2:0] FUNC;
logic [1:0] word;

AES_Controller controller_inst(.*);

KeyExpansion keyExpansion_inst (
	.clk(CLK),
	.Cipherkey(AES_KEY),
	.KeySchedule
);

always_comb
begin
curKey = 127'b0;
case(count)
	4'd0: curKey = KeySchedule[127:0];
	4'd1: curKey = KeySchedule[255:128];
	4'd2: curKey = KeySchedule[383:256];
	4'd3: curKey = KeySchedule[511:384];
	4'd4: curKey = KeySchedule[639:512];
	4'd5: curKey = KeySchedule[767:640];
	4'd6: curKey = KeySchedule[895:768];
	4'd7: curKey = KeySchedule[1023:896];
	4'd8: curKey = KeySchedule[1151:1024];
	4'd9: curKey = KeySchedule[1279:1152];
	4'd10: curKey = KeySchedule[1407:1280];
endcase
end

InvShiftRows invShiftRows_inst (
	.data_in(curState), 
	.data_out(invShiftRowsOut)
);

InvSubBytes subBytes_inst[15:0] (.clk(CLK), .in(curState), .out(invSubBytesOut));

always_comb
begin
	unique case(word)
		2'd0:
			mixInput = curState[31:0];
		2'd1:
			mixInput = curState[63:32];
		2'd2:
			mixInput = curState[95:64];
		2'd3:
			mixInput = curState[127:96];
	endcase
end

InvMixColumns invMixColumns (
	.in(mixInput),
	.out(mixWord)
);

always_ff @ (posedge CLK)
begin
	if(RESET)
		AES_MSG_DEC <= 128'b0;
	else if(FUNC==6)
	begin
		AES_MSG_DEC <= 128'b0;
		curState <= AES_MSG_ENC;
	end
	else
	begin
		AES_MSG_DEC <= curState;
		curState <= nextState;
	end
end

always_comb
begin
	//curKey = 128'b0;
	case (FUNC)
		3'd0:
			nextState = curState;
		3'd1:
		begin
			nextState = curState;
		end
		3'd2:
		begin
			//KeySchedule[(count)*128+:127];
			nextState = curState ^ curKey;
		end
		3'd3:
			nextState = invShiftRowsOut;
		3'd4:
			nextState = invSubBytesOut;
		3'd5:
			unique case(word)
				2'd0:
					nextState = {curState[127:32],mixWord};
				2'd1:
					nextState = {curState[127:64],mixWord,curState[31:0]};
				2'd2:
					nextState = {curState[127:96],mixWord,curState[63:0]};
				2'd3:
					nextState = {mixWord,curState[95:0]};
				default:
					nextState = curState;
			endcase
		
		default: nextState = curState;
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
	
	enum logic [4:0] {Halted, StartState, KeyExpansion1, KeyExpansion2, KeyExpansion3, KeyExpansion4, KeyExpansion5, KeyExpansion6, AddRoundKey, InvShiftRows, InvSubBytes, InvMixColumns1, InvMixColumns2, InvMixColumns3, InvMixColumns4, FinishedWait, End} State, Next_state;

	always_ff @ (posedge CLK)
	begin
		if(RESET)
		begin
			State <= Halted;
			count <= 4'b0;
		end
		else if (State == End)
		begin
			count <= 4'b0;
			State <= Next_state;
		end
		else if(State == InvShiftRows)
		begin
			State <= Next_state;
			count <= count+4'b1;
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
		
		case (State)
			Halted :
			begin
				if (AES_START)
					Next_state = StartState;
			end
			StartState:
				Next_state = KeyExpansion1;
				
			KeyExpansion1:
				Next_state = KeyExpansion2;
			KeyExpansion2:
				Next_state = KeyExpansion3;
			KeyExpansion3:
				Next_state = KeyExpansion4;
			KeyExpansion4:
				Next_state = KeyExpansion5;
			KeyExpansion5:
				Next_state = KeyExpansion6;
			KeyExpansion6:
				Next_state = AddRoundKey;
			
			AddRoundKey :
			begin
				if(count == 0)
					Next_state = InvShiftRows;
				else if(count == 10)								////count == 10
					Next_state = FinishedWait;
				else
					Next_state = InvMixColumns1;
			end
					
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
			
			FinishedWait :
			begin
				if(AES_START)
					Next_state = FinishedWait;
				else
					Next_state = End;
			end
			
			End :
			begin
				if(AES_START)
					Next_state = StartState;
			end
			
		endcase
		
		case (State)
			Halted:;
			StartState:
				FUNC = 3'd6;
			End:
			begin
				AES_DONE = 1'b1;
			end
			FinishedWait:
			begin
				AES_DONE = 1'b1;
			end
			
			KeyExpansion1, KeyExpansion2,KeyExpansion3, KeyExpansion4,KeyExpansion5, KeyExpansion6:
				FUNC = 3'd1;
			AddRoundKey:
				FUNC = 3'd2;
			
			InvShiftRows:
				FUNC = 3'd3;
			
			InvSubBytes:
				FUNC = 3'd4;
			
			InvMixColumns1:
			begin
				FUNC = 3'd5;
				word = 2'd0;
			end
			
			InvMixColumns2:
			begin
				FUNC = 3'd5;
				word = 2'd1;
			end
			
			InvMixColumns3:
			begin
				FUNC = 3'd5;
				word = 2'd2;
			end
			
			InvMixColumns4:
			begin
				FUNC = 3'd5;
				word = 2'd3;
			end
			
			
			default: ;
		endcase
	end
endmodule
