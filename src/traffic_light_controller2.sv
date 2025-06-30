import light_package ::*;

module traffic_light_controller2(
  input clk, reset, e_str_sensor, w_str_sensor, e_left_sensor, 
        w_left_sensor, ns_sensor,             // traffic sensors, east-west str, east-west left, north-south 
  output colors e_str_light, w_str_light, e_left_light, w_left_light, ns_light);

  logic s, sb, e, eb, w, wb, l, lb, n, nb;

  assign s  = e_str_sensor || w_str_sensor;
  assign sb = e_left_sensor || w_left_sensor || ns_sensor;
  assign e  = e_left_sensor || e_str_sensor;
  assign eb = w_left_sensor || w_str_sensor || ns_sensor;
  assign w  = w_left_sensor || w_str_sensor;
  assign wb = e_left_sensor || e_str_sensor || ns_sensor;
  assign l  = e_left_sensor || w_left_sensor;
  assign lb = e_str_sensor || w_str_sensor || ns_sensor;
  assign n  = ns_sensor;
  assign nb = s || l; 


  typedef enum {GRRRR, YRRRR, ZRRRR, HRRRR, 
  	            RGRRR, RYRRR, RZRRR, RHRRR, 
	            RRGRR, RRYRR, RRZRR, RRHRR,
	            RRRGR, RRRYR, RRRZR, RRRHR,
	            RRRRG, RRRRY, RRRRZ, RRRRH} tlc_states;
	tlc_states    present_state, next_state;
	int     ctr5, next_ctr5,       //  5 sec timeout when my traffic goes away
			ctr10, next_ctr10;       // 10 sec limit when other traffic presents

// sequential part of state machine
  always_ff @(posedge clk)
	if(reset) begin
	  present_state <= GRRRR;
	  ctr5          <= 'd0;
	  ctr10         <= 'd0;
	end  
	else begin
	  present_state <= next_state;
	  ctr5          <= next_ctr5;
	  ctr10         <= next_ctr10;
	end  

