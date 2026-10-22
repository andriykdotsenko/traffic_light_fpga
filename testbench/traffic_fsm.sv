`timescale 1ns/1ps

module tb_traffic_fsm;

  localparam int EXP_RED    = 41;
  localparam int EXP_YELLOW = 8;
  localparam int EXP_GREEN  = 41;

  logic       clk = 0;
  logic       rst;
  logic       tick_1s;
  logic       next_pulse;
  logic [6:0] seconds;
  logic       red_lamp, yellow_lamp, green_lamp;

  int errors = 0;
  int n;

  traffic_fsm dut (
    .clk         (clk),
    .rst         (rst),
    .tick_1s     (tick_1s),
    .next_pulse  (next_pulse),
    .seconds     (seconds),
    .red_lamp    (red_lamp),
    .yellow_lamp (yellow_lamp),
    .green_lamp  (green_lamp)
  );

  always #10 clk = ~clk;

  task automatic pulse_tick();
    @(negedge clk); tick_1s = 1;
    @(negedge clk); tick_1s = 0;
  endtask

  task automatic press_next();
    @(negedge clk); next_pulse = 1;
    @(negedge clk); next_pulse = 0;
  endtask

    task automatic count_until_change(output int cnt);
    logic [2:0] prev;
    prev = {red_lamp, yellow_lamp, green_lamp};
    cnt = 0;
    while ({red_lamp, yellow_lamp, green_lamp} == prev && cnt < 100) begin
      pulse_tick();
      cnt++;
    end
  endtask

  task automatic check(input string name, input logic cond);
    if (cond) $display("PASS: %s", name);
    else begin
      $display("FAIL: %s", name);
      errors++;
    end
  endtask

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_traffic_fsm);

    rst = 1; tick_1s = 0; next_pulse = 0;

    repeat (3) @(negedge clk);
    rst = 0;
    @(negedge clk);
    check("after reset: red only", red_lamp && !yellow_lamp && !green_lamp);
    check("after reset: seconds == 40", seconds == 40);

    count_until_change(n);
    $display("RED lasted %0d ticks", n);
    check("RED duration", n == EXP_RED);
    check("RED -> YELLOW", yellow_lamp && !red_lamp && !green_lamp);

    count_until_change(n);
    $display("YELLOW1 lasted %0d ticks", n);
    check("YELLOW1 duration", n == EXP_YELLOW);
    check("YELLOW1 -> GREEN", green_lamp && !red_lamp && !yellow_lamp);

    count_until_change(n);
    $display("GREEN lasted %0d ticks", n);
    check("GREEN duration", n == EXP_GREEN);
    check("GREEN -> YELLOW", yellow_lamp && !red_lamp && !green_lamp);

    count_until_change(n);
    $display("YELLOW2 lasted %0d ticks", n);
    check("YELLOW2 duration", n == EXP_YELLOW);
    check("YELLOW2 -> RED", red_lamp && !yellow_lamp && !green_lamp);
    check("back in RED: seconds == 40", seconds == 40);

    press_next();
    check("Next in RED -> YELLOW", yellow_lamp && !red_lamp && !green_lamp);
    check("Next in RED: seconds == 7", seconds == 7);
    press_next();
    check("Next in YELLOW -> GREEN", green_lamp && !red_lamp && !yellow_lamp);
    press_next();
    check("Next in GREEN -> YELLOW", yellow_lamp && !red_lamp && !green_lamp);
    press_next();
    check("Next in YELLOW -> RED", red_lamp && !yellow_lamp && !green_lamp);

    repeat (5) pulse_tick();
    check("5 ticks: seconds == 35", seconds == 35);

    @(negedge clk); rst = 1;
    @(negedge clk); rst = 0;
    check("mid-count reset: red only", red_lamp && !yellow_lamp && !green_lamp);
    check("mid-count reset: seconds == 40", seconds == 40);

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end

endmodule
