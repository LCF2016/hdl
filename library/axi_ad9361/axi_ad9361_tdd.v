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

`timescale 1ns/1ps

module axi_ad9361_tdd (

  // clock

  input                   clk,
  input                   rst,

  // control signals from the tdd control

  output                  tdd_rx_vco_en,
  output                  tdd_tx_vco_en,
  output                  tdd_rx_rf_en,
  output                  tdd_tx_rf_en,

  // status signal

  output                  tdd_enabled,
  input       [ 7:0]      tdd_status,

  // sync signal

  input                   tdd_sync,
  output  reg             tdd_sync_cntr,

  // tx/rx data flow control

  output  reg             tdd_tx_valid,
  output  reg             tdd_rx_valid,

  // bus interface

  input                   up_rstn,
  input                   up_clk,
  input                   up_wreq,
  input       [13:0]      up_waddr,
  input       [31:0]      up_wdata,
  output                  up_wack,
  input                   up_rreq,
  input       [13:0]      up_raddr,
  output      [31:0]      up_rdata,
  output                  up_rack);

  // internal signals

  wire              tdd_enable_s;
  wire              tdd_secondary_s;
  wire    [ 7:0]    tdd_burst_count_s;
  wire              tdd_rx_only_s;
  wire              tdd_tx_only_s;
  wire              tdd_gated_rx_dmapath_s;
  wire              tdd_gated_tx_dmapath_s;
  wire    [23:0]    tdd_counter_init_s;
  wire    [23:0]    tdd_frame_length_s;
  wire              tdd_terminal_type_s;
  wire              tdd_sync_enable_s;
  wire    [23:0]    tdd_vco_rx_on_1_s;
  wire    [23:0]    tdd_vco_rx_off_1_s;
  wire    [23:0]    tdd_vco_tx_on_1_s;
  wire    [23:0]    tdd_vco_tx_off_1_s;
  wire    [23:0]    tdd_rx_on_1_s;
  wire    [23:0]    tdd_rx_off_1_s;
  wire    [23:0]    tdd_rx_dp_on_1_s;
  wire    [23:0]    tdd_rx_dp_off_1_s;
  wire    [23:0]    tdd_tx_on_1_s;
  wire    [23:0]    tdd_tx_off_1_s;
  wire    [23:0]    tdd_tx_dp_on_1_s;
  wire    [23:0]    tdd_tx_dp_off_1_s;
  wire    [23:0]    tdd_vco_rx_on_2_s;
  wire    [23:0]    tdd_vco_rx_off_2_s;
  wire    [23:0]    tdd_vco_tx_on_2_s;
  wire    [23:0]    tdd_vco_tx_off_2_s;
  wire    [23:0]    tdd_rx_on_2_s;
  wire    [23:0]    tdd_rx_off_2_s;
  wire    [23:0]    tdd_rx_dp_on_2_s;
  wire    [23:0]    tdd_rx_dp_off_2_s;
  wire    [23:0]    tdd_tx_on_2_s;
  wire    [23:0]    tdd_tx_off_2_s;
  wire    [23:0]    tdd_tx_dp_on_2_s;
  wire    [23:0]    tdd_tx_dp_off_2_s;

  wire    [23:0]    tdd_counter_status;

  wire              tdd_rx_dp_en_s;
  wire              tdd_tx_dp_en_s;

  assign  tdd_enabled = tdd_enable_s;

  // syncronization control signal

  always @(posedge clk) begin
    if (tdd_enable_s == 1'b1) begin
      tdd_sync_cntr <= ~tdd_terminal_type_s;
    end else begin
      tdd_sync_cntr <= 1'b0;
    end
  end

  // tx/rx data flow control

  always @(posedge clk) begin
    if((tdd_enable_s == 1) && (tdd_gated_tx_dmapath_s == 1)) begin
      tdd_tx_valid <= tdd_tx_dp_en_s;
    end else begin
      tdd_tx_valid <= 1'b1;
    end
  end

  always @(posedge clk) begin
    if((tdd_enable_s == 1) && (tdd_gated_tx_dmapath_s == 1)) begin
      tdd_rx_valid <= tdd_rx_dp_en_s;
    end else begin
      tdd_rx_valid <= 1'b1;
    end
  end

  // instantiations

  up_tdd_cntrl i_up_tdd_cntrl(
    .clk(clk),
    .rst(rst),
    .tdd_enable(tdd_enable_s),
    .tdd_secondary(tdd_secondary_s),
    .tdd_burst_count(tdd_burst_count_s),
    .tdd_tx_only(tdd_tx_only_s),
    .tdd_rx_only(tdd_rx_only_s),
    .tdd_gated_rx_dmapath(tdd_gated_rx_dmapath_s),
    .tdd_gated_tx_dmapath(tdd_gated_tx_dmapath_s),
    .tdd_counter_init(tdd_counter_init_s),
    .tdd_frame_length(tdd_frame_length_s),
    .tdd_terminal_type(tdd_terminal_type_s),
    .tdd_vco_rx_on_1(tdd_vco_rx_on_1_s),
    .tdd_vco_rx_off_1(tdd_vco_rx_off_1_s),
    .tdd_vco_tx_on_1(tdd_vco_tx_on_1_s),
    .tdd_vco_tx_off_1(tdd_vco_tx_off_1_s),
    .tdd_rx_on_1(tdd_rx_on_1_s),
    .tdd_rx_off_1(tdd_rx_off_1_s),
    .tdd_rx_dp_on_1(tdd_rx_dp_on_1_s),
    .tdd_rx_dp_off_1(tdd_rx_dp_off_1_s),
    .tdd_tx_on_1(tdd_tx_on_1_s),
    .tdd_tx_off_1(tdd_tx_off_1_s),
    .tdd_tx_dp_on_1(tdd_tx_dp_on_1_s),
    .tdd_tx_dp_off_1(tdd_tx_dp_off_1_s),
    .tdd_vco_rx_on_2(tdd_vco_rx_on_2_s),
    .tdd_vco_rx_off_2(tdd_vco_rx_off_2_s),
    .tdd_vco_tx_on_2(tdd_vco_tx_on_2_s),
    .tdd_vco_tx_off_2(tdd_vco_tx_off_2_s),
    .tdd_rx_on_2(tdd_rx_on_2_s),
    .tdd_rx_off_2(tdd_rx_off_2_s),
    .tdd_rx_dp_on_2(tdd_rx_dp_on_2_s),
    .tdd_rx_dp_off_2(tdd_rx_dp_off_2_s),
    .tdd_tx_on_2(tdd_tx_on_2_s),
    .tdd_tx_off_2(tdd_tx_off_2_s),
    .tdd_tx_dp_on_2(tdd_tx_dp_on_2_s),
    .tdd_tx_dp_off_2(tdd_tx_dp_off_2_s),
    .tdd_status(tdd_status),
    .up_rstn(up_rstn),
    .up_clk(up_clk),
    .up_wreq(up_wreq),
    .up_waddr(up_waddr),
    .up_wdata(up_wdata),
    .up_wack(up_wack),
    .up_rreq(up_rreq),
    .up_raddr(up_raddr),
    .up_rdata(up_rdata),
    .up_rack(up_rack));

  // the TX_DATA_PATH_DELAY and CONTROL_PATH_DELAY are specificly defined
  // for the axi_ad9361 core

  ad_tdd_control #(
    .TX_DATA_PATH_DELAY(),
    .CONTROL_PATH_DELAY())
  i_tdd_control(
    .clk(clk),
    .rst(rst),
    .tdd_enable(tdd_enable_s),
    .tdd_secondary(tdd_secondary_s),
    .tdd_counter_init(tdd_counter_init_s),
    .tdd_frame_length(tdd_frame_length_s),
    .tdd_burst_count(tdd_burst_count_s),
    .tdd_rx_only(tdd_rx_only_s),
    .tdd_tx_only(tdd_tx_only_s),
    .tdd_sync (tdd_sync),
    .tdd_vco_rx_on_1(tdd_vco_rx_on_1_s),
    .tdd_vco_rx_off_1(tdd_vco_rx_off_1_s),
    .tdd_vco_tx_on_1(tdd_vco_tx_on_1_s),
    .tdd_vco_tx_off_1(tdd_vco_tx_off_1_s),
    .tdd_rx_on_1(tdd_rx_on_1_s),
    .tdd_rx_off_1(tdd_rx_off_1_s),
    .tdd_rx_dp_on_1(tdd_rx_dp_on_1_s),
    .tdd_rx_dp_off_1(tdd_rx_dp_off_1_s),
    .tdd_tx_on_1(tdd_tx_on_1_s),
    .tdd_tx_off_1(tdd_tx_off_1_s),
    .tdd_tx_dp_on_1(tdd_tx_dp_on_1_s),
    .tdd_tx_dp_off_1(tdd_tx_dp_off_1_s),
    .tdd_vco_rx_on_2(tdd_vco_rx_on_2_s),
    .tdd_vco_rx_off_2(tdd_vco_rx_off_2_s),
    .tdd_vco_tx_on_2(tdd_vco_tx_on_2_s),
    .tdd_vco_tx_off_2(tdd_vco_tx_off_2_s),
    .tdd_rx_on_2(tdd_rx_on_2_s),
    .tdd_rx_off_2(tdd_rx_off_2_s),
    .tdd_rx_dp_on_2(tdd_rx_dp_on_2_s),
    .tdd_rx_dp_off_2(tdd_rx_dp_off_2_s),
    .tdd_tx_on_2(tdd_tx_on_2_s),
    .tdd_tx_off_2(tdd_tx_off_2_s),
    .tdd_tx_dp_on_2(tdd_tx_dp_on_2_s),
    .tdd_tx_dp_off_2(tdd_tx_dp_off_2_s),
    .tdd_rx_dp_en(tdd_rx_dp_en_s),
    .tdd_tx_dp_en(tdd_tx_dp_en_s),
    .tdd_rx_vco_en(tdd_rx_vco_en),
    .tdd_tx_vco_en(tdd_tx_vco_en),
    .tdd_rx_rf_en(tdd_rx_rf_en),
    .tdd_tx_rf_en(tdd_tx_rf_en),
    .tdd_counter_status(tdd_counter_status));

endmodule
