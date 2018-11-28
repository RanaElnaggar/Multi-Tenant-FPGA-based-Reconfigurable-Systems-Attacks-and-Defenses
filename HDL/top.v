module static_top(
//connection from TPM to PS 
//output SW challenge 
output [31:0] sw_0, output[31:0] sw_1, output[31:0] rr0, output[31:0] rr1,
input challenge_received,
output comparison_done,
input [31:0] response_of_challenge_SW0_0,
input [31:0] response_of_challenge_SW0_1,
output [31:0] challenge_SW0_0,
output [31:0] challenge_SW0_1,
output initalize,
output compress,
output finalize,
output long,
output [3:0]st,
output [3:0] nst,
output  rh,

output [3:0] compression_rounds,
output [3:0] final_rounds,

input clk ,

input resetn,

output block_sw,
input [3:0] rrid,  
input update, 
input [3:0] rmid_target,//monitor reconfig manager
input reconf_done,// coming from PCAP
input resp_done_SW_0, //for SW region 
input ready_SW, 
output activate_SW,
output [31:0] out_rr0_0, output [31:0] out_rr0_1, output [31:0] out_sw_0, output [31:0] out_sw_1,
///data from filter reconfig region 
    input [11:0] p0,
    input [11:0] p1,
    input [11:0] p2,
    input [11:0] p3,
    input [11:0] p5,
    input [11:0] p6,
    input [11:0] p7,
    input [11:0] p8,
    output [11:0] q,
	output [2:0] outparam,
	output wire change_state, 
					output wire [2:0] dp_mode_,
					output wire [2:0] next_state,    output [31:0]  out_0, output [31:0]  out_1);
//wire activate_SW;


//wire block_sw;
assign sw_0=response_of_challenge_SW0_0;
assign sw_1=response_of_challenge_SW0_1;
assign rr0=response_of_challenge_rr0_0;
assign rr1=response_of_challenge_rr0_1;


wire siphash_word_valid;
wire block_0;
wire [31:0] challenge_rr0_0;
wire [31:0] challenge_rr0_1;
wire [31:0] response_of_challenge_rr0_0;
wire [31:0] response_of_challenge_rr0_1;
wire ready1;
wire resp_rec_;

filter filter0(
  .out_0(out_0),
  .out_1(out_1),
   .p0(p0),
   .p1(p1),
   .p2(p2),
    .p3(p3),
    .p5(p5),
    .p6(p6),
    .p7(p7),
    .p8(p8),
    .q(q),
.initalize(initalize),
     .compress(compress),
                .finalize(finalize),
                 .long(long),

                   .compression_rounds(compression_rounds),
                    .final_rounds(final_rounds),
                   .mi0(challenge_rr0_0),
                  .mi1(challenge_rr0_1),

                 .ready(ready1),
                 .siphash_word0(response_of_challenge_rr0_0),
			.siphash_word1(response_of_challenge_rr0_1),

            .siphash_word_valid(siphash_word_valid),
              .block(block_0),
              		.clk(clk),
					.resp_rec(resp_rec_),
      
      .resetn(resetn),
	  .outparam(outparam),
	 .change_state(change_state), 
			.dp_mode_(dp_mode_),
					.next_state(next_state),
					.compr_rec(compr_rec_),
					.done_init(done_init)
);

authentication_tpm am0(
.response_of_challenge_rr0_0(response_of_challenge_rr0_0),
.response_of_challenge_rr0_1(response_of_challenge_rr0_1),
.challenge_rr0_0(challenge_rr0_0),
.challenge_rr0_1(challenge_rr0_1),

.response_of_challenge_SW0_0(response_of_challenge_SW0_0),

.challenge_SW0_0(challenge_SW0_0),

.response_of_challenge_SW0_1(response_of_challenge_SW0_1),

.challenge_SW0_1(challenge_SW0_1),

 .initalize(initalize),
.compress(compress),
  .finalize(finalize),
  .long(long),

 .compression_rounds(compression_rounds),
   .final_rounds(final_rounds),

.clk(clk) ,

.resetn(resetn),

.block_0(block_0),

.block_sw(block_sw),
.rrid(rrid),  
.update(update), 
.rmid_target(rmid_target),//monitor reconfig manager
.reconf_done(reconf_done),// coming from PCAP
.resp_done0(siphash_word_valid), //for region 
.resp_done_SW_0(resp_done_SW_0), //for SW region 
 .ready0(ready1), 
 .ready_SW(ready_SW), 
 .activate_SW(activate_SW),
 ////////////////////////////////////////////
 .challenge_received(challenge_received),
 
 .comparison_done(comparison_done),
  .state_(st), .next_state_(nst),.response_done_hw(rh),.resp_rec(resp_rec_),.compr_rec(compr_rec_),
  .done_init(done_init), .out_rr0_0(out_rr0_0),
.out_rr0_1(out_rr0_1),
.out_sw_0(out_sw_0),
.out_sw_1(out_sw_1)

);
endmodule