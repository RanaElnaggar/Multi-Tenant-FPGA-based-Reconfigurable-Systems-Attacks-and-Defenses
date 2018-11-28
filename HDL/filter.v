module filter(
output [31:0] out_0, 
output [31:0] out_1, 

output compr_rec,
					output  change_state, 
					output  [2:0] dp_mode_,
					output  [2:0] next_state,
				  
					input  resp_rec, 
				output  [2:0] outparam,
    input [11:0] p0,
    input [11:0] p1,
    input [11:0] p2,
    input [11:0] p3,
    input [11:0] p5,
    input [11:0] p6,
    input [11:0] p7,
    input [11:0] p8,
    output [11:0] q,

	
	///////Add SipHash////////////
	
	//add inputs and outputs and its instantiations////
		input clk,

input resetn,
 input             initalize,
                    input            compress,
                    input             finalize,
                    input            long,

                    input [3 : 0]    compression_rounds,
                    input  [3 : 0]    final_rounds,

                    input  [31 : 0]   mi0,
                    input  [31 : 0]   mi1,

                 output        ready,
                  output [31:0]   siphash_word0,
				                    output [31:0]   siphash_word1,

                     output        siphash_word_valid,
                    input block, output done_init);
endmodule 