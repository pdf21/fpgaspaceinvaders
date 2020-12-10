module player(
    input logic Reset, frame_clk, Clk, 
    input logic [7:0] keycode,
    input logic start,
    input logic [9:0] player_initial_x, player_initial_y,
    input logic [9:0] DrawX, DrawY,
    output logic player_on,
    output logic [23:0] player_color
);

    logic [9:0] player_X_Pos, player_Y_Pos, player_X_Motion, player_size;
    logic need_move; //2 can go any direction, 1 for need to move right, 0 for need to move left.
    parameter [9:0] player_X_Center=320;  // Center position on the X axis 320
    parameter [9:0] player_X_Min=20;       // Leftmost point on the X axis Min = 0
    parameter [9:0] player_X_Max=600;     // Rightmost point on the X axis Max = 639
    parameter [9:0] player_X_Step= 1;      // Step size on the X axis
    
    logic [9:0] player_start_X, player_start_Y;

    parameter offsetup = 32;
    int IMAGE_WIDTH = 10'd36;
    int IMAGE_HEIGHT = 10'd40;
    
    logic [18:0] pos; // position within memory array

    enum {
        IDLE,       // awaiting start signal
        START,      // prepare for new sprite drawing
        AWAIT_POS,  // await horizontal position
        DRAW,       // draw pixel
        NEXT_LINE   // prepare for next sprite line
    }state, next_state;
   
   always_ff @ (posedge frame_clk) begin
        if(keycode == 8'h04 && player_start_X > 0)begin // A
          player_start_X <= player_start_X - 1;
        end
        else if (keycode == 8'h07 && player_start_X < 563)begin // D
          player_start_X <= player_start_X + 1;
        end else
          player_start_X <= player_start_X;
   end

   player_spriteRAM player_inst(
        .data_In(5'b0),
        .write_address(19'b0),
        .read_address(pos),
        .we(1'b0),
        .Clk(Clk)
        .data_Out(player_color)
   );
  logic start_moving;
  assign start_moving = start;
  always_ff @ (posedge Clk) begin
    state <= state_next;

    if(state == START) begin
        player_Y_Pos <= 0;
        player_X_Motion = <= 0;
        pos <= 0;
        player_on <= 1'b0;
    end

    if(state == AWAIT_POS) begin
        player_X_Pos <= 0;
    end

    if(state == DRAW) begin
        player_X_Pos <= player_X_Pos + 1;
        pos <= pos + 1;
        player_on <= 1'b1;
    end

    if(state == NEXT_LINE) begin
        player_Y_Pos <= player_Y_Pos + 1;
        player_on <= 1'b0;
    end

    if(Reset) begin
      state <= IDLE;
      player_start_X = player_initial_x;
      player_start_Y = player_initial_y;
      player_X_Pos <= 0;
      player_Y_Pos <= 0;
      pos <= 0;
      player_on <= 1'b0;            
    end

  end

  logic last_pixel, last_line;
  always_comb begin
      last_pixel = (player_X_Pos == IMAGE_WIDTH-1);
      last_line  = (player_Y_Pos == IMAGE_HEIGHT-1);
  end

  // determine next state
  always_comb begin
        case(state)
            IDLE:       state_next = start ? START : IDLE;
            START:      state_next = AWAIT_POS;
            AWAIT_POS:  state_next = (player_initial_x == DrawX) ? DRAW : AWAIT_POS;
            DRAW:       state_next = !last_pixel ? DRAW : (!last_line ? NEXT_LINE : IDLE);
            NEXT_LINE:  state_next = AWAIT_POS;
            default:    state_next = IDLE;
        endcase
  end
  
    // always_ff @ (posedge Reset or posedge frame_clk )
    // begin: Move_player
    //     if (Reset)  // Asynchronous Reset
    //     begin 
    //       player_X_Motion <= 0; //player_X_Step;
    //       player_X_Pos <= player_X_Center;
    //     end           
    //     else 
    //     begin 					  
    //         if ( (player_X_Pos) >= player_X_Max )
    //                     begin
    //                         player_X_Motion <= 0;
    //                         need_move <= 0;
    //                     end					  
    //         else if ( (player_X_Pos) <= player_X_Min )
    //                     begin
    //                       player_X_Motion <= 0;
    //                       need_move <= 1;
    //                     end
    //         else if (keycode == 8'h04 && need_move != 1) // A
    //                     begin
    //                       player_X_Motion <= (~(player_X_Step)+1'b1);
    //                       need_move <= 2;
    //                     end
    //         else if( keycode == 8'h07 && need_move != 0) // D
    //                 begin
    //                   player_X_Motion <= player_X_Step;
    //                   need_move <= 2;
    //                 end
    //         else
    //             begin
    //               player_X_Motion <= 0;
    //               need_move <= 2;
    //             end
    //         player_X_Pos <= (player_X_Pos + player_X_Motion);
    //     end
    // end       
    // assign Player_X = player_X_Pos;

endmodule