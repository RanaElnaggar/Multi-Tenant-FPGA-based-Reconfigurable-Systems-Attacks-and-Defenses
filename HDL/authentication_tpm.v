
//This file is used to implement the secure authentication module SAM in our hardwrae Demo
//generates the challenges 
module LFSR (
    input clock,
    input reset,
    output [63:0] rnd 
    );
 
reg [63:0] random, random_next, random_done;
reg [5:0] count, count_next; //to keep track of the shifts
wire feedback = random[63] ^ random[62] ^ random[60] ^ random[59]; 

always @ (posedge clock or posedge reset)
begin
 if (!reset)
 begin
  random <= 64'hF; //An LFSR cannot have an all 0 state, thus reset to FF
  count <= 0;
 end
  
 else
 begin
  random <= random_next;
  count <= count_next;
 end
end
 
always @ (*)
begin
 random_next = random; //default state stays the same
 count_next = count;
   
  random_next = {random[62:0], feedback}; //shift left the xor'd every posedge clock
  count_next = count + 1;
 
 if (count == 64)
 begin
  count = 0;
  random_done = random; //assign the random number to output after 13 shifts
 end
  
end
 
 
assign rnd = random_done;
 
endmodule


module authentication_tpm(
compr_rec,

challenge_received,//input from SW
comparison_done, //response from hardware to SW 

response_of_challenge_rr0_0, //
response_of_challenge_rr0_1,
challenge_rr0_0,
challenge_rr0_1,

response_of_challenge_SW0_0,

challenge_SW0_0,

response_of_challenge_SW0_1,

challenge_SW0_1,

 initalize,
                         compress,
                       finalize,
                         long,

                    compression_rounds,
                final_rounds,

clk ,

resetn,

block_0,block_sw,
rrid,  
update, 
rmid_target,//monitor reconfig manager
reconf_done,// coming from PCAP
resp_done0, //for region 
resp_done_SW_0, //for SW region 
 ready0, ready_SW, activate_SW,
 rd_sobel, rd_gaussian, rd_sw_g, rd_sw_s,
 state_, next_state_,response_done_hw,
 					 resp_rec,done_init, 
					 out_rr0_0, out_rr0_1,out_sw_0, out_sw_1
/////////////////// for hardware only now//////////
);
input compr_rec;
output reg [31:0] out_rr0_0;
output reg [31:0] out_rr0_1;
output reg [31:0] out_sw_0;
output reg [31:0] out_sw_1;

					output reg resp_rec;
output reg block_sw;
output reg [31:0] challenge_rr0_0;
output reg [31:0] challenge_rr0_1;
input done_init;
 output reg            initalize;
      output                reg            compress;
            output       reg            finalize;
            output         reg            long;

            output         reg [3 : 0]    compression_rounds;
            output         reg [3 : 0]    final_rounds;
             
                   
					output wire rd_sobel, rd_gaussian, rd_sw_g, rd_sw_s;
                     wire            ready_sobel, ready_gaussian, ready_SW0_g, ready_SW0_s;
                  input wire    ready0, ready_SW;
				  output reg activate_SW;
      assign     rd_sobel=         ready_sobel; 
	     assign     rd_gaussian=         ready_gaussian; 
		    assign     rd_sw_g=         ready_SW0_g; 
			
input  [31:0] response_of_challenge_rr0_0;
input  [31:0] response_of_challenge_rr0_1;
input challenge_received;
output reg comparison_done;

input  [31:0] response_of_challenge_SW0_0;
input  [31:0] response_of_challenge_SW0_1;

output reg [31:0] challenge_SW0_0;
output reg [31:0] challenge_SW0_1;

input clk ;

input resetn;

output reg block_0;
input [3:0] rrid; //reconf manager input 
input update; 
input [3:0]  rmid_target; //reconf manager
input reconf_done;// from PCAP
input resp_done_SW_0; 
input resp_done0; 
parameter SIZE = 4          ;
parameter IDLE  = 4'b000,UPDATE = 4'b001,SEND_CHALLENGE = 4'b010, after_init=4'b1001, compress_0=4'b011, after_compress_0=4'b1010, compress_1=4'b100,after_compress_1=4'b1011, after_finalize=4'b101,WAIT_4_RESP=4'b110, REC_RESP=4'b111, COUNTS=4'b1000 ;

