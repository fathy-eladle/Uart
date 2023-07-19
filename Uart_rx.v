`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2023 04:47:43 PM
// Design Name: 
// Module Name: Uart
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


module Uart #(parameter BITS_d = 8,     //num_bits of data
                N_TICK = 16            // num of ticks in bit
    )
    (
        input clk, reset,
        input rx, s_tick,
        output reg rx_done_tick,
        output [BITS_d - 1:0] rx_dout
    );
    
    localparam  idle = 0, start = 1,
                data = 2, stop = 3;
                
    reg [1:0] state_reg, state_next;
    reg [3:0] s_reg, s_next;                //  baud rate ticks (16 total)
    reg [$clog2(BITS_d) - 1:0] n_reg, n_next; // num_bits of data
    reg [BITS_d - 1:0] b_reg, b_next;         // shifted data bits
    
    // State and other registers
    always @(posedge clk, negedge reset)
    begin
        if (reset)
        begin
            state_reg <= idle;
            s_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
        end
        else
        begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
        end
    end
    
    // Next state logic
    always @(*)
    begin
        state_next = state_reg;
        s_next = s_reg;
        n_next = n_reg;
        b_next = b_reg;
        rx_done_tick = 1'b0;
        case (state_reg)
            idle:                
                if (~rx)
                begin
                    s_next = 0;
                    state_next = start;                        
                end                 
            start:                
                if (s_tick)
                    if (s_reg == 7)
                    begin
                        s_next = 0;
                        n_next = 0;
                        state_next = data;
                    end
                    else                        
                        s_next = s_reg + 1;                                                                   
            data:
                if (s_tick)
                    if(s_reg == 15)
                    begin
                        s_next = 0;
                        b_next = {rx, b_reg[BITS_d - 1:1]}; 
                        if (n_reg == (BITS_d - 1))
                            state_next = stop;
                        else
                            n_next = n_reg + 1;
                    end
                    else
                        s_next = s_reg + 1;
            stop:
                if (s_tick)
                    if(s_reg == ( N_TICK - 1))
                    begin
                        rx_done_tick = 1'b1;
                        state_next = idle;
                    end
                    else
                        s_next = s_reg + 1;
            default:
                state_next = idle;
        endcase
    end
    
    // output
    assign rx_dout = b_reg;
endmodule
