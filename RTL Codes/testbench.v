`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/16/2024 07:52:59 PM
// Design Name: 
// Module Name: testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define headersize 1080
`define imgsize 262144
module testbench(

    );
    
    reg clk;
    reg reset;
    reg[7:0]imgdata;
    integer file, fileres,i;
    reg imgdatavalid;
    integer sentsize = 0;
    wire intr;
    wire[7:0] outdata;
    wire outdatavalid;
    integer rcvddata=0;
    
    
    initial
        begin
        clk = 1'b0;
        forever
            begin
                #5 clk = ~clk;
            end
        end
                
    initial
        begin
            reset = 1'b0;
            sentsize=1'b0;
            imgdatavalid =1'b0;
            #100
            reset = 1'b1;
            file = $fopen("lena_gray.bmp","rb");
            fileres = $fopen("blurred_lena_gray.bmp","wb");
            //fileres = $fopen("edgedetect_lena_gray.bmp,"wb");
            for (i=0;i<`headersize;i=i+1)
                begin
                    $fscanf(file,"%c",imgdata);
                    $fwrite(fileres, "%c", imgdata);
                end
            for(i=0;i<4*512;i=i+1)
                begin
                    @(posedge clk)
                    $fscanf(file,"%c",imgdata);
                    imgdatavalid <= 1'b1; 
                end
                sentsize = 4*512;
                @(posedge clk)
                imgdatavalid <= 1'b0;
                while(sentsize < `imgsize)
                    begin
                        @(posedge intr);
                        for(i=0;i<512;i=i+1)
                            begin
                                @(posedge clk)
                                $fscanf(file, "%c", imgdata);
                                imgdatavalid <= 1'b1;
                            end
                            @(posedge clk);
                            imgdatavalid <= 1'b0;
                            sentsize = sentsize + 512;
                     end
                     @(posedge clk);
                      imgdatavalid <= 1'b0;
                    @(posedge intr)
                    for(i=0;i<512;i=i+1)
                    begin
                        @(posedge clk)
                        imgdata <=0;
                        imgdatavalid <= 1'b1;
                    end
                    @(posedge clk);
                    imgdatavalid <= 1'b0;
                    @(posedge intr);
                    for(i=0;i<512;i=i+1)
                    begin
                    @(posedge clk)
                        imgdata <=0;
                        imgdatavalid <= 1'b1;
                    end
                    @(posedge clk)
                    imgdatavalid <= 1'b0;
                    $fclose(file);   
        end
        
        always@(posedge clk)
        begin
            if(outdatavalid)
                begin
                    $fwrite(fileres, "%c", outdata);
                    rcvddata = rcvddata +1;
                end
                if (rcvddata == `imgsize)
                    begin
                        $fclose(fileres);
                        $stop;
                    end
        end
    
imageprocessingtop dut(
 .axi_clk(clk),                         //AXI clock
 .axi_reset(reset),                     //AXI reset

 .i_data_valid(imgdatavalid),           //slave-side AXI interface
 .i_data(imgdata),
 .o_data_ready(),

 .o_data_valid(outdatavalid),           //master-side AXI interface
 .o_data(outdata),
 .i_data_ready(1'b1),

 .o_intr(intr)                          //AXI interrupt signal
);
endmodule