// combinational part of state machine
  always_comb begin
	next_state = GRRRR;                       // default to reset state
	next_ctr5  = 'd0; 							   // default: reset counters
	next_ctr10 = 'd0;
	case(present_state)
	  GRRRR: begin 
			if(s == 0) next_ctr5 = 1+ctr5;
			
	  // when traffic is present in the other lanes, 10 cycle counter starts
			if(sb == 1) next_ctr10 = ctr10+1;
			
	  // change to 1st yellow state once counter completes
			if(next_ctr5 >= 5) next_state = YRRRR;
			else if(next_ctr10 == 10) next_state = YRRRR;
			else next_state = GRRRR;
			if(sb == 0) begin
				next_ctr5 = 1+ctr5;
				next_state = GRRRR;
					end
	         end
	  YRRRR:	begin 
			next_state = ZRRRR;
		// reset counters and traffic break signal
			next_ctr10 = 0;
			next_ctr5 = 0;
		end
	  ZRRRR: begin
			next_state = HRRRR;
	   end
	  HRRRR: begin
			next_state = RGRRR;
	   end
	  RGRRR: begin
			if(e == 0) next_ctr5 = 1+ctr5;
			else if(ctr5>1) next_ctr5 = 1+ctr5;
			
	  // when traffic is present in the other lanes, 10 cycle counter starts
			if(eb == 1) next_ctr10 = ctr10+1;
			
	  // change to 1st yellow state once counter completes
			if(next_ctr5 == 5) next_state = RYRRR;
			else if(next_ctr10 == 10) next_state = RYRRR;
			else next_state = RGRRR;
	   end
	  RYRRR: begin 
			next_state = RZRRR;
	  // reset counters and traffic break signal
			next_ctr10 = 0;
			next_ctr5 = 0;
		end
	  RZRRR: next_state = RHRRR;
	  RHRRR: next_state = RRGRR;

	  RRGRR: begin 
			if(w == 0) next_ctr5 = 1+ctr5;
	  // when traffic is present in the other lanes, 10 cycle counter starts
			if(wb == 1) next_ctr10 = ctr10+1;
			else if(ctr10>1) next_ctr10 = ctr10+1;
	  // change to 1st yellow state once counter completes
			if(next_ctr5 == 5) next_state = RRYRR;
			else if(next_ctr10 == 10) next_state = RRYRR;
			else next_state = RRGRR;
	  end
     RRYRR: begin 
			next_state = RRZRR;
	  // reset counters and traffic break signal
			next_ctr10 = 0;
			next_ctr5 = 0;
		end
	  RRZRR: next_state = RRHRR;
	  RRHRR: next_state = RRRGR;
	  RRRGR: begin
			if(l == 0) next_ctr5 = 1+ctr5;
	  // when traffic is present in the other lanes, 10 cycle counter starts
			if(lb == 1) next_ctr10 = ctr10+1;
			else if(ctr10>1) next_ctr10 = ctr10+1;
	  // change to 1st yellow state once counter completes
			if(next_ctr5 == 5) next_state = RRRYR;
			else if(next_ctr10 == 10) next_state = RRRYR;
			else next_state = RRRGR;
	   end
		RRRYR: begin 
			next_state = RRRZR;
	  // reset counters and traffic break signal
			next_ctr10 = 0;
			next_ctr5 = 0;
		end
		RRRZR: next_state = RRRHR;
		RRRHR: begin
			if(n == 1)
				next_state = RRRRG;
			else if(s == 1)
				next_state = GRRRR;
			else if(l == 1) 
				next_state = RRGRR;
			else if (e == 1) 
				next_state = RGRRR;
			else next_state = RRRRG;
			end
		RRRRG: begin
			if(n == 0) next_ctr5 = 1+ctr5;
			else if(ctr5>1) next_ctr5 = 1+ctr5;
	  // when traffic is present in the other lanes, 10 cycle counter starts
			if(nb == 1) next_ctr10 = ctr10+1;
	  // change to 1st yellow state once counter completes
			if(next_ctr5 == 5) next_state = RRRRY;
			else if(next_ctr10 == 10) next_state = RRRRY;
			else next_state = RRRRG;
	   end
		RRRRY: begin 
			next_state = RRRRZ;
	  // reset counters and traffic break signal
			next_ctr10 = 0;
			next_ctr5 = 0;
		end
		RRRRZ: next_state = RRRRH;
		RRRRH: next_state = GRRRR;
		default: next_state = GRRRR;
    endcase
  end

// combination output driver
	always_comb begin
	  e_str_light  = red;                
	  w_str_light  = red;
	  e_left_light = red;
	  w_left_light = red;
	  ns_light     = red;
	  case(present_state)      // Moore machine
		GRRRR:   begin e_str_light = green;
					   w_str_light = green;
					end
      YRRRR, ZRRRR: begin e_str_light = yellow;
					   w_str_light = yellow;
						  end
		HRRRR: begin e_str_light = red;
					   w_str_light = red;
				 end
		RGRRR: begin e_str_light = green;
					   e_left_light = green;
				 end
      RYRRR, RZRRR: begin e_str_light = yellow;
					   e_left_light = yellow;
						  end
		RHRRR: begin e_str_light = red;
					   e_left_light = red;
				 end
		RRGRR: begin w_left_light = green;
					   w_str_light = green;
				 end
      RRYRR, RRZRR: begin w_left_light = yellow;
					   w_str_light = yellow;
						  end
		RRHRR: begin w_left_light = red;
					   w_str_light = red;
				 end
		RRRGR: begin w_left_light = green;
					   e_left_light = green;
				 end
      RRRYR, RRRZR: begin w_left_light = yellow;
					   e_left_light = yellow;
						  end
		RRRHR: begin w_left_light = red;
					   e_left_light = red;
				 end
		RRRRG: ns_light = green;
		RRRRY, RRRRZ: ns_light = yellow;
		RRRRH: ns_light = red;
		default: begin
			e_str_light  = red;             
			w_str_light  = red;
			e_left_light = red;
			w_left_light = red;
			ns_light     = red;
		 end 
	 endcase
	end
endmodule
