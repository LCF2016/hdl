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

module system_top (

  inout   [14:0]  ddr_addr,
  inout   [ 2:0]  ddr_ba,
  inout           ddr_cas_n,
  inout           ddr_ck_n,
  inout           ddr_ck_p,
  inout           ddr_cke,
  inout           ddr_cs_n,
  inout   [ 3:0]  ddr_dm,
  inout   [31:0]  ddr_dq,
  inout   [ 3:0]  ddr_dqs_n,
  inout   [ 3:0]  ddr_dqs_p,
  inout           ddr_odt,
  inout           ddr_ras_n,
  inout           ddr_reset_n,
  inout           ddr_we_n,

  inout           fixed_io_ddr_vrn,
  inout           fixed_io_ddr_vrp,
  inout   [53:0]  fixed_io_mio,
  inout           fixed_io_ps_clk,
  inout           fixed_io_ps_porb,
  inout           fixed_io_ps_srstb,

  inout   [31:0]  gpio_bd,

  output          hdmi_out_clk,
  output          hdmi_vsync,
  output          hdmi_hsync,
  output          hdmi_data_e,
  output  [15:0]  hdmi_data,

  output          i2s_mclk,
  output          i2s_bclk,
  output          i2s_lrclk,
  output          i2s_sdata_out,
  input           i2s_sdata_in,

  output          spdif,

  inout   [ 1:0]  iic_mux_scl,
  inout   [ 1:0]  iic_mux_sda,

  input           otg_vbusoc,

  inout   [15:0]  data_bd,
  inout   [ 1:0]  trigger_bd,

  input           rx_clk,
  input           rxiq,
  input   [11:0]  rxd,
  input           tx_clk,
  output          txiq,
  output  [11:0]  txd,

  output          ad9963_resetn,
  output          ad9963_csn,
  output          adf4360_cs,
  output          spi_clk,
  inout           spi_sdio,

  output          en_power_analog,

  inout           iic_scl,
  inout           iic_sda);

  // internal signals

  wire    [63:0]  gpio_i;
  wire    [63:0]  gpio_o;
  wire    [63:0]  gpio_t;
  wire    [ 1:0]  iic_mux_scl_i_s;
  wire    [ 1:0]  iic_mux_scl_o_s;
  wire            iic_mux_scl_t_s;
  wire    [ 1:0]  iic_mux_sda_i_s;
  wire    [ 1:0]  iic_mux_sda_o_s;
  wire            iic_mux_sda_t_s;

  wire    [15:0]  data_i;
  wire    [15:0]  data_o;
  wire    [15:0]  data_t;

  wire    [ 1:0]  trigger_i;
  wire    [ 1:0]  trigger_o;
  wire    [ 1:0]  trigger_t;

  wire    [ 1:0]  spi0_csn;
  wire            spi0_clk;
  wire            spi0_mosi;
  wire            spi0_miso;

  assign ad9963_resetn = gpio_o[32];
  assign en_power_analog = gpio_o[33];

  assign ad9963_csn = spi0_csn[0];
  assign adf4360_cs = spi0_csn[1];
  assign spi_clk = spi0_clk;
  assign spi_mosi = spi0_mosi;
  assign spi0_miso = spi_miso;

  assign gpio_i[63:32] = gpio_o[63:32];

  // instantiations

  ad_iobuf #(
    .DATA_WIDTH(32)
  ) i_iobuf (
    .dio_t(gpio_t[31:0]),
    .dio_i(gpio_o[31:0]),
    .dio_o(gpio_i[31:0]),
    .dio_p(gpio_bd));

  ad_iobuf #(
    .DATA_WIDTH(2)
  ) i_iic_mux_scl (
    .dio_t({iic_mux_scl_t_s, iic_mux_scl_t_s}),
    .dio_i(iic_mux_scl_o_s),
    .dio_o(iic_mux_scl_i_s),
    .dio_p(iic_mux_scl));

  ad_iobuf #(
    .DATA_WIDTH(2)
  ) i_iic_mux_sda (
    .dio_t({iic_mux_sda_t_s, iic_mux_sda_t_s}),
    .dio_i(iic_mux_sda_o_s),
    .dio_o(iic_mux_sda_i_s),
    .dio_p(iic_mux_sda));

  ad_iobuf #(
    .DATA_WIDTH(16)
  ) i_data_bd (
    .dio_t(data_t[15:0]),
    .dio_i(data_o[15:0]),
    .dio_o(data_i[15:0]),
    .dio_p(data_bd));

  ad_iobuf #(
    .DATA_WIDTH(2)
  ) i_trigger_bd (
    .dio_t(trigger_t[1:0]),
    .dio_i(trigger_o[1:0]),
    .dio_o(trigger_i[1:0]),
    .dio_p(trigger_bd));

  m2k_spi i_m2k_spi (
    .ad9963_csn (ad9963_csn),
    .adf4360_cs (adf4360_cs),
    .spi_clk (spi_clk),
    .spi_mosi (spi_mosi),
    .spi_miso (spi_miso),
    .spi_sdio (spi_sdio));

  system_wrapper i_system_wrapper (
    .ddr_addr (ddr_addr),
    .ddr_ba (ddr_ba),
    .ddr_cas_n (ddr_cas_n),
    .ddr_ck_n (ddr_ck_n),
    .ddr_ck_p (ddr_ck_p),
    .ddr_cke (ddr_cke),
    .ddr_cs_n (ddr_cs_n),
    .ddr_dm (ddr_dm),
    .ddr_dq (ddr_dq),
    .ddr_dqs_n (ddr_dqs_n),
    .ddr_dqs_p (ddr_dqs_p),
    .ddr_odt (ddr_odt),
    .ddr_ras_n (ddr_ras_n),
    .ddr_reset_n (ddr_reset_n),
    .ddr_we_n (ddr_we_n),
    .fixed_io_ddr_vrn (fixed_io_ddr_vrn),
    .fixed_io_ddr_vrp (fixed_io_ddr_vrp),
    .fixed_io_mio (fixed_io_mio),
    .fixed_io_ps_clk (fixed_io_ps_clk),
    .fixed_io_ps_porb (fixed_io_ps_porb),
    .fixed_io_ps_srstb (fixed_io_ps_srstb),
    .gpio_i (gpio_i),
    .gpio_o (gpio_o),
    .gpio_t (gpio_t),
    .hdmi_data (hdmi_data),
    .hdmi_data_e (hdmi_data_e),
    .hdmi_hsync (hdmi_hsync),
    .hdmi_out_clk (hdmi_out_clk),
    .hdmi_vsync (hdmi_vsync),
    .i2s_bclk (i2s_bclk),
    .i2s_lrclk (i2s_lrclk),
    .i2s_mclk (i2s_mclk),
    .i2s_sdata_in (i2s_sdata_in),
    .i2s_sdata_out (i2s_sdata_out),
    .iic_fmc_scl_io (iic_scl),
    .iic_fmc_sda_io (iic_sda),
    .iic_mux_scl_i (iic_mux_scl_i_s),
    .iic_mux_scl_o (iic_mux_scl_o_s),
    .iic_mux_scl_t (iic_mux_scl_t_s),
    .iic_mux_sda_i (iic_mux_sda_i_s),
    .iic_mux_sda_o (iic_mux_sda_o_s),
    .iic_mux_sda_t (iic_mux_sda_t_s),
    .data_i(data_i),
    .data_o(data_o),
    .data_t(data_t),
    .trigger_i(trigger_i),
    .trigger_o(trigger_o),
    .trigger_t(trigger_t),
    .rx_clk(rx_clk),
    .rxiq(rxiq),
    .rxd(rxd),
    .tx_clk(tx_clk),
    .txiq(txiq),
    .txd(txd),
    .ps_intr_00 (1'b0),
    .ps_intr_01 (1'b0),
    .ps_intr_02 (1'b0),
    .ps_intr_03 (1'b0),
    .ps_intr_04 (1'b0),
    .ps_intr_05 (1'b0),
    .ps_intr_06 (1'b0),
    .ps_intr_07 (1'b0),
    .spi0_clk_i (spi0_clk),
    .spi0_clk_o (spi0_clk),
    .spi0_csn_0_o (spi0_csn[0]),
    .spi0_csn_1_o (spi0_csn[1]),
    .spi0_csn_i (1'b1),
    .spi0_sdi_i (spi0_miso),
    .spi0_sdo_i (spi0_mosi),
    .spi0_sdo_o (spi0_mosi),
    .spi1_clk_i (1'b0),
    .spi1_clk_o (),
    .spi1_csn_0_o (),
    .spi1_csn_1_o (),
    .spi1_csn_i (1'b1),
    .spi1_sdi_i (1'b0),
    .spi1_sdo_i (1'b0),
    .spi1_sdo_o (),
    .otg_vbusoc (otg_vbusoc),
    .spdif (spdif));

endmodule

// ***************************************************************************
// ***************************************************************************
