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

module axi_ad9643 #(

  parameter ID = 0,
  parameter DEVICE_TYPE = 0,
  parameter ADC_DATAPATH_DISABLE = 0,
  parameter IO_DELAY_GROUP = "adc_if_delay_group") (

  // adc interface (clk, data, over-range)

  input                   adc_clk_in_p,
  input                   adc_clk_in_n,
  input       [13:0]      adc_data_in_p,
  input       [13:0]      adc_data_in_n,
  input                   adc_or_in_p,
  input                   adc_or_in_n,

  // delay interface

  input                   delay_clk,

  // dma interface

  output                  adc_clk,
  output                  adc_valid_0,
  output                  adc_enable_0,
  output      [15:0]      adc_data_0,
  output                  adc_valid_1,
  output                  adc_enable_1,
  output      [15:0]      adc_data_1,
  input                   adc_dovf,
  input                   adc_dunf,
  input       [31:0]      up_adc_gpio_in,
  output      [31:0]      up_adc_gpio_out,
  output                  adc_rst,

  // axi interface

  input                   s_axi_aclk,
  input                   s_axi_aresetn,
  input                   s_axi_awvalid,
  input       [31:0]      s_axi_awaddr,
  output                  s_axi_awready,
  input                   s_axi_wvalid,
  input       [31:0]      s_axi_wdata,
  input       [ 3:0]      s_axi_wstrb,
  output                  s_axi_wready,
  output                  s_axi_bvalid,
  output      [ 1:0]      s_axi_bresp,
  input                   s_axi_bready,
  input                   s_axi_arvalid,
  input       [31:0]      s_axi_araddr,
  output                  s_axi_arready,
  output                  s_axi_rvalid,
  output      [ 1:0]      s_axi_rresp,
  output      [31:0]      s_axi_rdata,
  input                   s_axi_rready,
  input       [ 2:0]      s_axi_awprot,
  input       [ 2:0]      s_axi_arprot);


  // internal registers

  reg             up_status_pn_err = 'd0;
  reg             up_status_pn_oos = 'd0;
  reg             up_status_or = 'd0;
  reg     [31:0]  up_rdata = 'd0;
  reg             up_rack = 'd0;
  reg             up_wack = 'd0;

  // internal clocks & resets

  wire            up_rstn;
  wire            up_clk;
  wire            delay_rst;

  // internal signals

  wire    [13:0]  adc_data_a_s;
  wire    [13:0]  adc_data_b_s;
  wire            adc_or_a_s;
  wire            adc_or_b_s;
  wire    [15:0]  adc_dcfilter_data_a_s;
  wire    [15:0]  adc_dcfilter_data_b_s;
  wire    [15:0]  adc_channel_data_a_s;
  wire    [15:0]  adc_channel_data_b_s;
  wire    [ 1:0]  up_status_pn_err_s;
  wire    [ 1:0]  up_status_pn_oos_s;
  wire    [ 1:0]  up_status_or_s;
  wire            adc_ddr_edgesel_s;
  wire            adc_pin_mode_s;
  wire            adc_status_s;
  wire    [14:0]  up_dld_s;
  wire    [74:0]  up_dwdata_s;
  wire    [74:0]  up_drdata_s;
  wire            delay_locked_s;
  wire    [31:0]  up_rdata_s[0:3];
  wire            up_rack_s[0:3];
  wire            up_wack_s[0:3];
  wire            up_wreq_s;
  wire    [13:0]  up_waddr_s;
  wire    [31:0]  up_wdata_s;
  wire            up_rreq_s;
  wire    [13:0]  up_raddr_s;

  // signal name changes

  assign up_clk = s_axi_aclk;
  assign up_rstn = s_axi_aresetn;

  // dma interface

  assign adc_valid_0 = 1'b1;
  assign adc_valid_1 = 1'b1;

  // processor read interface

  always @(negedge up_rstn or posedge up_clk) begin
    if (up_rstn == 0) begin
      up_status_pn_err <= 'd0;
      up_status_pn_oos <= 'd0;
      up_status_or <= 'd0;
      up_rdata <= 'd0;
      up_rack <= 'd0;
      up_wack <= 'd0;
    end else begin
      up_status_pn_err <= up_status_pn_err_s[0] | up_status_pn_err_s[1];
      up_status_pn_oos <= up_status_pn_oos_s[0] | up_status_pn_oos_s[1];
      up_status_or <= up_status_or_s[0] | up_status_or_s[1];
      up_rdata <= up_rdata_s[0] | up_rdata_s[1] | up_rdata_s[2] | up_rdata_s[3];
      up_rack <= up_rack_s[0] | up_rack_s[1] | up_rack_s[2] | up_rack_s[3];
      up_wack <= up_wack_s[0] | up_wack_s[1] | up_wack_s[2] | up_wack_s[3];
    end
  end

  // channel

  axi_ad9643_channel #(
    .Q_OR_I_N(0),
    .CHANNEL_ID(0),
    .DATAPATH_DISABLE (ADC_DATAPATH_DISABLE))
  i_channel_0 (
    .adc_clk (adc_clk),
    .adc_rst (adc_rst),
    .adc_data (adc_data_a_s),
    .adc_or (adc_or_a_s),
    .adc_dcfilter_data_out (adc_dcfilter_data_a_s),
    .adc_dcfilter_data_in (adc_dcfilter_data_b_s),
    .adc_iqcor_data (adc_data_0),
    .adc_enable (adc_enable_0),
    .up_adc_pn_err (up_status_pn_err_s[0]),
    .up_adc_pn_oos (up_status_pn_oos_s[0]),
    .up_adc_or (up_status_or_s[0]),
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack_s[0]),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s[0]),
    .up_rack (up_rack_s[0]));

  // channel

  axi_ad9643_channel #(
    .Q_OR_I_N(1),
    .CHANNEL_ID(1),
    .DATAPATH_DISABLE (ADC_DATAPATH_DISABLE))
  i_channel_1 (
    .adc_clk (adc_clk),
    .adc_rst (adc_rst),
    .adc_data (adc_data_b_s),
    .adc_or (adc_or_b_s),
    .adc_dcfilter_data_out (adc_dcfilter_data_b_s),
    .adc_dcfilter_data_in (adc_dcfilter_data_a_s),
    .adc_iqcor_data (adc_data_1),
    .adc_enable (adc_enable_1),
    .up_adc_pn_err (up_status_pn_err_s[1]),
    .up_adc_pn_oos (up_status_pn_oos_s[1]),
    .up_adc_or (up_status_or_s[1]),
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack_s[1]),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s[1]),
    .up_rack (up_rack_s[1]));

  // main (device interface)

  axi_ad9643_if #(
    .DEVICE_TYPE (DEVICE_TYPE),
    .IO_DELAY_GROUP (IO_DELAY_GROUP))
  i_if (
    .adc_clk_in_p (adc_clk_in_p),
    .adc_clk_in_n (adc_clk_in_n),
    .adc_data_in_p (adc_data_in_p),
    .adc_data_in_n (adc_data_in_n),
    .adc_or_in_p (adc_or_in_p),
    .adc_or_in_n (adc_or_in_n),
    .adc_clk (adc_clk),
    .adc_data_a (adc_data_a_s),
    .adc_data_b (adc_data_b_s),
    .adc_or_a (adc_or_a_s),
    .adc_or_b (adc_or_b_s),
    .adc_status (adc_status_s),
    .adc_ddr_edgesel (adc_ddr_edgesel_s),
    .adc_pin_mode (adc_pin_mode_s),
    .up_clk (up_clk),
    .up_dld (up_dld_s),
    .up_dwdata (up_dwdata_s),
    .up_drdata (up_drdata_s),
    .delay_clk (delay_clk),
    .delay_rst (delay_rst),
    .delay_locked (delay_locked_s));

  // common processor control

  up_adc_common #(.ID(ID)) i_up_adc_common (
    .mmcm_rst (),
    .adc_clk (adc_clk),
    .adc_rst (adc_rst),
    .adc_r1_mode (),
    .adc_ddr_edgesel (adc_ddr_edgesel_s),
    .adc_pin_mode (adc_pin_mode_s),
    .adc_status (adc_status_s),
    .adc_sync_status (1'd0),
    .adc_status_ovf (adc_dovf),
    .adc_status_unf (adc_dunf),
    .adc_clk_ratio (32'd1),
    .adc_start_code (),
    .adc_sref_sync (),
    .adc_sync (),
    .up_adc_ce (),
    .up_status_pn_err (up_status_pn_err),
    .up_status_pn_oos (up_status_pn_oos),
    .up_status_or (up_status_or),
    .up_drp_sel (),
    .up_drp_wr (),
    .up_drp_addr (),
    .up_drp_wdata (),
    .up_drp_rdata (32'd0),
    .up_drp_ready (1'd0),
    .up_drp_locked (1'd1),
    .up_usr_chanmax_out (),
    .up_usr_chanmax_in (8'd0),
    .up_adc_gpio_in (up_adc_gpio_in),
    .up_adc_gpio_out (up_adc_gpio_out),
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack_s[2]),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s[2]),
    .up_rack (up_rack_s[2]));

  // adc delay control

  up_delay_cntrl #(.DATA_WIDTH(15), .BASE_ADDRESS(6'h02)) i_delay_cntrl (
    .delay_clk (delay_clk),
    .delay_rst (delay_rst),
    .delay_locked (delay_locked_s),
    .up_dld (up_dld_s),
    .up_dwdata (up_dwdata_s),
    .up_drdata (up_drdata_s),
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack_s[3]),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s[3]),
    .up_rack (up_rack_s[3]));

  // up bus interface

  up_axi i_up_axi (
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_axi_awvalid (s_axi_awvalid),
    .up_axi_awaddr (s_axi_awaddr),
    .up_axi_awready (s_axi_awready),
    .up_axi_wvalid (s_axi_wvalid),
    .up_axi_wdata (s_axi_wdata),
    .up_axi_wstrb (s_axi_wstrb),
    .up_axi_wready (s_axi_wready),
    .up_axi_bvalid (s_axi_bvalid),
    .up_axi_bresp (s_axi_bresp),
    .up_axi_bready (s_axi_bready),
    .up_axi_arvalid (s_axi_arvalid),
    .up_axi_araddr (s_axi_araddr),
    .up_axi_arready (s_axi_arready),
    .up_axi_rvalid (s_axi_rvalid),
    .up_axi_rresp (s_axi_rresp),
    .up_axi_rdata (s_axi_rdata),
    .up_axi_rready (s_axi_rready),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata),
    .up_rack (up_rack));

endmodule

// ***************************************************************************
// ***************************************************************************

