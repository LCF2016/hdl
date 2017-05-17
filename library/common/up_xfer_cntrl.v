// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2017 (c) Analog Devices, Inc. All rights reserved.
//
// Each core or library found in this collection may have its own licensing terms. 
// The user should keep this in in mind while exploring these cores. 
//
// Redistribution and use in source and binary forms,
// with or without modification of this file, are permitted under the terms of either
//  (at the option of the user):
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory, or at:
// https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html
//
// OR
//
//   2.  An ADI specific BSD license as noted in the top level directory, or on-line at:
// https://github.com/analogdevicesinc/hdl/blob/dev/LICENSE
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module up_xfer_cntrl #(

  parameter     DATA_WIDTH = 8) (

  // up interface

  input                   up_rstn,
  input                   up_clk,
  input       [DW:0]      up_data_cntrl,
  output  reg             up_xfer_done,

  // device interface

  input                   d_rst,
  input                   d_clk,
  output  reg [DW:0]      d_data_cntrl);

  localparam    DW = DATA_WIDTH - 1;

  // internal registers

  reg             up_xfer_state_m1 = 'd0;
  reg             up_xfer_state_m2 = 'd0;
  reg             up_xfer_state = 'd0;
  reg     [ 5:0]  up_xfer_count = 'd0;
  reg             up_xfer_toggle = 'd0;
  reg     [DW:0]  up_xfer_data = 'd0;
  reg             d_xfer_toggle_m1 = 'd0;
  reg             d_xfer_toggle_m2 = 'd0;
  reg             d_xfer_toggle_m3 = 'd0;
  reg             d_xfer_toggle = 'd0;

  // internal signals

  wire            up_xfer_enable_s;
  wire            d_xfer_toggle_s;

  // device control transfer

  assign up_xfer_enable_s = up_xfer_state ^ up_xfer_toggle;

  always @(negedge up_rstn or posedge up_clk) begin
    if (up_rstn == 1'b0) begin
      up_xfer_state_m1 <= 'd0;
      up_xfer_state_m2 <= 'd0;
      up_xfer_state <= 'd0;
      up_xfer_count <= 'd0;
      up_xfer_done <= 'd0;
      up_xfer_toggle <= 'd0;
      up_xfer_data <= 'd0;
    end else begin
      up_xfer_state_m1 <= d_xfer_toggle;
      up_xfer_state_m2 <= up_xfer_state_m1;
      up_xfer_state <= up_xfer_state_m2;
      up_xfer_count <= up_xfer_count + 1'd1;
      up_xfer_done <= (up_xfer_count == 6'd1) ? ~up_xfer_enable_s : 1'b0;
      if ((up_xfer_count == 6'd1) && (up_xfer_enable_s == 1'b0)) begin
        up_xfer_toggle <= ~up_xfer_toggle;
        up_xfer_data <= up_data_cntrl;
      end
    end
  end

  assign d_xfer_toggle_s = d_xfer_toggle_m3 ^ d_xfer_toggle_m2;

  always @(posedge d_clk or posedge d_rst) begin
    if (d_rst == 1'b1) begin
      d_xfer_toggle_m1 <= 'd0;
      d_xfer_toggle_m2 <= 'd0;
      d_xfer_toggle_m3 <= 'd0;
      d_xfer_toggle <= 'd0;
      d_data_cntrl <= 'd0;
    end else begin
      d_xfer_toggle_m1 <= up_xfer_toggle;
      d_xfer_toggle_m2 <= d_xfer_toggle_m1;
      d_xfer_toggle_m3 <= d_xfer_toggle_m2;
      d_xfer_toggle <= d_xfer_toggle_m3;
      if (d_xfer_toggle_s == 1'b1) begin
        d_data_cntrl <= up_xfer_data;
      end
    end
  end

endmodule

// ***************************************************************************
// ***************************************************************************
