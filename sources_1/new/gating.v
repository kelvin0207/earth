`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/16 16:48:43
// Design Name: Gating module
// Module Name: gating
// Project Name: EARTH
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



/////////////////// FUNCTION NOTE: //////////////////
// drafted by Jingkui

/////// For Router-Linear computation /////////
// 1. Gating module recieves the results from output collector (RL-out)

// 2. on top-k module:
// finish the top-k tell main ctrl. to load the experts

// 3. on Arith. module:
// finish softmax and norm. to get weight, stored in local buffer for later use

//////// For Activation Function (GELU as an example) //////
// 1. Gating module recieves the results from output collector (Up-proj out)

// 2. on Arith. module:
// finish non-linear calculaiton (16 results on cycle).

//////// For Aggregation (Final operation) //////
// 1. Gating module recieves the results from output collector (expert-out / Down-proj out)

// 2. on Arth. module:
// load the weights stored in local buffer, and multiply with expert-out 
// (for the second and following expert-out) load previous partial sum from Token buffer 
// (only 16 FP16 results)
// Accumulate with the previous psum (16-ele vector)
// write back to Token buffer

/////////////////// FUNCTION NOTE END //////////////////
