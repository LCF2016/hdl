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

module util_fir_int (
  input               aclk,
  input               s_axis_data_tvalid,
  output              s_axis_data_tready,
  input       [31:0]  s_axis_data_tdata,
  output      [15:0]  channel_0,
  output      [15:0]  channel_1,
  output              m_axis_data_tvalid,
  input               interpolate,
  input               dac_read);

  wire [31:0] m_axis_data_tdata_s;
  wire        s_axis_data_tvalid_s;

  reg         s_axis_data_tready_r;
  reg         s_axis_data_tvalid_r;
  reg   [2:0] ready_counter;

  always @(posedge aclk) begin
    ready_counter <= ready_counter + 1;
    s_axis_data_tready_r <= s_axis_data_tvalid_r;
    if (ready_counter == 0) begin
      s_axis_data_tvalid_r <= 1'b1;
    end else begin
      s_axis_data_tvalid_r <= 1'b1;
    end
  end

  assign {channel_1, channel_0} = (interpolate == 1'b1) ? {m_axis_data_tdata_s[30:16],1'b0,m_axis_data_tdata_s[14:0], 1'b0} : s_axis_data_tdata;
  assign s_axis_data_tready = (interpolate == 1'b1) ? s_axis_data_tready_r : dac_read;
  assign s_axis_data_tvalid_s = (interpolate == 1'b1) ? s_axis_data_tvalid_r : s_axis_data_tvalid;

  fir_interp interpolator (
    .aclk(aclk),
    .s_axis_data_tvalid(s_axis_data_tvalid_s),
    .s_axis_data_tready(),
    .s_axis_data_tdata(s_axis_data_tdata),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tdata(m_axis_data_tdata_s)
  );

endmodule  // util_fir_int

