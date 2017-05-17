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

module __ad_cmos_out__ #(

  parameter   DEVICE_TYPE = 0,
  parameter   IODELAY_ENABLE = 0,
  parameter   IODELAY_CTRL = 0,
  parameter   IODELAY_GROUP = "dev_if_delay_group") (

  // data interface

  input               tx_clk,
  input               tx_data_p,
  input               tx_data_n,
  output              tx_data_out,

  // delay-data interface

  input               up_clk,
  input               up_dld,
  input       [ 4:0]  up_dwdata,
  output      [ 4:0]  up_drdata,

  // delay-cntrl interface

  input               delay_clk,
  input               delay_rst,
  output              delay_locked);

  // local parameter

  localparam ARRIA10 = 0;
  localparam CYCLONE5 = 1;

  // defaults

  assign up_drdata = 5'd0;
  assign delay_locked = 1'b1;

  // instantiations

  generate
  if (DEVICE_TYPE == ARRIA10) begin
  __ad_cmos_out_1__ i_tx_data_oddr (
    .clk_export (tx_clk),
    .din_export ({tx_data_p, tx_data_n}),
    .pad_out_export (tx_data_out));
  end
  endgenerate

  generate
  if (DEVICE_TYPE == CYCLONE5) begin
  ad_cmos_out_core_c5 i_tx_data_oddr (
    .clk (tx_clk),
    .din ({tx_data_p, tx_data_n}),
    .pad_out (tx_data_out));
  end
  endgenerate

endmodule

// ***************************************************************************
// ***************************************************************************
