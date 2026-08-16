module vending_machine (
    input clk,
    input reset,
    input coin5,
    input coin10,
    output reg product,
    output reg change5,
    output reg change10
);

    parameter S0 = 2'b00;
    parameter S5 = 2'b01;

    reg [1:0] state;
    reg [1:0] next_state;

    always @(posedge clk or posedge reset)
    begin
        if (reset)
            state <= S0;
        else
            state <= next_state;
    end

    always @(*)
    begin
        next_state = state;

        product  = 1'b0;
        change5  = 1'b0;
        change10 = 1'b0;

        case (state)

            S0:
            begin
                if (coin5)
                    next_state = S5;

                else if (coin10)
                begin
                    product = 1'b1;
                    next_state = S0;
                end

                else
                    next_state = S0;
            end

            S5:
            begin
                if (coin5)
                begin
                    product = 1'b1;
                    next_state = S0;
                end

                else if (coin10)
                begin
                    product = 1'b1;
                    change5 = 1'b1;
                    next_state = S0;
                end

                else
                    next_state = S5;
            end

            default:
            begin
                next_state = S0;
                product = 1'b0;
                change5 = 1'b0;
                change10 = 1'b0;
            end

        endcase
    end

endmodule