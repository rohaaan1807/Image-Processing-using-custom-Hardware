`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/17/2024 02:57:48 AM
// Design Name: 
// Module Name: convoluter1
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

module convoluter1(
input        i_clk,                             //convolutor clock
input [71:0] i_pixel_data,                      //24x3 = 72 bits of input data read from 3 multiplexed line buffers
input        i_pixel_data_valid,                //indication for valid pixel input data
output reg [7:0] o_convolved_data,              //single pixel data output of the convoluter
output reg   o_convolved_data_valid             //indication for valid pixel output data
    );
    
integer i; 
reg [7:0] kernel1 [8:0];                        //2D-kernel matrix with 9 pixels, each holding 8 bits of data
reg [7:0] kernel2 [8:0];                        //2D-kernel matrix with 9 pixels, each holding 8 bits of data
reg [10:0] multData1[8:0];                      //2D-data matrix with 9 pixels, each holding 11 bits of multiplied data
reg [10:0] multData2[8:0];                      //2D-data matrix with 9 pixels, each holding 11 bits of multiplied data
reg [10:0] sumDataInt1;                         //11 bits of intermediate sums of multiplied data
reg [10:0] sumDataInt2;                         //11 bits of finished sum of multiplied data
reg [10:0] sumData1;
reg [10:0] sumData2;
reg multDataValid;
reg sumDataValid;
reg convolved_data_valid;
reg [20:0] convolved_data_int1;
reg [20:0] convolved_data_int2;
wire [21:0] convolved_data_int;
reg convolved_data_int_valid;

initial
begin                                           //Sobel Kernels in X and Y axes
    kernel1[0] =  1;
    kernel1[1] =  0;
    kernel1[2] = -1;
    kernel1[3] =  2;
    kernel1[4] =  0;
    kernel1[5] = -2;
    kernel1[6] =  1;
    kernel1[7] =  0;
    kernel1[8] = -1;
    
    kernel2[0] =  1;
    kernel2[1] =  2;
    kernel2[2] =  1;
    kernel2[3] =  0;
    kernel2[4] =  0;
    kernel2[5] =  0;
    kernel2[6] = -1;
    kernel2[7] = -2;
    kernel2[8] = -1;
end    
    
always @(posedge i_clk)                        //multiplying the kernel with the input pixel data 
begin                                          //first pipeline stage
    for(i=0;i<9;i=i+1)
    begin                                      //Due to negative values we need $signed directive
        multData1[i] <= $signed(kernel1[i])*$signed({1'b0,i_pixel_data[i*8+:8]});       
        multData2[i] <= $signed(kernel2[i])*$signed({1'b0,i_pixel_data[i*8+:8]});
    end
    multDataValid <= i_pixel_data_valid;       
end


always @(*)                                    //purely combinational parallel adders
begin                       
    sumDataInt1 = 0;
    sumDataInt2 = 0;
    for(i=0;i<9;i=i+1)
    begin
        sumDataInt1 = $signed(sumDataInt1) + $signed(multData1[i]);             //sum of each multiplied value
        sumDataInt2 = $signed(sumDataInt2) + $signed(multData2[i]);
    end
end

always @(posedge i_clk)
begin                                           //second pipeline stage
    sumData1 <= sumDataInt1;                    //finished sum of all multiplied values
    sumData2 <= sumDataInt2;
    sumDataValid <= multDataValid;
end

always @(posedge i_clk)     
begin                                          //third pipeline stage
    convolved_data_int1 <= $signed(sumData1)*$signed(sumData1);                 //square of Mx and My
    convolved_data_int2 <= $signed(sumData2)*$signed(sumData2);
    convolved_data_int_valid <= sumDataValid;
end

assign convolved_data_int = convolved_data_int1+convolved_data_int2;

    
always @(posedge i_clk)
begin                                          //fourth pipeline stage
    if(convolved_data_int > 4000)
        o_convolved_data <= 8'hff;
    else                                       //assigning the final convolved output value of the pixel
        o_convolved_data <= 8'h00;
    o_convolved_data_valid <= convolved_data_int_valid;
end
    
endmodule
