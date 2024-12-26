`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 04:47:26 AM
// Design Name: 
// Module Name: imageprocessingtop
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


module imageprocessingtop(
input axi_clk,                      //AXI clock
input axi_reset,                    //AXI reset

input i_data_valid,                 //slave-side AXI interface
input [7:0]i_data,
output o_data_ready,

output o_data_valid,                //master-side AXI interface
output [7:0]o_data,
input i_data_ready,

output o_intr                       //AXI interrupt signal
);

wire [71:0]pixel_data;
wire pixel_data_valid;
wire axis_prog_full; 
wire [7:0]convolved_data;
wire convolved_data_valid;

assign o_data_ready =!axis_prog_full;
                                    
                                    
                                    //line buffer control path module instantiated to be used 
controlpath conpat(                    
.i_clk(axi_clk),                                
.i_rst(!axi_rst),                                
.i_pixel_data(i_data),                    
.i_pixel_data_valid(i_data_valid),                    
.o_pixel_data(pixel_data),              
.o_pixel_data_valid(pixel_data_valid),
.o_intr(o_intr)                   
);




                                    //convolutor module instantiated to be used
convolutor conv(
.i_clk(axi_clk),                                    
.i_pixel_data(pixel_data),                       
.i_pixel_data_valid(pixel_data_valid),                       
.o_convolved_data(convolved_data),               
.o_convolved_data_valid(convolved_data_valid)                    
);




                                    //FIFO buffer IP instantiated to manage pipelined data transfer
fifo_generator_0 your_instance_name (
  .wr_rst_busy(),        
  .rd_rst_busy(),        
  .s_aclk(axi_clk),                  
  .s_aresetn(axi_reset),            
  .s_axis_tvalid(convolved_data_valid),    
  .s_axis_tready(),    
  .s_axis_tdata(convolved_data),      
  .m_axis_tvalid(o_data_valid),    
  .m_axis_tready(i_data_ready),    
  .m_axis_tdata(o_data),      
  .axis_prog_full(axis_prog_full)  
);

endmodule