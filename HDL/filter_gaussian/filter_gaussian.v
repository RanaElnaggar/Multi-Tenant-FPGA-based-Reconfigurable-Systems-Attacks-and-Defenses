module filter( 
output [31:0] out_0,
output [31:0]out_1,
     input [11:0]p0, 
     input [11:0]p1, 
     input [11:0]p2, 
     input [11:0]p3,
     input [11:0]p5, 
     input [11:0]p6, 
     input [11:0]p7, 
     input [11:0]p8, 
     output [11:0]q,

		input clk,

input resetn,
	///////Add SipHash////////////
	
	//add inputs and outputs and its instantiations////
	
	///////Add SipHash////////////
	
	//add inputs and outputs and its instantiations////
	
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
                    input block,
					input resp_rec,
					output [2:0] outparam,
										output  change_state, 
					output wire [2:0] dp_mode_,
					output wire [2:0] next_state,
					output wire compr_rec,
					output wire done_init
);
   wire [127 : 0]  key;
            assign key=128'h0f0e0d0c0b0b090809006050403020100;


assign dp_mode_=dp_mode;
assign change_state=siphash_ctrl_we;
assign next_state=siphash_ctrl_new;
assign compr_rec=compr_rec_;
reg done_init_;
assign done_init=done_init_;
reg compr_rec_;
  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam DP_INIT         = 3'h0;
  localparam DP_COMP_START   = 3'h1;
  localparam DP_COMP_END     = 3'h2;
  localparam DP_FINAL0_START = 3'h3;
  localparam DP_FINAL1_START = 3'h4;
  localparam DP_SIPROUND     = 3'h5;

  localparam CTRL_IDLE         = 3'h0;
  localparam CTRL_COMP_LOOP    = 3'h1;
  localparam CTRL_COMP_END     = 3'h2;
  localparam CTRL_FINAL0_LOOP  = 3'h3;
  localparam CTRL_FINAL0_END   = 3'h4;
  localparam CTRL_FINAL1_START = 3'h5;
  localparam CTRL_FINAL1_LOOP  = 3'h6;
  localparam CTRL_FINAL1_END   = 3'h7;

assign outparam=siphash_ctrl_reg;
  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //---------------mi-------------------------------------------------
  reg [63 : 0] v0_reg;
  reg [63 : 0] v0_new;
  reg          v0_we;

  reg [63 : 0] v1_reg;
  reg [63 : 0] v1_new;
  reg          v1_we;

  reg [63 : 0] v2_reg;
  reg [63 : 0] v2_new;
  reg          v2_we;

  reg [63 : 0] v3_reg;
  reg [63 : 0] v3_new;
  reg          v3_we;

  reg [63 : 0] mi_reg;
  reg          mi_we;

  reg [3 : 0]  loop_ctr_reg;
  reg [3 : 0]  loop_ctr_new;
  reg          loop_ctr_we;
  reg          loop_ctr_inc;
  reg          loop_ctr_rst;

  reg          ready_reg;
  reg          ready_new;
  reg          ready_we;

  reg [63: 0] siphash_word0_reg;
  reg [63: 0] siphash_word1_reg;
  reg [63: 0] siphash_word_new;
  reg          siphash_word0_we;
  reg          siphash_word1_we;

  reg          siphash_valid_reg;
  reg          siphash_valid_new;
  reg          siphash_valid_we;

  reg [2 : 0]  siphash_ctrl_reg;
  reg [2 : 0]  siphash_ctrl_new;
  reg          siphash_ctrl_we;
  reg compr_d;

reg resp_done;
  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg         dp_update;
  reg [2 : 0] dp_mode;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
reg done;  

assign ready              = ready_reg; //changed from ready_reg to done
  assign siphash_word1      = siphash_word0_reg[63:32];
  assign out_0      = siphash_word0_reg[31:0];
  assign out_1     = siphash_word0_reg[63:32];

  assign siphash_word0=siphash_word0_reg[31:0];
 assign siphash_word_valid = siphash_valid_reg;
