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
// Input must be RGB or CrYCb in that order, output is CrY/CbY

module ad_ss_444to422 #(

  parameter   CR_CB_N = 0,
  parameter   DELAY_DATA_WIDTH = 16) (

  // 444 inputs

  input                   clk,
  input                   s444_de,
  input       [DW:0]      s444_sync,
  input       [23:0]      s444_data,

  // 422 outputs

  output  reg [DW:0]      s422_sync,
  output  reg [15:0]      s422_data);

  localparam  DW = DELAY_DATA_WIDTH - 1;

  // internal registers

  reg             s444_de_d = 'd0;
  reg     [DW:0]  s444_sync_d = 'd0;
  reg     [23:0]  s444_data_d = 'd0;
  reg             s444_de_2d = 'd0;
  reg     [DW:0]  s444_sync_2d = 'd0;
  reg     [23:0]  s444_data_2d = 'd0;
  reg             s444_de_3d = 'd0;
  reg     [DW:0]  s444_sync_3d = 'd0;
  reg     [23:0]  s444_data_3d = 'd0;
  reg     [ 7:0]  cr = 'd0;
  reg     [ 7:0]  cb = 'd0;
  reg             cr_cb_sel = 'd0;

  // internal wires

  wire    [ 9:0]  cr_s;
  wire    [ 9:0]  cb_s;

  // fill the data pipe lines, hold the last data on edges 

  always @(posedge clk) begin
    s444_de_d <= s444_de;
    s444_sync_d <= s444_sync;
    if (s444_de == 1'b1) begin
      s444_data_d <= s444_data;
    end
    s444_de_2d <= s444_de_d;
    s444_sync_2d <= s444_sync_d;
    if (s444_de_d == 1'b1) begin
      s444_data_2d <= s444_data_d;
    end
    s444_de_3d <= s444_de_2d;
    s444_sync_3d <= s444_sync_2d;
    if (s444_de_2d == 1'b1) begin
      s444_data_3d <= s444_data_2d;
    end
  end

  // get the average 0.25*s(n-1) + 0.5*s(n) + 0.25*s(n+1)

  assign cr_s = {2'd0, s444_data_d[23:16]} +
                {2'd0, s444_data_3d[23:16]} +
                {1'd0, s444_data_2d[23:16], 1'd0};

  assign cb_s = {2'd0, s444_data_d[7:0]} +
                {2'd0, s444_data_3d[7:0]} +
                {1'd0, s444_data_2d[7:0], 1'd0};

  always @(posedge clk) begin
    cr <= cr_s[9:2];
    cb <= cb_s[9:2];
    if (s444_de_3d == 1'b1) begin
      cr_cb_sel <= ~cr_cb_sel;
    end else begin
      cr_cb_sel <= CR_CB_N;
    end
  end

  // 422 outputs

  always @(posedge clk) begin
    s422_sync <= s444_sync_3d;
    if (s444_de_3d == 1'b0) begin
      s422_data <= 'd0;
    end else if (cr_cb_sel == 1'b1) begin
      s422_data <= {cr, s444_data_3d[15:8]};
    end else begin
      s422_data <= {cb, s444_data_3d[15:8]};
    end
  end

endmodule

// ***************************************************************************
// ***************************************************************************
