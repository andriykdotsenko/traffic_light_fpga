 Traffic Light Controller on CPLD (SystemVerilog)

Traffic light controller written in SystemVerilog and running on an Altera MAX II (EPM570) CPLD board, with two 7-segment countdown displays and two push buttons.

<!-- Тут встав відео: перетягни .mp4 у редактор -->

 Features

- 4-state FSM: RED (41 s) → YELLOW (7 s) → GREEN (41 s) → YELLOW (7 s) → RED
- Countdown of the remaining seconds on two independent 7-segment displays (common anode)
- `btn_next` skips to the next state manually, `btn_rst` resets the FSM
- Button conditioning: 2-FF synchronizer, debounce (10 ms) and rising-edge detector
- 50 MHz on-board clock divided down to a 1 Hz tick

 Module structure

| Module | Purpose |
|---|---|
| `top` | Connects all modules |
| `synchronizer` | Two flip-flops against metastability |
| `debounce` | Removes contact bounce (10 ms at 50 MHz) |
| `edge_detector` | Single-cycle pulse on button press |
| `clk_div` | 50 MHz → 1 Hz tick |
| `traffic_fsm` | State machine, seconds counter, lamp outputs |
| `split_digits` | Splits the seconds value into tens and ones |
| `seg7_decoder` | Digit → 7-segment pattern |

 Pin assignments

| Signal | Pin |
|---|---|
| `clk` (50 MHz oscillator) | PIN_64 |
| `btn_next` | PIN_50 |
| `btn_rst` | PIN_48 |
| `red_lamp` | PIN_57 |
| `yellow_lamp` | PIN_53 |
| `green_lamp` | PIN_55 |
| `seg_ones[6:0]` | PIN_14, 12, 8, 7, 6, 5, 4 |
| `seg_tens[6:0]` | PIN_86, 87, 89, 91, 92, 95, 96 |

Buttons are active-low: one side goes to GND and the pin uses the internal weak pull-up. The code inverts the inputs.

 Hardware

- MAX II EPM570 development board (50 MHz oscillator on PIN_64)
- 2 push buttons, 3 LEDs, 2 common-anode 7-segment displays, current-limiting resistors <values>

 Build and program

1. Open `Trafic_light.qpf` in Quartus II 13.0 (Web Edition)
2. Compile the project (Processing → Start Compilation)
3. Program the board through USB-Blaster (Tools → Programmer)
4. Press the reset button once after power-up
