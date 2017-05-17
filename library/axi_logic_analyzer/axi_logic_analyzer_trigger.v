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

module axi_logic_analyzer_trigger (

  input                 clk,
  input                 reset,

  input       [15:0]    data,
  input                 data_valid,
  input       [ 1:0]    trigger,

  input       [17:0]    edge_detect_enable,
  input       [17:0]    rise_edge_enable,
  input       [17:0]    fall_edge_enable,
  input       [17:0]    low_level_enable,
  input       [17:0]    high_level_enable,

  input                 trigger_logic,

  output  reg           trigger_out);

  reg     [ 17:0]   data_m1 = 'd0;
  reg     [ 17:0]   low_level = 'd0;
  reg     [ 17:0]   high_level = 'd0;
  reg     [ 17:0]   edge_detect = 'd0;
  reg     [ 17:0]   rise_edge = 'd0;
  reg     [ 17:0]   fall_edge = 'd0;
  reg     [ 31:0]   delay_count = 'd0;

  reg              trigger_active;

  always @(posedge clk) begin
    trigger_out <= trigger_active;
  end

  // trigger logic:
  // 0 OR
  // 1 AND

  always @(*) begin
    case (trigger_logic)
      0: trigger_active = | ((edge_detect & edge_detect_enable) |
                          (rise_edge & rise_edge_enable) |
                          (fall_edge & fall_edge_enable) |
                          (low_level & low_level_enable) |
                          (high_level & high_level_enable));
      1: trigger_active = | (((edge_detect & edge_detect_enable) | !(|edge_detect_enable)) &
                          ((rise_edge & rise_edge_enable) | !(|rise_edge_enable)) &
                          ((fall_edge & fall_edge_enable) | !(|fall_edge_enable)) &
                          ((low_level & low_level_enable) | !(|low_level_enable)) &
                          ((high_level & high_level_enable) | !(|high_level_enable)));
      default: trigger_active = 1'b1;
    endcase
  end

  // internal signals

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      data_m1 <= 'd0;
      edge_detect <= 'd0;
      rise_edge <= 'd0;
      fall_edge <= 'd0;
      low_level <= 'd0;
      high_level <= 'd0;
    end else begin
      if (data_valid == 1'b1) begin
        data_m1 <= {trigger, data} ;
        edge_detect <= data_m1 ^ {trigger, data};
        rise_edge <= (data_m1 ^ {trigger, data} ) & {trigger, data};
        fall_edge <= (data_m1 ^ {trigger, data}) & ~{trigger, data};
        low_level <= ~{trigger, data};
        high_level <= {trigger, data};
      end
    end
  end


endmodule

// ***************************************************************************
// ***************************************************************************
