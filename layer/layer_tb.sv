`timescale 1ns / 1ps


module tb_layer ();
    localparam int IN_FMAP = 28;
    localparam int K_SIZE = 3;
    logic clk, rst, start, done;

    logic signed [ 7:0] fmap     [    IN_FMAP+2] [IN_FMAP+2];
    logic signed [ 7:0] weight   [K_SIZE*K_SIZE];
    logic signed [19:0] bias;
    logic signed [19:0] layer_out[      IN_FMAP] [  IN_FMAP];

 logic signed [7:0] img_mem[90000];
    logic signed [7:0] w_mem[288];
    logic signed [19:0] b_mem[32];
    logic signed [19:0] gold_mem[784];

    layer #(.IN_FMAP(IN_FMAP), .K_SIZE(K_SIZE)) u_layer (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .fmap     (fmap),
        .weight   (weight),
        .bias     (bias),
        .done     (done),
        .layer_out(layer_out)
    );

   
    // 클럭: 10ns 주기
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        int err;

        // 1) 파일 읽기
        $readmemh("test_images_pad.mem", img_mem);
        $readmemh("conv1_weight.mem", w_mem);
        $readmemh("conv1_bias.mem", b_mem);
        $readmemh("golden_conv1_img0_ch0.mem", gold_mem);

        for (int r = 0; r < IN_FMAP+2; r++)
            for (int c = 0; c < IN_FMAP+2; c++)
                fmap[r][c] = img_mem[r*(IN_FMAP+2) + c];   // 이미지 0
        for (int k = 0; k < K_SIZE*K_SIZE; k++)
            weight[k] = w_mem[k];                           // 채널 0
        bias = b_mem[0];                                    // 채널 0

        // 2) 리셋
        rst   = 1'b1;
        start = 1'b0;
        repeat (3) @(posedge clk);
        rst <= 1'b0;
        @(posedge clk);

        // 3) start 1클럭
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        // 4) done 대기
        wait (done == 1'b1);
        @(posedge clk);

        // 5) golden 비교
        err = 0;
        for (int r = 0; r < IN_FMAP; r++)
            for (int c = 0; c < IN_FMAP; c++)
                if (layer_out[r][c] !== gold_mem[r*IN_FMAP + c]) begin
                    if (err < 10)
                        $display("MISMATCH (%0d,%0d): rtl=%0d gold=%0d",
                                 r, c, layer_out[r][c], gold_mem[r*IN_FMAP + c]);
                    err++;
                end

        if (err == 0) $display("PASS: %0d개 모두 일치", IN_FMAP*IN_FMAP);
        else          $display("FAIL: 불일치 %0d개", err);
        $finish;
    end
endmodule