//assign siphash_word_valid=resp_done;

  //----------------------------------------------------------------
  // reg_update
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with
  // asynchronous active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin
      if (!resetn)
        begin
          // Reset all registers to defined values.
          v0_reg            <= 64'h0;
          v1_reg            <= 64'h0;
          v2_reg            <= 64'h0;
          v3_reg            <= 64'h0;
          siphash_word0_reg <= 64'h0;
          siphash_word1_reg <= 64'h0;
          mi_reg            <= 64'h0;
          ready_reg         <= 1;
          siphash_valid_reg <= 0;
          loop_ctr_reg      <= 4'h0;
          siphash_ctrl_reg  <= CTRL_IDLE;
		done <=1;
resp_done<=0;
done_init_<=0;
        end
      else
        begin
          if (siphash_word0_we)
            siphash_word0_reg <= siphash_word_new;

          if (siphash_word1_we)
		  begin
            siphash_word1_reg <= siphash_word_new;
			end

          if (v0_we)
            v0_reg <= v0_new;

          if (v1_we)
            v1_reg <= v1_new;

          if (v2_we)
            v2_reg <= v2_new;

          if (v3_we)
            v3_reg <= v3_new;

          if (mi_we)
            mi_reg <= {mi1,mi0};

          if (ready_we)
            ready_reg <= ready_new;

          if (siphash_valid_we)
		  begin
            siphash_valid_reg <= siphash_valid_new;
						done_init_<=1;
			end
			if (compr_d)
