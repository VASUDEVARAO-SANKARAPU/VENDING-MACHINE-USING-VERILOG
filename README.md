# VENDING MACHINE USING VERILOG

PROJECT_IDEA

The idea of this project is to design a simple vending machine controller using Verilog HDL. The vending machine accepts two types of coins, ₹5 and ₹10. The machine keeps track of the amount inserted using a Finite State Machine (FSM). When the required amount is reached, the machine automatically provides the product. If the user inserts more money than required, the appropriate change is generated. The design has coin5 and coin10 as inputs and product, change5, and change10 as outputs.

WORKING_PRINCIPLE

The vending machine uses two states: S0, representing ₹0 inserted, and S5, representing ₹5 inserted. The current state is stored in a 2-bit register and is updated according to the clock signal. When reset is activated, the machine returns to the initial S0 state.

Initially, the machine is in S0. If a ₹5 coin is inserted, the machine moves to S5, indicating that ₹5 has been inserted. If a ₹10 coin is inserted while the machine is in S0, the product is immediately released and the machine returns to S0.

When the machine is in S5, inserting another ₹5 coin makes the total amount ₹10. The product is then released and the machine returns to S0. If a ₹10 coin is inserted while the machine is in S5, the total amount becomes ₹15. In this case, the product is released and ₹5 change is generated. After dispensing the product and change, the machine returns to the initial S0 state.

The testbench verifies the operation by applying different combinations of ₹5 and ₹10 coins. The reset is initially activated and then released. Different coin inputs are applied sequentially, and the product, change5, and change10 outputs are observed in the simulation waveform to verify the correct operation of the vending machine.