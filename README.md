# Vending Machine Controller using Verilog HDL

## 1. Project Overview

This project implements a simple coin-operated vending machine controller in Verilog HDL. The machine accepts two coin types (5 and 10 units) and dispenses a product once enough money has been inserted, returning change if the customer overpays.

A vending machine is a classic beginner-to-intermediate FSM (Finite State Machine) design problem in digital electronics courses — it involves sequential logic, state transitions, and simple arithmetic-like decision making, all of which map cleanly onto Verilog constructs. It's a good way to practice writing synthesizable RTL code and verifying it with a testbench.

The main objective of this project was to design the controller logic in Verilog, verify its behavior through simulation, and study how the RTL code gets translated into actual hardware structures (registers, muxes) using Vivado's elaborated schematic view.

## 2. Project Idea

The basic idea is straightforward:

```
Coin Inserted (5 or 10)
        ↓
Controller tracks how much money has been inserted so far
        ↓
Once the inserted amount reaches 10 units
        ↓
Product signal goes high (product dispensed)
        ↓
If the customer overpaid, change is returned
```

In this implementation, the product costs **10 units**. The customer can pay for it in two ways:
- Insert one 10-unit coin directly, or
- Insert two 5-unit coins (5 + 5)

If the customer inserts a 5, then a 10, the machine gives the product **and** returns 5 as change, since 15 was paid for a 10-unit item.

## 3. Features

Based strictly on what is implemented in `vending_machine.v`:

- Clock-based (synchronous) sequential design
- Asynchronous active-high reset
- Two coin inputs: `coin5` and `coin10`
- Two-state FSM to track the amount inserted
- Product dispensing output (`product`)
- Change return logic for the `change5` output
- Combinational next-state and output logic (Mealy-style outputs)
- Separate testbench (`vending_machine_tb.v`) with clock generation and multiple coin-insertion scenarios

Note: the design also has a `change10` output port, but nowhere in the logic is it ever driven to `1` — it stays permanently at `0`. This is pointed out here rather than described as a working feature, since the code doesn't actually use it.

## 4. Inputs and Outputs

| Signal | Direction | Description |
|--------|-----------|--------------|
| `clk` | Input | System clock, drives the state register on every rising edge |
| `reset` | Input | Active-high asynchronous reset; forces the FSM back to state `S0` |
| `coin5` | Input | Goes high for one clock cycle when a 5-unit coin is inserted |
| `coin10` | Input | Goes high for one clock cycle when a 10-unit coin is inserted |
| `product` | Output | Goes high for one cycle when the product is dispensed |
| `change5` | Output | Goes high for one cycle when 5 units of change need to be returned |
| `change10` | Output | Declared in the port list but never asserted in the current logic (always 0) |

## 5. Working Principle

The design is a small FSM with outputs that depend on both current state and inputs (Mealy-style):

1. **Reset condition:** When `reset` is high, the state register is asynchronously forced to `S0` (`00`), representing "no money inserted yet."

2. **State S0 (0 units inserted):**
   - If `coin5` is inserted → move to state `S5` (5 units inserted so far).
   - If `coin10` is inserted → the full price is already covered, so `product` is asserted immediately and the FSM stays in `S0`.
   - If no coin is inserted → stay in `S0`.

3. **State S5 (5 units inserted):**
   - If `coin5` is inserted → total becomes 10, `product` is asserted, and the FSM returns to `S0`.
   - If `coin10` is inserted → total becomes 15, which is 5 more than the price, so `product` is asserted **and** `change5` is asserted, then the FSM returns to `S0`.
   - If no coin is inserted → stay in `S5` (partial payment is remembered).

4. **Next state selection:** All of the above is computed combinationally in the second `always @(*)` block, which decides `next_state` based on the current `state` and the coin inputs.

5. **Product output:** `product` becomes high only in the specific combinations described above (`coin10` in `S0`, or `coin5`/`coin10` in `S5`). It is a combinational output, so it appears in the same cycle the qualifying coin is applied.

6. **Change generation:** Only `change5` is ever generated, and only in the `S5 + coin10` case, since that's the only combination in the code that results in an overpayment condition (15 inserted vs 10 required).

7. **After dispensing:** Once `product` (and `change5`, if applicable) is issued, `next_state` is set back to `S0`, so the machine is immediately ready to accept a new transaction on the next clock edge.