begin 
compr_rec_<=1;
end 
          if (loop_ctr_we)
            loop_ctr_reg <= loop_ctr_new;

          if (siphash_ctrl_we)
            siphash_ctrl_reg <= siphash_ctrl_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // datapath_update
  // update_logic for the internal datapath with the internal state
  // stored in the v0, v1, v2 and v3 registers.
  //
  // The datapath contains two parallel 64-bit adders with
  // operand MUXes to support reuse during processing.
  //----------------------------------------------------------------
  always @*
    begin : datapath_update
      reg [63 : 0] add_0_res;
      reg [63 : 0] add_1_res;
      reg [63 : 0] add_2_res;
      reg [63 : 0] add_3_res;
      reg [63 : 0] v0_tmp;
      reg [63 : 0] v1_tmp;
      reg [63 : 0] v2_tmp;
      reg [63 : 0] v3_tmp;

      v0_new    = 64'h0;
      v0_we     = 0;
      v1_new    = 64'h0;
      v1_we     = 0;
      v2_new    = 64'h0;
      v2_we     = 0;
      v3_new    = 64'h0;
      v3_we     = 0;

      siphash_word_new = v0_reg ^ v1_reg ^ v2_reg ^ v3_reg;

      if (dp_update)
        begin
          case (dp_mode)
            DP_INIT:
              begin
                v0_new = key[063 : 000] ^ 64'h736f6d6570736575;
                v2_new = key[063 : 000] ^ 64'h6c7967656e657261;
                v3_new = key[127 : 064] ^ 64'h7465646279746573;
                v0_we  = 1;
                v1_we  = 1;
                v2_we  = 1;
                v3_we  = 1;
                if (long)
                  v1_new = key[127 : 064] ^ 64'h646f72616e646f6d ^ 64'hee;
                else
                  v1_new = key[127 : 064] ^ 64'h646f72616e646f6d;
		done=0;
              end
 
            DP_COMP_START:
              begin
                v3_new = v3_reg ^ {mi1,mi0};
                v3_we = 1;
              end

            DP_COMP_END:
              begin
                v0_new = v0_reg ^ mi_reg;
                v0_we = 1;
              end

            DP_FINAL0_START:
              begin
                v2_we = 1;
                if (long)
                  v2_new = v2_reg ^ 64'hee;
                else
                  v2_new = v2_reg ^ 64'hff;
              end

            DP_FINAL1_START:
              begin
                v1_new = v1_reg ^ 64'hdd;
                v1_we  = 1;
              end

            DP_SIPROUND:
              begin
		done =1;
                add_0_res = v0_reg + v1_reg;
                add_1_res = v2_reg + v3_reg;

                v0_tmp = {add_0_res[31:0], add_0_res[63:32]};
                v1_tmp = {v1_reg[50:0], v1_reg[63:51]} ^ add_0_res;
                v2_tmp = add_1_res;
                v3_tmp = {v3_reg[47:0], v3_reg[63:48]} ^ add_1_res;

                add_2_res = v1_tmp + v2_tmp;
                add_3_res = v0_tmp + v3_tmp;

                v0_new = add_3_res;
                v0_we = 1;

                v1_new = {v1_tmp[46:0], v1_tmp[63:47]} ^ add_2_res;
                v1_we = 1;

                v2_new = {add_2_res[31:0], add_2_res[63:32]};
                v2_we = 1;

                v3_new = {v3_tmp[42:0], v3_tmp[63:43]} ^ add_3_res;
                v3_we = 1;
              end

            default:
              begin
              end
          endcase // case (dp_state_reg)
        end // if (dp_update)
    end // block: datapath_update


  //----------------------------------------------------------------
  // loop_ctr
  // Update logic for the loop counter, a monotonically
  // increasing counter with reset.
  //----------------------------------------------------------------
  always @*
    begin : loop_ctr
      loop_ctr_new = 0;
      loop_ctr_we  = 0;

      if (loop_ctr_rst)
        loop_ctr_we  = 1;

      if (loop_ctr_inc)
        begin
          loop_ctr_new = loop_ctr_reg + 4'h1;
          loop_ctr_we  = 1;
        end
    end // loop_ctr


  //----------------------------------------------------------------
  // siphash_ctrl_fsm
  // Logic for the state machine controlling the core behaviour.
  //----------------------------------------------------------------
  always @*
    begin : siphash_ctrl_fsm
      loop_ctr_rst      = 0;
      loop_ctr_inc      = 0;
      dp_update         = 0;
      dp_mode           = DP_INIT;
      mi_we             = 0;
      ready_new         = 0;
      ready_we          = 0;
      siphash_word0_we  = 0;
      siphash_word1_we  = 0;
      siphash_valid_new = 0;
      siphash_valid_we  = 0;
      siphash_ctrl_new  = CTRL_IDLE;
      siphash_ctrl_we   = 0;
     done=1;

     resp_done=0;
      case (siphash_ctrl_reg)
        CTRL_IDLE:
          begin
            if (initalize)
              begin
                dp_update         = 1;
                dp_mode           = DP_INIT;
                siphash_valid_new = 0;
                siphash_valid_we  = 1;
				                ready_new        = 0;
                ready_we         = 1;
		resp_done=0;
		
              end

            else if (compress)
              begin
                mi_we            = 1;
                loop_ctr_rst     = 1;
                ready_new        = 0;
                ready_we         = 1;
                dp_update        = 1;
                dp_mode          = DP_COMP_START;
                siphash_ctrl_new = CTRL_COMP_LOOP;
                siphash_ctrl_we  = 1;
		resp_done=0;
              end

            else if (finalize)
              begin
			  	 ready_new         = 1;
                ready_we          = 1;
                loop_ctr_rst      = 1;
               
                dp_update         = 1;
                dp_mode           = DP_FINAL0_START;
                siphash_ctrl_new  = CTRL_FINAL0_LOOP;
                siphash_ctrl_we   = 1;
		resp_done=0;
              end
          end

        CTRL_COMP_LOOP:
          begin
		  				compr_d=1;

            loop_ctr_inc = 1;
            dp_update    = 1;
            dp_mode      = DP_SIPROUND;
	    
            if (loop_ctr_reg == (compression_rounds - 1))
              begin
                siphash_ctrl_new  = CTRL_COMP_END;
                siphash_ctrl_we   = 1;
		resp_done=0;
	
              end

          end

        CTRL_COMP_END:
          begin
            ready_new        = 0;
            ready_we         = 1;
            dp_update        = 1;
            dp_mode          = DP_COMP_END;
            siphash_ctrl_new = CTRL_IDLE;
            siphash_ctrl_we  = 1;
	    done=0;
	    resp_done=0;
          end

        CTRL_FINAL0_LOOP:
          begin
            loop_ctr_inc = 1;
            dp_update    = 1;
            dp_mode      = DP_SIPROUND;
            if (loop_ctr_reg == (final_rounds - 1))
              begin
                if (long)
                  begin
                    siphash_ctrl_new  = CTRL_FINAL1_START;
                    siphash_ctrl_we   = 1;
		resp_done=0;
	   
                  end
                else
                  begin
                    siphash_ctrl_new  = CTRL_FINAL0_END;
                    siphash_ctrl_we   = 1;
		resp_done=0;

                  end
              end

          end

        CTRL_FINAL0_END:
          begin
            ready_new         = 1;
            ready_we          = 1;
            siphash_word0_we  = 1;
            siphash_valid_new = 1;
            siphash_valid_we  = 1;
			if (resp_rec==1)
			begin 
            siphash_ctrl_new  = CTRL_IDLE;
			end 
			else 
			begin 
			            siphash_ctrl_new  = CTRL_FINAL0_END;

			end
            siphash_ctrl_we   = 1;
	   done =0;
