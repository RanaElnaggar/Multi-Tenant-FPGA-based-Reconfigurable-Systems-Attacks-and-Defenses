//call LUT in update, 

module LUT_(
input clk,
input resetn,
input [3:0] rrid,// region to update
input [3:0] update_val,
input update,
output reg  rmid_out1, 
output reg rmid_out2, 
output reg rmid_out0

);//active_module
//reg rmid_0, rmid_1, rmid_2; 


//FSM for LUT
parameter SIZE = 2           ;
parameter Init  = 2'b00,UPDATE = 2'b01,Retain_val = 2'b10;

reg   [SIZE-1:0]          state        ;// Seq part of the FSM
 reg   [SIZE-1:0]          next_state   ;// combo part of FSM
 
always @ (state or update or update_val or  rrid or clk or resetn)
 begin : states_fsm
  next_state = 2'b00;
  case(state)
    Init : if (update == 1'b1) begin
                 next_state = UPDATE;
                 end
                else if (resetn == 1'b0) begin
                  next_state = Init;
               end
    UPDATE:if (update == 1'b1) begin
                 next_state = UPDATE;
                 end
                else if (resetn == 1'b0) begin
                  next_state = Init;
               end
               else 
               begin 
                  next_state = Retain_val;
               end
    Retain_val: if (update == 1'b1) begin
                 next_state = UPDATE;
                 end
                else if (resetn == 1'b0) begin
                  next_state = Init;
               end
               else 
               begin 
                  next_state = Retain_val;
               end
    endcase 
    end //always block
    
     always @ (posedge clk)
 begin : next_state_assignement 
   if (resetn == 1'b0) begin
   state <= Init;
  end
   else begin
    state <= next_state;
   end
 end



 always @ (posedge clk)
 begin : output_assignement
 if (resetn == 1'b0) begin
 rmid_out0<=0;
rmid_out1<=0;
rmid_out2<=0;
 end
  else begin
   case(state)
     Init : begin
            rmid_out0<=0;
rmid_out1<=0;
rmid_out2<=0;      
                end
    UPDATE : begin 
case (rrid)
2'b00: rmid_out0=update_val; 
2'b01: rmid_out1=update_val;
2'b10:rmid_out2=update_val;
endcase
                 end
    endcase 
    end //end else 
    end //end always 
endmodule