8. **Return to idle:** Because `next_state` always resolves to `S0` after a successful purchase, the FSM naturally returns to the idle/no-money state without needing a separate "dispense" state.

## 6. FSM / State Description

| State | Meaning | Condition / Transition |
|-------|---------|--------------------------|
| `S0` (00) | No money inserted (idle state) | `coin5` → go to `S5`. `coin10` → dispense product, stay in `S0`. No coin → stay in `S0`. |
| `S5` (01) | 5 units already inserted | `coin5` → dispense product, go to `S0`. `coin10` → dispense product + `change5`, go to `S0`. No coin → stay in `S5`. |

```text
                RESET
                  |
                  v
                 S0
           (0 units inserted)
             /            \
        coin5             coin10
          |                  |
          v                  v
          S5             product = 1
   (5 units inserted)      (stay S0)
        /        \
   coin5        coin10
     |             |
     v             v
 product=1     product=1
 (go to S0)    change5=1
               (go to S0)
```

## 7. Verilog Implementation

The design is split into two `always` blocks, which is a common and clean way to write FSMs in Verilog:

- **Sequential (state) logic:** `always @(posedge clk or posedge reset)` — this is the only clocked block in the design. It updates `state` with `next_state` on every rising clock edge, or forces `state` to `S0` if `reset` is asserted. This is the only register in the design (a 2-bit state register).

- **Combinational next-state and output logic:** `always @(*)` — this single block computes both `next_state` and the three outputs (`product`, `change5`, `change10`) based on the current `state` and the coin inputs. Default assignments (`next_state = state`, and all outputs = 0) are made at the top of the block before the `case` statement, which avoids unintentional latch inference.

There's no separate "output logic" block — outputs are generated in the same combinational block as the next-state logic, driven directly by the `case (state)` structure.

## 8. Testbench

`vending_machine_tb.v` instantiates the `vending_machine` module as `uut` and exercises it as follows:

- **Clock generation:** `always #5 clk = ~clk;` produces a clock with a 10 ns period (toggling every 5 ns).
- **Reset application:** `reset` is held high for the first 10 ns, then deasserted, to confirm the FSM starts from `S0`.
- **Coin sequences applied:**
  1. `coin5` pulsed once — expected to move the FSM from `S0` to `S5`.
  2. `coin5` pulsed again — expected to trigger `product` and return to `S0`.
  3. `coin10` pulsed — expected to trigger `product` directly from `S0`.
  4. `coin5` pulsed — moves to `S5` again.
  5. `coin10` pulsed — expected to trigger both `product` and `change5`, returning to `S0`.
- **Monitoring:** A `$monitor` statement prints `reset`, `coin5`, `coin10`, `product`, `change5`, and `change10` on every value change, so the console log can be checked alongside the waveform.
- **Simulation end:** The testbench runs for a total of about 100 ns before calling `$finish`.

This sequence covers both purchase paths (10 directly, and 5+5) as well as the overpayment/change scenario (5+10), which together exercise both states and every transition in the FSM.

## 9. Simulation Results

