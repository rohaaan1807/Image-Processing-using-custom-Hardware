`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2024 12:45:29 AM
// Design Name: 
// Module Name: convolutor
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


module convolutor(
input i_clk,                                    //convolutor clock
input [71:0]i_pixel_data,                       //24x3 = 72 bits of input data read from 3 multiplexed line buffers
input i_pixel_data_valid,                       //indication for valid pixel input data
output reg [7:0]o_convolved_data,               //single pixel data output of the convoluter 
output reg o_convolved_data_valid                   //indication for valid pixel output data 
);

integer i;
reg [7:0]kernel[8:0];                           //2D-kernel matrix with 9 pixels, each holding 8 bits of data
reg [15:0]multiplied_data[8:0];                 //2D-data matrix with 9 pixels, each holding 16 bits of multiplied data
reg [15:0]sum_data_intr;                        //16 bits of intermediate sums of multiplied data
reg [15:0]sum_data;                             //16 bits of finished sum of multiplied data
reg multiplied_data_valid;                      //pipeline's multiplication stage valid signal
reg sum_data_valid;                             //pipeline's addition stage valid signal
reg convolved_data_valid;                       //pipeline's convolution stage valid signal
initial                                         //initializing the value of kernel elements via a loop   
begin
    for(i=0;i<9;i=i+1)
    begin
        kernel[i] = 1;                          //kernel for an averaging or blurring operation
    end
end

always @(posedge i_clk)                         //multiplying the kernel with the input pixel data 
begin                                           //first pipeline stage
    for(i=0;i<9;i=i+1)
    begin
        multiplied_data[i] <= kernel[i]*i_pixel_data[i*8+:8];       //storing the result of multiplication of kernel matrix with the pixel data
    end
    multiplied_data_valid <= i_pixel_data_valid; 
end 

always @(*)                                     //purely combinational parallel adders 
begin
    sum_data_intr = 0;
    for(i=0;i<9;i=i+1)
    begin
        sum_data_intr = sum_data_intr + multiplied_data[i];         //sum of each multiplied value
    end
end

always @(posedge i_clk)
begin                                           //second pipeline stage
    sum_data = sum_data_intr;                   //finished sum of all multiplied values
    sum_data_valid <= multiplied_data_valid;
end

always @(posedge i_clk)
begin                                           //third pipeline stage
    o_convolved_data <= sum_data/9;             //assigning the final convolved output value of the pixel
    o_convolved_data_valid <= sum_data_valid;
end

endmodule
