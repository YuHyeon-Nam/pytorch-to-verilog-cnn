`timescale 1ns / 1ps

module layer #(
    parameter IN_FMAP = 28,
    parameter K_SIZE  = 3
) (
    input logic clk,
    input logic rst,
    input logic start,
    input logic signed [7:0] fmap[IN_FMAP+2][IN_FMAP+2],
    input logic signed [7:0] weight[K_SIZE*K_SIZE],
    input logic signed [19:0] bias,
    output logic done,
    output logic signed [19:0] layer_out[IN_FMAP][IN_FMAP]
);
    logic signed [ 7:0] in_f        [K_SIZE*K_SIZE];
    logic signed [19:0] sum_out     [      IN_FMAP] [IN_FMAP];  //unpacked
    logic signed [19:0] out_sum_reg;
    logic        [ $clog2(IN_FMAP)-1:0] row;
    logic        [ $clog2(IN_FMAP)-1:0] col;
    logic               count_en;
    logic               last;

    assign in_f[0] = fmap[row][col];
    assign in_f[1] = fmap[row][col+1];
    assign in_f[2] = fmap[row][col+2];
    assign in_f[3] = fmap[row+1][col];
    assign in_f[4] = fmap[row+1][col+1];
    assign in_f[5] = fmap[row+1][col+2];
    assign in_f[6] = fmap[row+2][col];
    assign in_f[7] = fmap[row+2][col+1];
    assign in_f[8] = fmap[row+2][col+2];

    assign layer_out = sum_out;
    assign last = (row == (IN_FMAP - 1)) && (col == (IN_FMAP - 1));

    typedef enum logic {
        IDLE,
        RUN
    } state_t;

    state_t c_state, n_state;

    always_ff @(posedge clk) begin
        if (rst) begin
            row <= '0;
            col <= '0;
            c_state <= IDLE;
            done <= 1'b0;
        end else begin
            c_state <= n_state;
            done <= (c_state == RUN) && last;
            if (count_en) begin
                if (col == IN_FMAP - 1) begin
                    col <= '0;
                    if (row == IN_FMAP - 1) begin
                        row <= '0;
                    end else row <= row + 5'd1;
                end else begin
                    col <= col + 5'd1;
                end
                sum_out[row][col] <= out_sum_reg + bias;
            end
        end
    end

    always_comb begin
        n_state  = c_state;
        count_en = 1'b0;
        case (c_state)
            IDLE: begin
                if (start) begin
                    n_state = RUN;
                end
            end
            RUN: begin
                count_en = 1'b1;
                if (last) begin
                    n_state = IDLE;
                end
            end
        endcase
    end

    sum u_sum (
        .weight(weight),
        .in_f(in_f),
        .out_sum(out_sum_reg)
    );


endmodule
