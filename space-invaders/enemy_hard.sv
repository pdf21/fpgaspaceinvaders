module enemy_hard(
    input   logic Reset, input logic frame_clk, input logic [7:0] keycode, input logic Clk,
    input   logic enemy_direction_X, // 0 = move left, 1 = move right
    input   logic enemy_direction_Y, // 0 = stay, 1 = move down
    input   logic [9:0] enemy_initial_x, enemy_initial_y,
    input   logic [9:0] DrawX, DrawY,
    input   logic start,
    output  logic enemy_on,
    output  logic [7:0] enemy_R, enemy_G, enemy_B
);
    logic   enemy_enable;
    logic   [9:0] enemy_x, enemy_y, next_enemy_y;
    parameter enemy_step_X, enemy_step_Y;

    int IMAGE_WIDTH = 9'd50; 
    int IMAGE_HEIGHT = 9'd50;

    logic [18:0] pos; //position inside memory ARRAY
    // find position in memory : DrawX - startX
    logic   [23:0] read_addr;
    enum {
        IDLE,           // when dead or game have not yet started
        START,          // game just started, await for sprite drawing
        AWAIT_POS,      // wait next horizontal position
        DRAW,           // output the RGB
        NEXT_LINE       // wait for next row
    } state, next_state;
    // states IDLE, START, AWAIT_POS, DRAW, NEXT_LINE 

    // enemy_data module 

    always_ff @(posedge frame_clk) begin
        if(enemy_direction_X == 1'b0) begin
            enemy_start_x <= enemy_start_x - 1;
        end
        else begin
            enemy_start_x <= enemy_start_x + 1;
        end
        if(enemy_direction_Y == 1)begin
            enemy_start_y <= enemy_start_y - 1;
        end
    end
    


    pink_invaderRAM my_pink_invader(
        .data_in(5'b0),
        .write_address(19'b0),
        .read_address(read_addr),
        .we(0'b0),
        .Clk(Clk),
        .data_out({enemy_sprite_R, enemy_sprite_G, enemy_sprite_B})
    );
    // 2 always: outputs of each state
             //  handling of next state
    // accessing memory = row no * width + col no
    // always happens:
    always_comb begin
        if(enemy_on == 1'b1) begin
            enemy_R <= enemy_sprite_R;
            enemy_G <= enemy_sprite_G;
            enemy_B <= enemy_sprite_B;
        end
        else begin
            enemy_R <= 8'b0;
            enemy_G <= 8'b0;
            enemy_B <= 8'b0;
        end 
    end

    always_ff @ (posedge Clk) begin
           state <= state_next;

           if(state == START)begin
               enemy_y <= 0;
               pos <= 0;
               enemy_on <= 1'b0;
           end

           if(state == AWAIT_POS)begin
               enemy_x <= 0;
               enemy_on <= 1'b0;
           end

           if(state == DRAW) begin
               enemy_x <= enemy_x + 1;
               pos <= pos + 1;
               enemy_on <= 1'b1;
           end

           if(state == NEXT_LINE) begin
               enemy_y <= enemy_y + 1;
               enemy_on <= 1'b0;
           end

           if(Reset) begin
               state <= IDLE;
            enemy_start_x = enemy_initial_x;
               enemy_start_y = enemy_initial_y;
               enemy_x <= 0;
               enemy_y <= 0;
               pos <= 0;
               enemy_on <= 1'b0;
           end
    end
             
    logic final_pixel;
    logic final_line;

    always_comb begin
        final_pixel = (enemy_x == IMAGE_WIDTH - 1);
        final_line = (enemy_y == IMAGE_HEIGHT - 1);
    end
    
    logic [9:0] temp_Draw_X;
    logic [9:0] temp_Draw_Y;
    always_comb begin
        temp_Draw_X = Draw_X - enemy_start_x;
        temp_Draw_Y = Draw_Y - enemy_start_Y;
        assign ready = (temp_Draw_Y == enemy_Y && temp_Draw_X == enemy_X);
        case(state)
            IDLE:       state_next = start & ready ? START: IDLE;
            START:      state_next = AWAIT_POS;
            AWAIT_POS:  state_next = enemy_x == temp_Draw_X ? DRAW : AWAIT_POS;
            DRAW:       state_next = !last_pixel ? DRAW : (!last_line ? NEXT_LINE : IDLE);
            NEXT_LINE:  state_next = AWAIT_POS;
            default:    state_next = IDLE;
        endcase
    end
    
endmodule