resp_done=1;
          end

        CTRL_FINAL1_START:
          begin
	    done =1;
            siphash_word0_we = 1;
            loop_ctr_rst     = 1;
            dp_update        = 1;
            dp_mode          = DP_FINAL1_START;
            siphash_ctrl_new = CTRL_FINAL1_LOOP;
            siphash_ctrl_we  = 1;
 resp_done=0;
          end

        CTRL_FINAL1_LOOP:
          begin
            loop_ctr_inc = 1;
            dp_update    = 1;
            dp_mode      = DP_SIPROUND;
            if (loop_ctr_reg == (final_rounds - 1))
              begin
                siphash_ctrl_new  = CTRL_FINAL1_END;
                siphash_ctrl_we   = 1;
		resp_done=0;
              end
          end

        CTRL_FINAL1_END:
          begin
            ready_new         = 1;
            ready_we          = 1;
            siphash_word1_we  = 1;
            siphash_valid_new = 1;
            siphash_valid_we  = 1;
			if (resp_rec==1)
			begin 
            siphash_ctrl_new  = CTRL_IDLE;
			end 
			else 
			begin 
			            siphash_ctrl_new  = CTRL_FINAL1_END;

			end
            siphash_ctrl_we   = 1;
	    done =0;
	    resp_done=1;
          end

        default:
          begin
          end
      endcase // case (siphash_ctrl_reg)
    end // siphash_ctrl_fsm

/////////////////////////////////////////
////////Add module//////////////////////
	
	
    
								 
parameter unsigned[11:0]coefa = 1;
parameter unsigned[11:0]coefb = 17;
parameter unsigned[11:0]coefc = 78;
parameter unsigned[11:0]coefd = 128;
parameter unsigned[11:0]coeff = 78;
parameter unsigned[11:0]coefg = 17;
parameter unsigned[11:0]coefh = 1;

wire  unsigned[19:0]delay_tapa = p0 * coefa;
wire  unsigned[19:0]delay_tapb = p1 * coefb;
wire  unsigned[19:0]delay_tapc = p2 * coefc;
wire  unsigned[19:0]delay_tapd = p3 * coefd;
wire  unsigned[19:0]delay_tapf = p5 * coeff;
wire  unsigned[19:0]delay_tapg = p6 * coefg;
wire  unsigned[19:0]delay_taph = p7 * coefh;
wire  unsigned[19:0]delay_tapi = p8;

wire  unsigned[31:0]addresult = delay_tapa + delay_tapb + delay_tapc + delay_tapd + delay_tapf + delay_tapg + delay_taph + delay_tapi;

assign q = addresult[19:8];

endmodule 

