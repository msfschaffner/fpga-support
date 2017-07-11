/**
 * Inferable, Synchronous Single-Port RAM
 *
 * This module is designed to work with both Xilinx and Altera tools by following the respective
 * guidelines:
 * - Xilinx UG901 Vivado Design Suite User Guide: Synthesis (p. 106)
 * - Altera Quartus II Handbook Volume 1: Design and Synthesis (p. 768)
 *
 * Copyright (c) 2014 ETH Zurich and University of Bologna.  All rights reserved.
 *
 * Current Maintainers:
 * - Michael Schaffner  <schaffer@iis.ee.ethz.ch>
 */

module SyncSpRam
#(
  parameter ADDR_WIDTH = 10,
  parameter DATA_DEPTH = 1024, // usually 2**ADDR_WIDTH, but can be lower
  parameter DATA_WIDTH = 32,
  parameter OUT_REGS   = 0
) (
  input  logic                    Clk_CI,
  input  logic                    Rst_RBI,
  input  logic                    CSel_SI,
  input  logic                    WrEn_SI,
  input  logic [ADDR_WIDTH-1:0]   Addr_DI,
  input  logic [DATA_WIDTH-1:0]   WrData_DI,
  output logic [DATA_WIDTH-1:0]   RdData_DO
);

  ////////////////////////////
  // signals, localparams
  ////////////////////////////

  logic [DATA_WIDTH-1:0] RdData_DN;
  logic [DATA_WIDTH-1:0] RdData_DP;
  logic [DATA_WIDTH-1:0] Mem_DP [DATA_DEPTH-1:0];

  ////////////////////////////
  // XILINX/ALTERA implementation
  ////////////////////////////

  always_ff @(posedge Clk_CI)
  begin
    if (CSel_SI) begin
      if (WrEn_SI) begin
        Mem_DP[Addr_DI] <= WrData_DI;
      end
      else
      begin
        RdData_DN <= Mem_DP[Addr_DI];
      end
    end
  end

  ////////////////////////////
  // optional output regs
  ////////////////////////////

  // output regs
  generate
    if (OUT_REGS>0) begin : g_outreg
      always_ff @(posedge Clk_CI or negedge Rst_RBI) begin
        if(Rst_RBI == 1'b0)
        begin
          RdData_DP  <= 0;
        end
        else
        begin
          RdData_DP  <= RdData_DN;
        end
      end
    end
  endgenerate // g_outreg

  // output reg bypass
  generate
    if (OUT_REGS==0) begin : g_oureg_byp
      assign RdData_DP  = RdData_DN;
    end
  endgenerate// g_oureg_byp

  assign RdData_DO = RdData_DP;

  ////////////////////////////
  // assertions
  ////////////////////////////

  // pragma translate_off
  assert property
    (@(posedge Clk_CI) (longint'(2)**longint'(ADDR_WIDTH) >= longint'(DATA_DEPTH)))
    else $error("depth out of bounds");
  // pragma translate_on

endmodule // SyncSpRam
