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
// this is a sine function (approximate), the basic idea is to approximate sine as a
// polynomial function (there are a lot of stuff about this on the web)

`timescale 1ns/100ps

module ad_dds_sine #(

  parameter   DELAY_DATA_WIDTH = 16) (

  // sine = sin(angle)

  input                   clk,
  input       [ 15:0]     angle,
  output  reg [ 15:0]     sine,
  input       [ DW:0]     ddata_in,
  output  reg [ DW:0]     ddata_out);

  localparam  DW = DELAY_DATA_WIDTH - 1;

  // internal registers

  reg     [ 33:0]   s1_data_p = 'd0;
  reg     [ 33:0]   s1_data_n = 'd0;
  reg     [ 15:0]   s1_angle = 'd0;
  reg     [ DW:0]   s1_ddata = 'd0;
  reg     [ 18:0]   s2_data_0 = 'd0;
  reg     [ 18:0]   s2_data_1 = 'd0;
  reg     [ DW:0]   s2_ddata = 'd0;
  reg     [ 18:0]   s3_data = 'd0;
  reg     [ DW:0]   s3_ddata = 'd0;
  reg     [ 33:0]   s4_data2_p = 'd0;
  reg     [ 33:0]   s4_data2_n = 'd0;
  reg     [ 16:0]   s4_data1_p = 'd0;
  reg     [ 16:0]   s4_data1_n = 'd0;
  reg     [ DW:0]   s4_ddata = 'd0;
  reg     [ 16:0]   s5_data2_0 = 'd0;
  reg     [ 16:0]   s5_data2_1 = 'd0;
  reg     [ 16:0]   s5_data1 = 'd0;
  reg     [ DW:0]   s5_ddata = 'd0;
  reg     [ 16:0]   s6_data2 = 'd0;
  reg     [ 16:0]   s6_data1 = 'd0;
  reg     [ DW:0]   s6_ddata = 'd0;
  reg     [ 33:0]   s7_data = 'd0;
  reg     [ DW:0]   s7_ddata = 'd0;

  // internal signals

  wire    [ 15:0]   angle_s;
  wire    [ 33:0]   s1_data_s;
  wire    [ DW:0]   s1_ddata_s;
  wire    [ 15:0]   s1_angle_s;
  wire    [ 33:0]   s4_data2_s;
  wire    [ DW:0]   s4_ddata_s;
  wire    [ 16:0]   s4_data1_s;
  wire    [ 33:0]   s7_data2_s;
  wire    [ 33:0]   s7_data1_s;
  wire    [ DW:0]   s7_ddata_s;

  // make angle 2's complement

  assign angle_s = {~angle[15], angle[14:0]};

  // level 1 - intermediate

  ad_mul #(.DELAY_DATA_WIDTH(DELAY_DATA_WIDTH+16)) i_mul_s1 (
    .clk (clk),
    .data_a ({angle_s[15], angle_s}),
    .data_b ({angle_s[15], angle_s}),
    .data_p (s1_data_s),
    .ddata_in ({ddata_in, angle_s}),
    .ddata_out ({s1_ddata_s, s1_angle_s}));

  // 2's complement versions

  always @(posedge clk) begin
    s1_data_p <= s1_data_s;
    s1_data_n <= ~s1_data_s + 1'b1;
    s1_angle <= s1_angle_s;
    s1_ddata <= s1_ddata_s;
  end

  // select partial products

  always @(posedge clk) begin
    s2_data_0 <= (s1_angle[15] == 1'b0) ? s1_data_n[31:13] : s1_data_p[31:13];
    s2_data_1 <= {s1_angle[15], s1_angle[15:0], 2'b00};
    s2_ddata <= s1_ddata;
  end

  // unit-sine

  always @(posedge clk) begin
    s3_data <= s2_data_0 + s2_data_1;
    s3_ddata <= s2_ddata;
  end

  // level 2 - final

  ad_mul #(.DELAY_DATA_WIDTH(DELAY_DATA_WIDTH+17)) i_mul_s2 (
    .clk (clk),
    .data_a (s3_data[16:0]),
    .data_b (s3_data[16:0]),
    .data_p (s4_data2_s),
    .ddata_in ({s3_ddata, s3_data[16:0]}),
    .ddata_out ({s4_ddata_s, s4_data1_s}));

  // 2's complement versions

  always @(posedge clk) begin
    s4_data2_p <= s4_data2_s;
    s4_data2_n <= ~s4_data2_s + 1'b1;
    s4_data1_p <= s4_data1_s;
    s4_data1_n <= ~s4_data1_s + 1'b1;
    s4_ddata <= s4_ddata_s;
  end

  // select partial products

  always @(posedge clk) begin
    s5_data2_0 <= (s4_data1_p[16] == 1'b1) ? s4_data2_n[31:15] : s4_data2_p[31:15];
    s5_data2_1 <= s4_data1_n;
    s5_data1 <= s4_data1_p;
    s5_ddata <= s4_ddata;
  end

  // corrected-sine

  always @(posedge clk) begin
    s6_data2 <= s5_data2_0 + s5_data2_1;
    s6_data1 <= s5_data1;
    s6_ddata <= s5_ddata;
  end

  // full-scale

  ad_mul #(.DELAY_DATA_WIDTH(1)) i_mul_s3_2 (
    .clk (clk),
    .data_a (s6_data2),
    .data_b (17'h1d08),
    .data_p (s7_data2_s),
    .ddata_in (1'b0),
    .ddata_out ());

  ad_mul #(.DELAY_DATA_WIDTH(DELAY_DATA_WIDTH)) i_mul_s3_1 (
    .clk (clk),
    .data_a (s6_data1),
    .data_b (17'h7fff),
    .data_p (s7_data1_s),
    .ddata_in (s6_ddata),
    .ddata_out (s7_ddata_s));

  // corrected sum

  always @(posedge clk) begin
    s7_data <= s7_data2_s + s7_data1_s;
    s7_ddata <= s7_ddata_s;
  end

  // output registers

  always @(posedge clk) begin
    sine <= s7_data[30:15];
    ddata_out <= s7_ddata;
  end

endmodule

// ***************************************************************************
// ***************************************************************************