reg   [SIZE-1:0]          state        ;// Seq part of the FSM
 reg   [SIZE-1:0]          next_state   ;// combo part of FSM
 output   [SIZE-1:0]          state_        ;// Seq part of the FSM
  output   [SIZE-1:0]          next_state_   ;// combo part of FSM
  output response_done_hw;
  assign response_done_hw=resp_done0;
  assign state_=state;
  assign next_state_=next_state;
 reg [3:0] count;
//reg [63:0] expected_rr0;
//reg [63:0] expected_rr1;
//reg [63:0] expected_rr2;
wire [63:0] response_sobel;
wire [63:0] response_gaussian;
wire [63:0] response_sw_sobel;
wire [63:0] response_sw_gaussian;

//reg resp_done;
LFSR LFSR_0(
    .clock(clk),
    .reset(resetn),
    .rnd(rand_ch) 
    );
wire [63:0] rand_ch;
 wire resp_done_isobel,resp_done_igaussian,resp_done_isw_sobel,resp_done_isw_gaussian;
reg [63:0] out_pseudo ;
reg attack0;       


/////The output of these modules (core_sobel, core_gaussian, core_sw_s, siphash_core core_sw_g) can be used to check if the hardware tasks are registered in the system (not used in the current demo)
siphash_core core_sobel(
                    // Clock and reset.
                    .clk(clk),
                    .reset_n(resetn),

                    .initalize(initalize),
                    .compress(compress),
                    .finalize(finalize),
                    .long(long),

                    .compression_rounds(compression_rounds),
                    .final_rounds(final_rounds),
                    .key(128'h0f0e0d0c0b0b090809706050403020100),
                    .mi(out_pseudo),

                   .ready(ready_sobel),
                    .siphash_word(response_sobel),
                    .siphash_word_valid(resp_done_isobel)
                   );
 /////The output of these modules can be used to check if the software and hardware tasks are registered (not used in the current demo)                  
siphash_core core_gaussian(
                    // Clock and reset.
                    .clk(clk),
                    .reset_n(resetn),

                    .initalize(initalize),
                    .compress(compress),
                    .finalize(finalize),
                    .long(long),

                    .compression_rounds(compression_rounds),
                    .final_rounds(final_rounds),
                    .key(128'h0f0e0d0c0b0a0908f7060504f30201000),
                    .mi(out_pseudo),

                   .ready(ready_gaussian),
                    .siphash_word(response_gaussian),
                    .siphash_word_valid(resp_done_igaussian)
                   );
                                               
siphash_core core_sw_s(
                    // Clock and reset.
                    .clk(clk),
                    .reset_n(resetn),

                    .initalize(initalize),
                    .compress(compress),
                    .finalize(finalize),
                    .long(long),

                    .compression_rounds(compression_rounds),
                    .final_rounds(final_rounds),
                    .key(128'h0f0e0ddd0b0b090809706050403020ccc),
                    .mi(out_pseudo),

                   .ready(ready_SW0_g),
                    .siphash_word(response_sw_sobel),
                    .siphash_word_valid(resp_done_isw_sobel)
                   );
                            
                            
siphash_core core_sw_g(
                    // Clock and reset.
                    .clk(clk),
                    .reset_n(resetn),

                    .initalize(initalize),
                    .compress(compress),
                    .finalize(finalize),
                    .long(long),

                    .compression_rounds(compression_rounds),
                    .final_rounds(final_rounds),
                    .key(128'h0f0e0ddd0b0b090809706050403020100),
                    .mi(out_pseudo),

                   .ready(ready_SW0_s),
                    .siphash_word(response_sw_gaussian),
                    .siphash_word_valid(resp_done_isw_gaussian)
                   );
                                                                           
  
///this module determines which module should be configured in the partial reconfiguration region according to the input from the reconfiguration manager (used in the simulation for attack localization, not currently used in hardware demo)
/*LUT_ LUT_am
 (.clk(clk),.rrid(rrid),
 .resetn(resetn), 
.update_val(rmid_target),
.update(update),
.rmid_out0(rmid_out0), 
.rmid_out1(rmid_out1),
 .rmid_out2(rmid_out2)

);
*/
//state assignement
 always @ (resp_done_isobel or resp_done_igaussian or resp_done_isw_sobel or resp_done_isw_gaussian or state or update or rmid_target or rrid or reconf_done or resp_done0 or clk or resetn or  ready_sobel or ready_gaussian or ready_SW0_g or ready_SW0_s)
 begin : states_fsm
  next_state = 3'b001;
  case(state)
    IDLE : if (update == 1'b1) begin
                 next_state = UPDATE;
                 end
                else if (resetn == 1'b0) begin
                  next_state = IDLE;
               end
    UPDATE : if (reconf_done == 1'b1) begin
                 next_state = SEND_CHALLENGE;
                 end
                else if (resetn == 1'b0) begin
                  next_state = IDLE;
               end
               else 
               begin 
                next_state = UPDATE;
               end
     SEND_CHALLENGE : if (resetn == 1'b0) begin
                  next_state = IDLE;
               end
                else if (challenge_received==1 && done_init==1) begin
                 next_state = after_init;
                end 
				else 
				begin 
				next_state = SEND_CHALLENGE;

				end
     after_init : if (resetn == 1'b0) begin
                  next_state = IDLE;
               end
             //  else if (ready_sobel==0 && ready_gaussian==0 && ready_SW0_g==0 &&  ready_SW0_s==0) //possible problem
			 else if (ready0==0)
			   begin
                  next_state = compress_0;
                end
                else begin
                 next_state = after_init;
                end

  compress_0 : if (resetn == 1'b0) begin
                  next_state = IDLE;
               end
                else if (compr_rec==1) begin 
                 next_state = after_compress_0;
                end
                else begin 
                                 next_state = compress_0;

                end

after_compress_0: if (resetn == 1'b0) begin
                  next_state = IDLE;
               end
             //  else if (ready_sobel==0 && ready_gaussian==0 && ready_SW0_g==0 &&  ready_SW0_s==0) //possible problem
			 else if (ready0==0)			   begin
                  next_state =compress_1;
                end
                else begin
next_state=after_compress_0;
end

 compress_1 : if (resetn == 1'b0)
	  begin
                  next_state = IDLE;
               end
                   else if (compr_rec==1) begin 
                             next_state = after_compress_1;
                            end
                            else begin 
                                             next_state = compress_1;
            
                            end
    after_compress_1:if (resetn == 1'b0) begin
                  next_state = IDLE;
               end
             //  else if (ready_sobel==0 && ready_gaussian==0 && ready_SW0_g==0 &&  ready_SW0_s==0) //possible problem
			 else if (ready0==0)			   begin
                  next_state =WAIT_4_RESP;
                end
                else begin
                 next_state = after_compress_1;
                end

      WAIT_4_RESP: if (resetn == 1'b0)
	  begin
                  next_state = IDLE;
               end
               else 
               begin 
               next_state = after_finalize; //possible problem
               end 
after_finalize:if (resetn == 1'b0) begin
                  next_state = IDLE;
               end
              // else if (resp_done_isobel ==1 && resp_done_igaussian==1 && resp_done_isw_sobel==1 && resp_done_isw_gaussian==1 && resp_done_SW_0==1) begin
			 else if (  resp_done0 ==1 && resp_done_SW_0 ==1)//for SW region 
			 begin
                  next_state =REC_RESP;
                end
                else begin
                 next_state = after_finalize;
                end

      REC_RESP:  if (resetn == 1'b0) begin
                  next_state = IDLE;
               end  
               else if (update==1 ) begin
                  next_state = UPDATE;
                  end 
                  else begin
                  next_state = COUNTS;
		 count=0;
                  end 
                  
                  
      COUNTS:if (resetn == 1'b0) begin
                  next_state = IDLE;
                  count=0;
               end
       else if (update==1 ) begin
                  next_state = UPDATE;
		count=0;
                  end 
       else if (count==1000 ) begin
                  next_state = SEND_CHALLENGE;
                  end 
      else begin 
        next_state = COUNTS;
        end 
     default : next_state = IDLE;
    endcase
 end //end always




 always @ (posedge clk)
 begin : next_state_assignement 
   if (resetn == 1'b0) begin
   state <= IDLE;
  end
   else begin
    state <= next_state;
   end
 end

 always @ (posedge clk)
 begin : output_assignement
 if (resetn == 1'b0) begin
    block_0 <=  1'b0;
    block_sw  <=  1'b0;
  
    challenge_rr0_0<= 32'h0;
        challenge_rr0_1<= 32'h0;

    challenge_SW0_0<= 32'h0;
    challenge_SW0_1<= 32'h0;
    
compression_rounds<=4'h2;
initalize<=0;
compress<=0;
final_rounds<=4'h4;
attack0<=0;
long<=0;
out_sw_0<=0;
out_sw_1<=0;
out_rr0_0<=0;
out_sw_0<=1;
 end
  else begin
   case(state)
     IDLE : begin
                  block_0 <=  1'b0;
    block_sw  <=  1'b0;

    challenge_rr0_0<= 32'h0;
        challenge_rr0_1<= 32'h0;

    challenge_SW0_0<= 32'h0;
    challenge_SW0_1<= 32'h0;
  
compression_rounds<=4'h2;
final_rounds<=4'h4;
initalize<=0;
compress<=0;
attack0<=0;
long<=0;
activate_SW<=0;
		 resp_rec<=0;
		 out_sw_0<=0;
		 out_sw_1<=0;
		 
		 
                end
    UPDATE : begin
    block_0 <=  1'b0;
    block_sw  <=  1'b0;
    challenge_rr0_0<= 32'h0;
        challenge_rr0_1<= 32'h0;

    challenge_SW0_0<= 32'h0;
    challenge_SW0_1<= 32'h0;
compression_rounds<=4'h2;
final_rounds<=4'h4;
attack0<=0;
long<=0;
                 end
     SEND_CHALLENGE : begin

    block_0 <=  1'b1;
      block_sw  <=  1'b1;
    challenge_rr0_0<= rand_ch[31:0];
          challenge_rr0_1<= rand_ch[63:32];
  
      challenge_SW0_0<= rand_ch[31:0];
      challenge_SW0_1<= rand_ch[63:32];
   
    out_pseudo<= 64'h12;
    initalize <= 1;
    compress <= 0;
    compression_rounds<=4'h2;
final_rounds<=4'h4;
finalize<=0;
attack0<=0;

long<=0;

                  end
after_init:
 begin
    block_0 <=  1'b1;
 block_sw<=1;
    challenge_rr0_0<= rand_ch[31:0];
     challenge_rr0_1<=  rand_ch[63:32];

 challenge_SW0_0<= rand_ch[31:0];
 challenge_SW0_1<= rand_ch[63:32];
   
    out_pseudo<= 64'h12;
    initalize <= 0;
    compress <= 0;
    compression_rounds<=4'h2;
final_rounds<=4'h4;
attack0<=0;
long<=0;

                  end

     compress_0: begin

    block_0 <=  1'b1;
   block_sw<=1;
    challenge_rr0_0<= rand_ch[31:0];
       challenge_rr0_1<=  rand_ch[63:32];

   challenge_SW0_0<= 32'h12;
   challenge_SW0_1<= 32'h0;
	
    out_pseudo<= 64'h12;
initalize <= 0;
compress <= 1;
compression_rounds<=4'h2;
final_rounds<=4'h4;
attack0<=0;
long<=0;
                  end

after_compress_0: begin
    block_0 <=  1'b1;
     block_sw<=1;

    challenge_rr0_0<= rand_ch[31:0];
        challenge_rr0_1<=rand_ch[63:32];

    challenge_SW0_0<= rand_ch[31:0];
    challenge_SW0_1<= rand_ch[63:32];
    out_pseudo<= 64'h12;
initalize <= 0;
compress <= 0;
compression_rounds<=4'h2;
final_rounds<=4'h4;
attack0<=0;
long<=0;
                  end

     compress_1: begin
   
    block_0 <=  1'b1;
    block_sw<=1;

    challenge_rr0_0<= rand_ch[31:0];
        challenge_rr0_1<= rand_ch[63:32];

    challenge_SW0_0<= rand_ch[31:0];
    challenge_SW0_1<= rand_ch[63:32];
    
    out_pseudo<= 64'h12;
initalize <= 0;
compress <= 1;
compression_rounds<=4'h2;
final_rounds<=4'h4;
attack0<=0;
long<=0;
                  end

after_compress_1:
begin

    block_0 <=  1'b1;
   block_sw<=1;
    challenge_rr0_0<= rand_ch[31:0];
       challenge_rr0_1<= rand_ch[63:32];

   challenge_SW0_0<=rand_ch[31:0];
   challenge_SW0_1<=rand_ch[63:32];
   
   
    out_pseudo<= 64'h12;
initalize <= 0;
compress <= 0;
compression_rounds<=4'h2;
final_rounds<=4'h4;
attack0<=0;
long<=0;
                  end

    WAIT_4_RESP: begin
   
    block_0 <=  1'b1;
   block_sw<=1;
    challenge_rr0_0<= rand_ch[31:0];
       challenge_rr0_1<= rand_ch[63:32];

   challenge_SW0_0<= rand_ch[31:0];
   challenge_SW0_1<= rand_ch[63:32];
    
    out_pseudo<= 64'h12;
    compress <= 0;
    finalize <= 1;
compression_rounds<=4'h2;
final_rounds<=4'h4;
attack0<=0;
long<=0;
                  end
                               
after_finalize:begin
    block_0 <=  1'b1;
      block_sw<=1;
	  
    challenge_rr0_0<=rand_ch[31:0];
	    challenge_rr0_1<=rand_ch[63:32];

    challenge_SW0_0<= rand_ch[31:0];
	challenge_SW0_1<= rand_ch[63:32];
    out_pseudo<= 64'h12;
    compress <= 0;
    finalize <= 1;
compression_rounds<=4'h2;
final_rounds<=4'h4;
attack0<=0;
long<=0;
                  end
    
     REC_RESP:begin 
     compression_rounds<=4'h2;
final_rounds<=4'h4;
      finalize <= 0;
    
long<=0;
	 resp_rec<=1;
    if  (response_of_challenge_rr0_1== response_of_challenge_SW0_1 &&response_of_challenge_rr0_0== response_of_challenge_SW0_0)
    begin
      block_0<=0;
attack0<=0;	
      block_sw<=0;
activate_SW<=1;
comparison_done<=1;
out_rr0_0<=response_of_challenge_rr0_0;
out_rr0_1<=response_of_challenge_rr0_1;
out_sw_0<=response_of_challenge_SW0_0;
out_sw_1<=response_of_challenge_SW0_1;

      end
    else 
    begin
      block_0<=1;
	        block_sw<=1;
comparison_done<=1;
attack0<=1;
activate_SW<=0;
out_rr0_0<=response_of_challenge_rr0_0;
out_rr0_1<=response_of_challenge_rr0_1;
out_sw_0<=response_of_challenge_SW0_0;
out_sw_1<=response_of_challenge_SW0_1;
      end
    challenge_rr0_0<= rand_ch[31:0];
          challenge_rr0_1<= rand_ch[63:32];
  
      challenge_SW0_0<= rand_ch[31:0];
      challenge_SW0_1<=rand_ch[63:32];
    
     end
     
     COUNTS:begin 
	 long<=0;
     compression_rounds<=4'h2;
final_rounds<=4'h4;
    challenge_rr0_0<= rand_ch[31:0];
    challenge_rr0_1<= rand_ch[63:32];

challenge_SW0_0<=rand_ch[31:0];
challenge_SW0_1<= rand_ch[63:32];
    count<=count+1;
     end 
    endcase
  end //else end
 end //always end
endmodule