![Simulation Waveform](https://raw.githubusercontent.com/VASUDEVARAO-SANKARAPU/VENDING-MACHINE-USING-VERILOG/refs/heads/main/images/timing_ven_D.jpeg)

From the waveform capture:

- `clk` toggles continuously throughout the simulation, confirming clock generation is working.
- `reset` is high at the very start and then drops low, matching the testbench's reset sequence.
- `coin5` and `coin10` can be seen pulsing high individually at different points in time, corresponding to the coin-insertion sequence written in the testbench.
- `product` pulses high shortly after certain coin events — consistent with the FSM reaching a state where the required amount has been met.
- `change5` pulses high later in the simulation, at the point where a `coin10` is applied while the FSM is already in state `S5`, matching the overpayment case in the code.
- `change10` stays low for the entire simulation, which lines up with the fact that it is never driven high anywhere in the design.

Overall, the waveform confirms that `product` and `change5` respond to coin inputs in a way that matches the state transitions described in Section 5 — the outputs only turn on at the specific coin/state combinations coded in the design, not on every coin insertion.

## 10. RTL / Elaborated Design

![Elaborated RTL Design](https://github.com/VASUDEVARAO-SANKARAPU/VENDING-MACHINE-USING-VERILOG/blob/main/images/scheamtic_ven_D.jpeg?raw=true)

This is the elaborated (post-synthesis-analysis) schematic generated by Vivado directly from the RTL code, before any technology mapping. It shows how the Verilog description gets translated into generic hardware building blocks:

- **`RTL_REG_ASYNC` (state_reg[1:0])** — this is the 2-bit state register, with an asynchronous clear (`CLR`) tied to `reset`, a clock input (`C`), and data input/output (`D`/`Q`). This corresponds directly to the sequential `always` block in the code.
- **Multiple `RTL_MUX` blocks** — these implement the `case` statement logic. Vivado has broken the next-state and output logic down into a chain of multiplexers (`next_state_i`, `next_state_i__0`, `next_state_i__1` for the next-state bits, and similarly for `product_i` and `change5_i`), each selected by `coin5`, `coin10`, or the current state bits.
- **Inputs/outputs** — `coin10`, `coin5`, `reset`, and `clk` enter on the left, while `product`, `change10`, and `change5` exit on the right, matching the port list of the module exactly.
- The tool reports **9 cells, 7 I/O ports, and 15 nets** for this design, which is consistent with a small 2-state FSM with three outputs.

This view is useful because it shows that even a small `case`-based always block doesn't map to a single lookup table conceptually — Vivado represents it as a network of muxes feeding a register, which is essentially what any FSM synthesizes down to before it hits actual FPGA logic cells (LUTs, flip-flops).

## 11. Tools and Technologies

- Verilog HDL (RTL design)
- Xilinx Vivado (used for RTL elaboration and behavioral simulation)
- Vivado's elaborated schematic viewer
- Vivado's behavioral (functional) simulator

No FPGA board programming or bitstream generation was part of this project — only RTL elaboration and functional simulation were performed.

## 12. Project Files

| File | Description |
|------|-------------|
| `vending_machine.v` | Main vending machine controller (FSM, coin logic, outputs) |
| `vending_machine_tb.v` | Testbench used to drive and verify the design in simulation |
| `images/scheamtic_ven_D.jpeg` | Elaborated RTL schematic from Vivado |
| `images/timing_ven_D.jpeg` | Functional simulation waveform |
| `README.md` | Project documentation |

## 13. How to Run the Project

1. Open Xilinx Vivado and create a new RTL project.
2. Add `vending_machine.v` as a design source.
3. Add `vending_machine_tb.v` as a simulation source.
4. If Vivado doesn't automatically detect it, set `vending_machine_tb` as the simulation top module.
5. Run **Behavioral Simulation** from the Flow Navigator.
6. In the simulation waveform window, add the signals `clk`, `reset`, `coin5`, `coin10`, `product`, `change5`, and `change10` if they aren't already listed.
7. Run the simulation for the full duration (or until `$finish` is hit) and observe how `product` and `change5` respond to the coin sequences applied in the testbench.

Synthesis and hardware implementation steps are not covered here since this project was verified only at the RTL/simulation level.

## 14. What I Learned

- How to design a small FSM in Verilog using a two-`always`-block style (sequential state register + combinational next-state/output logic).
- The practical difference between sequential logic (clocked, uses non-blocking assignment) and combinational logic (uses blocking assignment inside `always @(*)`).
- How to write a basic testbench: generating a clock, applying a reset, and sequencing input stimuli with delays.
- How to read and interpret a timing/waveform diagram to confirm that outputs are behaving as expected.
- How Vivado's elaborated schematic represents RTL code as registers and multiplexers, which helped connect the abstract Verilog code to actual hardware structure.
- That it's easy to leave a port unused (like `change10` here) without realizing it until you actually trace through the logic — a good reminder to double-check every output is driven in every intended case.

## 15. Future Improvements

These are possible extensions, not things currently implemented:

- Support for more coin denominations (e.g., 1-unit or 20-unit coins)
- Actually handling `change10` for larger overpayment cases
- Multiple product types with individual pricing
- A product selection input
- Out-of-stock / inventory tracking
- More generalized change calculation instead of hardcoded single-denomination change
- FPGA implementation and hardware testing on a real board
- A seven-segment display interface to show inserted amount or change

## 16. Conclusion

This project demonstrates a basic but complete example of FSM-based digital design in Verilog — from writing the RTL, to verifying it with a testbench, to observing both the simulated behavior and the synthesized hardware structure. Even with just two states and two coin inputs, it touches on most of the core ideas needed for larger sequential design projects: state encoding, sequential vs. combinational logic, testbench stimulus generation, and reading RTL schematics. It served as a solid, hands-on way to connect Verilog code to actual hardware behavior.
