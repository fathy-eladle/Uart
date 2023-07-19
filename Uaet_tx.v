`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2023 05:06:29 PM
// Design Name: 
// Module Name: Uart_tx
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


module Uart_tx #(parameter BITS_d = 8,   //num_bits of data
                N_TICK = 16            // num of ticks in bit
    )
    (
        input clk, reset,
        input tx_start, s_tick,        
        input [BITS_d - 1:0] tx_din,
        output reg tx_done_tick,
        output tx
        
    );
    
    localparam  idle = 0, start = 1,
                data = 2, stop = 3;
                
    reg [1:0] state_reg, state_next;
    reg [3:0] s_reg, s_next;                // baud rate ticks(16 total)
    reg [$clog2(BITS_d) - 1:0] n_reg, n_next; // num_bits of data
    reg [BITS_d - 1:0] b_reg, b_next;         // shifted data bits
    reg tx_reg, tx_next;                    // track the transmitted bit
    
    // State and other registers
    always @(posedge clk, posedge reset)
    begin
        if (reset)
        begin
            state_reg <= idle;
            s_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
            tx_reg <= 1'b1;
        end
        else
        begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
            tx_reg <= tx_next;
        end
    end
    
    // Next state logic
    always @(*)
    begin
        state_next = state_reg;
        s_next = s_reg;
        n_next = n_reg;
        b_next = b_reg;
        tx_done_tick = 1'b0;
        case (state_reg)
            idle:   
            begin    
                tx_next = 1'b1;         
                if (tx_start)
                begin
                    s_next = 0;
                    b_next = tx_din;
                    state_next = start;                        
                end
            end                 
            start:    
            begin
                tx_next = 1'b0;            
                if (s_tick)
                    if (s_reg == 15)
                    begin
                        s_next = 0;
                        n_next = 0;
                        state_next = data;
                    end
                    else                        
                        s_next = s_reg + 1;
            end                                                                                       
            data:
            begin
                tx_next = b_reg[0];
                if (s_tick)
                    if(s_reg == 15)
                    begin
                        s_next = 0;
                        b_next = {1'b0, b_reg[BITS_d - 1:1]}; // Right shift
                        if (n_reg == (BITS_d - 1))
                            state_next = stop;
                        else
                            n_next = n_reg + 1;
                    end
                    else
                        s_next = s_reg + 1;
            end
            stop:
            begin
                tx_next = 1'b1;
                if (s_tick)
                    if(s_reg == ( N_TICK - 1))
                    begin
                        tx_done_tick = 1'b1;
                        state_next = idle;
                    end
                    else
                        s_next = s_reg + 1;                        
            end
            default:
                state_next = idle;
        endcase
    end
    
    // output 
    assign tx = tx_reg;
endmodule
