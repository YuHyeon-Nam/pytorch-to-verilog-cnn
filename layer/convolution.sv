`timescale 1ns / 1ps

module conv (
    input  logic signed [ 7:0] weight,
    input  logic signed [ 7:0] in_f,
    output logic signed [15:0] out_conv
);

    assign out_conv = weight * in_f;

endmodule
