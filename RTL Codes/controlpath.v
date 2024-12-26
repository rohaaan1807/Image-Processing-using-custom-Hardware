`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2024 01:49:21 PM
// Design Name: 
// Module Name: controlpath
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


module controlpath(
input i_clk,                                //control path clock
input i_rst,                                //control path reset
input [7:0]i_pixel_data,                    //input interface for line buffer
input i_pixel_data_valid,                   //indication for valid data 
output reg [71:0]o_pixel_data,              //output interface for line buffers
output o_pixel_data_valid,                  //indication for valid data
output reg o_intr                           //interrupt signal for AXI stream use
);

reg [8:0]pixelcounter;                      //pixel-counter to control the line buffer selection to write to
reg [1:0]currentwrlinebuffer;               //indication of the currently selected line buffer for writing
reg [3:0]linebuffer_data_valid;             //combined 4 bit valid flag for all 4 line buffers
reg [3:0]linebuffer_rd_data;                //combined 4 bit flag for setting read signal from the line buffers 
reg [1:0]currentrdlinebuffer;               //indication of the currently selected line buffer for reading
reg [8:0]rdcounter;                         //read-counter to control the line buffer  selection to read from
reg rdlinebuffer;                           //internal signal to control the setting of read signals of the line buffers
wire [23:0]lb0data;                         //wire-ports to read data from the line buffer multiplexed assembly
wire [23:0]lb1data;
wire [23:0]lb2data;
wire [23:0]lb3data;
reg [11:0]totalpixelcounter;                //counter to store the count of valid pixel data stored in the line buffers
reg rdState;                                //State Machine's state bit

localparam IDLE = 'b0, RD_BUFFER = 'b1;     //State Machine's parameters

assign o_pixel_data_valid = rdlinebuffer;   //indication of a valid output pixel data

always @(posedge i_clk)                     //logic for updating the value of the total pixel counts 
begin
    if(i_rst)
        totalpixelcounter <= 0;
    else                                    //if pixel data arrives and read operation is not done then increase the count by 1
    begin                                   //if pixel data doesnt arrive and read operation is done then decrease the count by 1
        if(i_pixel_data_valid & !rdlinebuffer)
            totalpixelcounter <= totalpixelcounter + 1;
        else if(!i_pixel_data_valid & rdlinebuffer)
            totalpixelcounter <= totalpixelcounter - 1;
    end
end

always @(posedge i_clk)                     //State Machine for updating the value of rdlinebuffer signal
begin
    if(i_rst)
    begin
        rdState <= IDLE;
        rdlinebuffer <= 1'b0;
        o_intr <= 1'b0;
    end
    else
    begin
        case(rdState)
        
            IDLE:begin
                o_intr <= 1'b0;
                if(totalpixelcounter >= 1536)
                begin
                    rdlinebuffer <= 1'b1;
                    rdState <= RD_BUFFER;
                end
                end
                
            RD_BUFFER:begin
                if(rdcounter == 511)
                begin
                    rdState <= IDLE;
                    rdlinebuffer <= 1'b0;
                    o_intr <= 1'b1;
                end
                end
                
        endcase
    end
end

always @(posedge i_clk)                     //logic for updating and resetting the pixel-counter
begin
    if(i_rst)
        pixelcounter <=0;
    else
    begin
        if (i_pixel_data_valid)
            pixelcounter <= pixelcounter+1;
    end
end

always @(posedge i_clk)                     //logic for selecting the line buffers for writing to them
begin                                        
    if(i_rst)
        currentwrlinebuffer <= 0;
    else
    begin
        if(pixelcounter == 511 & i_pixel_data_valid)
            currentwrlinebuffer <= currentwrlinebuffer+1;
    end
end

always @(*)                                 //logic for updating the valid flags for the line buffers
begin
    linebuffer_data_valid = 4'h0;
    linebuffer_data_valid[currentwrlinebuffer] = i_pixel_data_valid;
end

always @(posedge i_clk)
begin
    if(i_rst)
        rdcounter <= 0;
    else 
    begin
        if(rdlinebuffer)
            rdcounter <= rdcounter + 1;
    end
end

always @(posedge i_clk)
begin
    if(i_rst)
    begin
        currentrdlinebuffer <= 0;
    end
    else
    begin
        if(rdcounter == 511 & rdlinebuffer)
            currentrdlinebuffer <= currentrdlinebuffer+1;
    end
end

always @(*)                                 //logic for selecting the line buffers for reading from them
begin
    case(currentrdlinebuffer)
        0:begin
            o_pixel_data = {lb2data,lb1data,lb0data};
        end
        
        1:begin
            o_pixel_data = {lb3data,lb2data,lb1data};
        end
        
        2:begin
            o_pixel_data = {lb0data,lb3data,lb2data};
        end
        
        3:begin
            o_pixel_data = {lb1data,lb0data,lb3data};
        end
    endcase
end

always @(*)                                 //logic to set the read signal flag of the line buffers 
begin
    case(currentrdlinebuffer)
    0:begin
        linebuffer_rd_data[0] = rdlinebuffer;
        linebuffer_rd_data[1] = rdlinebuffer;
        linebuffer_rd_data[2] = rdlinebuffer;
        linebuffer_rd_data[3] = 1'b0;
    end
    
    1:begin
        linebuffer_rd_data[0] = 1'b0;
        linebuffer_rd_data[1] = rdlinebuffer;
        linebuffer_rd_data[2] = rdlinebuffer;
        linebuffer_rd_data[3] = rdlinebuffer;
    end
    
    2:begin
        linebuffer_rd_data[0] = rdlinebuffer;
        linebuffer_rd_data[1] = 1'b0;
        linebuffer_rd_data[2] = rdlinebuffer;
        linebuffer_rd_data[3] = rdlinebuffer;
    end
    
    3:begin
        linebuffer_rd_data[0] = rdlinebuffer;
        linebuffer_rd_data[1] = rdlinebuffer;
        linebuffer_rd_data[2] = 1'b0;
        linebuffer_rd_data[3] = rdlinebuffer;
    end
    endcase
end




                                            //line buffer modules instantiated to be used in the control path
linebuffer lb0(
.i_clk(i_clk),
.i_rst(i_rst),                    
.i_data(i_pixel_data),              
.i_data_valid(linebuffer_data_valid[0]),             
.o_data(lb0data),            
.i_rd_data(linebuffer_rd_data[0])                 
);

linebuffer lb1(
.i_clk(i_clk),
.i_rst(i_rst),                    
.i_data(i_pixel_data),              
.i_data_valid(linebuffer_data_valid[1]),             
.o_data(lb1data),            
.i_rd_data(linebuffer_rd_data[1])                 
);

linebuffer lb2(
.i_clk(i_clk),
.i_rst(i_rst),                    
.i_data(i_pixel_data),              
.i_data_valid(linebuffer_data_valid[2]),             
.o_data(lb2data),            
.i_rd_data(linebuffer_rd_data[2])                 
);

linebuffer lb3(
.i_clk(i_clk),
.i_rst(i_rst),                    
.i_data(i_pixel_data),              
.i_data_valid(linebuffer_data_valid[3]),             
.o_data(lb3data),            
.i_rd_data(linebuffer_rd_data[3])                 
);

endmodule
