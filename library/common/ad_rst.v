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

module ad_rst (

  // clock reset

  input                   preset,
  input                   clk,
  output  reg             rst);

  // internal registers

  reg             ad_rst_sync_m1 = 'd0 /* synthesis preserve */;
  reg             ad_rst_sync = 'd0 /* synthesis preserve */;

  // simple reset gen

  always @(posedge clk) begin
    ad_rst_sync_m1 <= preset;
    ad_rst_sync <= ad_rst_sync_m1;
    rst <= ad_rst_sync;
  end

endmodule

// ***************************************************************************
// ***************************************************************************
