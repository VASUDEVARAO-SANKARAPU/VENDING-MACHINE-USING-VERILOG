`timescale 1ns/1ps

module vending_machine_tb;

    reg clk;
    reg reset;
    reg coin5;
    reg coin10;

    wire product;
    wire change5;
    wire change10;

    vending_machine uut (
        .clk(clk),
        .reset(reset),
        .coin5(coin5),
        .coin10(coin10),
        .product(product),
        .change5(change5),
        .change10(change10)
    );

    always #5 clk = ~clk;

    initial
    begin
        clk = 0;
        reset = 1;
        coin5 = 0;
        coin10 = 0;

        #10;
        reset = 0;

        #10;
        coin5 = 1;
        #10;
        coin5 = 0;

        #10;
        coin5 = 1;
        #10;
        coin5 = 0;

        #10;
        coin10 = 1;
        #10;
        coin10 = 0;

        #10;
        coin5 = 1;
        #10;
        coin5 = 0;

        #10;
        coin10 = 1;
        #10;
        coin10 = 0;

        #20;
        $finish;
    end

    initial
    begin
        $monitor("Time=%0t | Reset=%b | Coin5=%b | Coin10=%b | Product=%b | Change5=%b | Change10=%b",
                 $time, reset, coin5, coin10, product, change5, change10);
    end

endmodule