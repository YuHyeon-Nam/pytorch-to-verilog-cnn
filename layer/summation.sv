`timescale 1ns / 1ps


module sum (
    input  logic signed [ 7:0] weight[9],
    input  logic signed [ 7:0] in_f[9],
    output logic signed [19:0] out_sum
);

    logic signed [15:0] out_conv[9];
    logic signed [19:0] out_sum_reg;

    genvar i;
    generate
        for (i = 0; i < 9; i++) begin
            conv u_conv (
                .weight(weight[i]),
                .in_f(in_f[i]),
                .out_conv(out_conv[i])
            );
        end
    endgenerate

    always_comb begin
        out_sum_reg = '0;
        for (int j =0;j<9;j++ ) begin
            out_sum_reg = out_sum_reg + out_conv[j];
        end
        out_sum = out_sum_reg;
    end
endmodule
