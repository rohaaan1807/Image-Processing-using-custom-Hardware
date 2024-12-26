`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/05/2024 10:56:48 PM
// Design Name: 
// Module Name: linebuffer
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


module linebuffer(
input i_clk,                    //line buffer clock
input i_rst,                    //line buffer reset
input [7:0]i_data,              //data input to the buffer
input i_data_valid,             //indication for valid data 
output [23:0]o_data,            //3x8 = 24 bits of output data to be read from the line buffer at once
input i_rd_data                 //indication for reading data from the line buffer
);

reg [7:0]line[511:0];           //line buffer (512x512 image with each pixel of size 8 bit)
reg [8:0]wrptr;                 //write-pointer to tell where the incoming pixel data should be stored in the line buffer
reg [8:0]rdptr;                 //read-pointer to tell from where the next pixel data should be read out of the line buffer  

always @(posedge i_clk)
begin                           //if a valid pixel data is available, send it to write-pointer
   if(i_data_valid)
        line[wrptr] <= i_data;   
end

always @(posedge i_clk)
begin                           //flush the write-pointer to empty state on reset 
    if(i_rst)
        wrptr <= 'd0;
    else if(i_data_valid)       //increment write-pointer to indicate the next location
        wrptr <= wrptr + 'd1;    
end

assign o_data = {line[rdptr],line[rdptr+1],line[rdptr+2]}; //reading 3 pixels, i.e. 24 bits of data at once

always @(posedge i_clk)
begin                           //flush the read-pointer to empty state on reset 
    if(i_rst)
        rdptr <= 'd0;
    else if(i_rd_data)       //increment read-pointer to indicate the next location
        rdptr <= rdptr + 'd1;    
end

endmodule
