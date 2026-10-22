module synchronizer (
  input  logic clk,
  input  logic d,
  output logic q
);
  logic meta;

  always_ff @(posedge clk) begin
    meta <= d;
    q    <= meta;
  end
endmodule

module debounce (
  input  logic clk,
  input  logic rst,
  input  logic d,
  output logic q
);
  logic [18:0] counter;

  always_ff @(posedge clk) begin
    if (rst) begin
      q       <= 0;
      counter <= 0;
    end
    else if (d == q)
      counter <= 0;
    else if (counter == 499_999) begin
      q       <= d;
      counter <= 0;
    end
    else
      counter <= counter + 1;
  end
endmodule

module edge_detector (
  input  logic clk,
  input  logic rst,
  input  logic btn_in,
  output logic pulse_out
);
  logic btn_prev;

  always_ff @(posedge clk) begin
    if (rst)
      btn_prev <= 0;
    else
      btn_prev <= btn_in;
  end

  assign pulse_out = (btn_in == 1) & (btn_prev == 0);
endmodule

module clk_div (
  input  logic clk,
  input  logic rst,
  output logic tick_1s
);
  logic [25:0] counter;

  assign tick_1s = (counter == 49_999_999);

  always_ff @(posedge clk) begin
    if (rst || tick_1s)
      counter <= 0;
    else
      counter <= counter + 1;
  end
endmodule

module traffic_fsm (
  input  logic       clk,
  input  logic       rst,
  input  logic       tick_1s,
  input  logic       next_pulse,
  output logic [6:0] seconds,
  output logic       red_lamp,
  output logic       yellow_lamp,
  output logic       green_lamp
);

  typedef enum logic [1:0] {
    RED,
    YELLOW1,
    GREEN,
    YELLOW2
  } state_t;

  state_t state, next_state;

  logic [6:0] next_limit;
  logic       go_next;

  always_comb begin
    next_state = state;
    case (state)
      RED:     next_state = YELLOW1;
      YELLOW1: next_state = GREEN;
      GREEN:   next_state = YELLOW2;
      YELLOW2: next_state = RED;
    endcase
  end

  always_comb begin
    case (next_state)
      RED:     next_limit = 40;
      YELLOW1: next_limit = 7;
      GREEN:   next_limit = 40;
      YELLOW2: next_limit = 7;
      default: next_limit = 0;
    endcase
  end

  assign go_next = next_pulse || (tick_1s && seconds == 0);

  always_ff @(posedge clk) begin
    if (rst)
      state <= RED;
    else if (go_next)
      state <= next_state;
  end

  always_ff @(posedge clk) begin
    if (rst)
      seconds <= 40;
    else if (go_next)
      seconds <= next_limit;
    else if (tick_1s)
      seconds <= seconds - 1;
  end

  always_comb begin
    red_lamp    = 0;
    yellow_lamp = 0;
    green_lamp  = 0;
    case (state)
      RED:     red_lamp    = 1;
      YELLOW1: yellow_lamp = 1;
      GREEN:   green_lamp  = 1;
      YELLOW2: yellow_lamp = 1;
    endcase
  end

endmodule


module split_digits (
  input  logic [6:0] number,
  output logic [3:0] tens,
  output logic [3:0] ones
);
  assign tens = number / 10;
  assign ones = number % 10;
endmodule



module seg7_decoder (
  input  logic [3:0] a,
  output logic [6:0] y
);
  logic [6:0] seg_on;

  always_comb begin
    case (a)
      4'd0:    seg_on = 7'b0111111;
      4'd1:    seg_on = 7'b0000110;
      4'd2:    seg_on = 7'b1011011;
      4'd3:    seg_on = 7'b1001111;
      4'd4:    seg_on = 7'b1100110;
      4'd5:    seg_on = 7'b1101101;
      4'd6:    seg_on = 7'b1111101;
      4'd7:    seg_on = 7'b0000111;
      4'd8:    seg_on = 7'b1111111;
      4'd9:    seg_on = 7'b1101111;
      default: seg_on = 7'b0000000;
    endcase
  end

  assign y = ~seg_on;
endmodule

module Trafic_light (
  input  logic       clk,
  input  logic       btn_next,
  input  logic       btn_rst,
  output logic       red_lamp,
  output logic       yellow_lamp,
  output logic       green_lamp,
  output logic [6:0] seg_tens,
  output logic [6:0] seg_ones
);

  logic next_sync, next_clean, next_pulse;
  logic rst_sync,  rst_clean,  rst_pulse;
  logic tick_1s;
  logic [6:0] seconds;
  logic [3:0] tens, ones;

  synchronizer  u_sync_next (.clk(clk), .d(btn_next),       .q(next_sync));
  debounce      u_deb_next  (.clk(clk), .rst(rst_pulse),    .d(next_sync),   .q(next_clean));
  edge_detector u_edge_next (.clk(clk), .rst(rst_pulse),    .btn_in(next_clean), .pulse_out(next_pulse));

  synchronizer  u_sync_rst  (.clk(clk), .d(btn_rst),        .q(rst_sync));
  debounce      u_deb_rst   (.clk(clk), .rst(1'b0),         .d(rst_sync),    .q(rst_clean));
  edge_detector u_edge_rst  (.clk(clk), .rst(1'b0),         .btn_in(rst_clean),  .pulse_out(rst_pulse));

  clk_div u_clk_div (.clk(clk), .rst(rst_pulse), .tick_1s(tick_1s));

  traffic_fsm u_fsm (
    .clk        (clk),
    .rst        (rst_pulse),
    .tick_1s    (tick_1s),
    .next_pulse (next_pulse),
    .seconds    (seconds),
    .red_lamp   (red_lamp),
    .yellow_lamp(yellow_lamp),
    .green_lamp (green_lamp)
  );

  split_digits u_split (.number(seconds), .tens(tens), .ones(ones));

  seg7_decoder u_seg_tens (.a(tens), .y(seg_tens));
  seg7_decoder u_seg_ones (.a(ones), .y(seg_ones));

endmodule
