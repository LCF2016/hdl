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

  inout           iic_scl,
  inout           iic_sda,

  output          i2s_mclk,
  output          i2s_bclk,
  output          i2s_lrclk,
  output          i2s_sdata_out,
  input           i2s_sdata_in,

  output          imu_csn,
  output          imu_clk,
  output          imu_mosi,
  input           imu_miso,
  input           imu_ready,
  output          imu_rstn,
  inout           imu_sync,

  output          oled_csn,
  output          oled_clk,
  output          oled_mosi,
  output          oled_rst,
  output          oled_dc,

  output          switch_led_r,
  output          switch_led_g,
  output          switch_led_b,

  output          gps_reset,
  output          gps_force_on,
  output          gps_standby,
  input           gps_pps,

  input   [ 2:0]  pss_valid_n,
  inout   [ 2:0]  adp5061_io,

  inout           tsw_rot_com_a,
  inout           tsw_dir_com_b,
  inout           tsw_rot_s1,
  inout           tsw_rot_a,
  inout           tsw_rot_b,
  inout           tsw_rot_misc,
  inout           tsw_dir_s2,
  inout           tsw_dir_s3,
  inout           tsw_dir_s4,
  inout           tsw_dir_s5,

  inout           otg_ctrl,
  inout           adp1614_en,
  inout           ltc2955_kill_n,
  inout           ltc2955_int_n,
  inout           mic_present_n,
  inout           ts3a227_int_n,

  input           rx_clk_in_p,
  input           rx_clk_in_n,
  input           rx_frame_in_p,
  input           rx_frame_in_n,
  input   [ 5:0]  rx_data_in_p,
  input   [ 5:0]  rx_data_in_n,
  output          tx_clk_out_p,
  output          tx_clk_out_n,
  output          tx_frame_out_p,
  output          tx_frame_out_n,
  output  [ 5:0]  tx_data_out_p,
  output  [ 5:0]  tx_data_out_n,

  output          enable,
  output          txnrx,
  input           clkout_in,

  inout           gpio_rf0,
  inout           gpio_rf1,
  inout           gpio_rf2,
  inout           gpio_rf3,
  inout           gpio_rf4,
  inout           gpio_rfpwr_enable,
  inout           gpio_clksel,
  inout           gpio_resetb,
  inout           gpio_sync,
  inout           gpio_en_agc,
  inout   [ 3:0]  gpio_ctl,
  inout   [ 7:0]  gpio_status,

  output          spi_csn,
  output          spi_clk,
  output          spi_mosi,
  input           spi_miso);

  // internal signals

  wire    [63:0]  gpio_i;
  wire    [63:0]  gpio_o;
  wire    [63:0]  gpio_t;

  // assignments

  assign oled_clk = spi_clk;
  assign oled_mosi = spi_mosi;

  // gpio[31:20] controls misc stuff (keep as io)

  assign gpio_i[31:29] = gpio_o[31:29];
  assign gpio_i[28:28] = imu_ready;
  assign gpio_i[27:26] = gpio_o[27:26];

  ad_iobuf #(.DATA_WIDTH(6)) i_iobuf_misc (
    .dio_t (gpio_t[25:20]),
    .dio_i (gpio_o[25:20]),
    .dio_o (gpio_i[25:20]),
    .dio_p ({ adp1614_en,
              otg_ctrl,
              ltc2955_kill_n,
              ltc2955_int_n,
              ts3a227_int_n,
              mic_present_n}));

  // gpio[19:16] controls adp5061 (keep as io)

  assign gpio_i[19] = gpio_o[19];

  ad_iobuf #(.DATA_WIDTH(3)) i_iobuf_adp5061 (
    .dio_t (gpio_t[18:16]),
    .dio_i (gpio_o[18:16]),
    .dio_o (gpio_i[18:16]),
    .dio_p (adp5061_io));

  // gpio[15:12] reads power source select valids

  assign gpio_i[15:12] = {gpio_o[15], pss_valid_n};

  // gpio[11:8] controls the imu/oled reset & such.

  assign oled_dc = gpio_o[11];
  assign oled_rst = gpio_o[10];
  assign imu_rstn = gpio_o[9];
  assign gpio_i[11:9] = gpio_o[11:9];

  ad_iobuf #(.DATA_WIDTH(1)) i_iobuf_imu_sync (
    .dio_t (gpio_t[8]),
    .dio_i (gpio_o[8]),
    .dio_o (gpio_i[8]),
    .dio_p (imu_sync));

  // gpio[7:4] controls the gps

  assign gps_reset = gpio_o[6];
  assign gps_force_on = gpio_o[5];
  assign gps_standby = gpio_o[4];
  assign gpio_i[7:4] = {gps_pps, gpio_o[6:4]};

  // gpio[3:0] controls the power switch led colors

  assign switch_led_r = gpio_o[2];
  assign switch_led_g = gpio_o[1];
  assign switch_led_b = gpio_o[0];
  assign gpio_i[3:0] = gpio_o[3:0];

  // ad9361 gpio - tact-scroll-wheel
 
  ad_iobuf #(.DATA_WIDTH(10)) i_iobuf_tsw (
    .dio_t ({gpio_t[63:62], gpio_t[60:57], gpio_t[50:47]}),
    .dio_i ({gpio_o[63:62], gpio_o[60:57], gpio_o[50:47]}),
    .dio_o ({gpio_i[63:62], gpio_i[60:57], gpio_i[50:47]}),
    .dio_p ({ tsw_rot_com_a,      // 63
              tsw_dir_com_b,      // 62
              tsw_rot_s1,         // 60
              tsw_rot_a,          // 59
              tsw_rot_b,          // 58
              tsw_rot_misc,       // 57
              tsw_dir_s2,         // 50
              tsw_dir_s3,         // 49
              tsw_dir_s4,         // 48
              tsw_dir_s5}));      // 47

  // ad9361 gpio - 63-32

  ad_iobuf #(.DATA_WIDTH(22)) i_iobuf (
    .dio_t ({gpio_t[61:61], gpio_t[56:51], gpio_t[46:32]}),
    .dio_i ({gpio_o[61:61], gpio_o[56:51], gpio_o[46:32]}),
    .dio_o ({gpio_i[61:61], gpio_i[56:51], gpio_i[46:32]}),
    .dio_p ({ gpio_rf4,           // 61:61
              gpio_rf0,           // 56:56
              gpio_rf1,           // 55:55
              gpio_rf2,           // 54:54
              gpio_rf3,           // 53:53
              gpio_rfpwr_enable,  // 52:52
              gpio_clksel,        // 51:51
              gpio_resetb,        // 46:46
              gpio_sync,          // 45:45
              gpio_en_agc,        // 44:44
              gpio_ctl,           // 43:40
              gpio_status}));     // 39:32

  // instantiations

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
    .enable (enable),
    .fixed_io_ddr_vrn (fixed_io_ddr_vrn),
    .fixed_io_ddr_vrp (fixed_io_ddr_vrp),
    .fixed_io_mio (fixed_io_mio),
    .fixed_io_ps_clk (fixed_io_ps_clk),
    .fixed_io_ps_porb (fixed_io_ps_porb),
    .fixed_io_ps_srstb (fixed_io_ps_srstb),
    .gpio_i (gpio_i),
    .gpio_o (gpio_o),
    .gpio_t (gpio_t),
    .i2s_bclk (i2s_bclk),
    .i2s_lrclk (i2s_lrclk),
    .i2s_mclk (i2s_mclk),
    .i2s_sdata_in (i2s_sdata_in),
    .i2s_sdata_out (i2s_sdata_out),
    .iic_main_scl_io (iic_scl),
    .iic_main_sda_io (iic_sda),
    .otg_vbusoc (1'b0),
    .ps_intr_00 (1'b0),
    .ps_intr_01 (1'b0),
    .ps_intr_02 (1'b0),
    .ps_intr_03 (1'b0),
    .ps_intr_04 (1'b0),
    .ps_intr_05 (1'b0),
    .ps_intr_06 (1'b0),
    .ps_intr_07 (1'b0),
    .ps_intr_08 (1'b0),
    .ps_intr_09 (1'b0),
    .ps_intr_10 (1'b0),
    .ps_intr_11 (1'b0),
    .ps_intr_15 (1'b0),
    .rx_clk_in_n (rx_clk_in_n),
    .rx_clk_in_p (rx_clk_in_p),
    .rx_data_in_n (rx_data_in_n),
    .rx_data_in_p (rx_data_in_p),
    .rx_frame_in_n (rx_frame_in_n),
    .rx_frame_in_p (rx_frame_in_p),
    .spi0_clk_i (1'b0),
    .spi0_clk_o (spi_clk),
    .spi0_csn_0_o (spi_csn),
    .spi0_csn_1_o (oled_csn),
    .spi0_csn_2_o (),
    .spi0_csn_i (1'b1),
    .spi0_sdi_i (spi_miso),
    .spi0_sdo_i (1'b0),
    .spi0_sdo_o (spi_mosi),
    .spi1_clk_i (1'b0),
    .spi1_clk_o (imu_clk),
    .spi1_csn_0_o (imu_csn),
    .spi1_csn_1_o (),
    .spi1_csn_2_o (),
    .spi1_csn_i (1'b1),
    .spi1_sdi_i (imu_miso),
    .spi1_sdo_i (1'b0),
    .spi1_sdo_o (imu_mosi),
    .tdd_sync_i (gps_pps),
    .tdd_sync_o (),
    .tdd_sync_t (),
    .tx_clk_out_n (tx_clk_out_n),
    .tx_clk_out_p (tx_clk_out_p),
    .tx_data_out_n (tx_data_out_n),
    .tx_data_out_p (tx_data_out_p),
    .tx_frame_out_n (tx_frame_out_n),
    .tx_frame_out_p (tx_frame_out_p),
    .txnrx (txnrx),
    .up_enable (gpio_o[47]),
    .up_txnrx (gpio_o[48]));

endmodule

// ***************************************************************************
// ***************************************************************************
