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

module ad_lvds_in #(

  // parameters

  parameter   SINGLE_ENDED = 0,
  parameter   DEVICE_TYPE = 0,
  parameter   IODELAY_ENABLE = 1,
  parameter   IODELAY_CTRL = 0,
  parameter   IODELAY_GROUP = "dev_if_delay_group") (

  // data interface

  input               rx_clk,
  input               rx_data_in_p,
  input               rx_data_in_n,
  output              rx_data_p,
  output              rx_data_n,

  // delay-data interface

  input               up_clk,
  input               up_dld,
  input       [ 4:0]  up_dwdata,
  output      [ 4:0]  up_drdata,

  // delay-cntrl interface

  input               delay_clk,
  input               delay_rst,
  output              delay_locked);

  // internal parameters

  localparam  VIRTEX7 = 0;
  localparam  VIRTEX6 = 1;
  localparam  ULTRASCALE_PLUS = 2;
  localparam  ULTRASCALE = 3;

  // internal signals

  wire                rx_data_ibuf_s;
  wire                rx_data_idelay_s;
  wire        [ 8:0]  up_drdata_s;

  // delay controller

  generate if (IODELAY_ENABLE == 1 && IODELAY_CTRL == 1) begin
    if ((DEVICE_TYPE == ULTRASCALE_PLUS) || (DEVICE_TYPE == ULTRASCALE)) begin
    (* IODELAY_GROUP = IODELAY_GROUP *)
    IDELAYCTRL #(.SIM_DEVICE ("ULTRASCALE")) i_delay_ctrl (
      .RST (delay_rst),
      .REFCLK (delay_clk),
      .RDY (delay_locked));
    end
    if ((DEVICE_TYPE == VIRTEX7) || (DEVICE_TYPE == VIRTEX6)) begin
    (* IODELAY_GROUP = IODELAY_GROUP *)
    IDELAYCTRL i_delay_ctrl (
      .RST (delay_rst),
      .REFCLK (delay_clk),
      .RDY (delay_locked));
    end
  end else begin
     assign delay_locked = 1'b1;
  end
  endgenerate

  // receive data interface, ibuf -> idelay -> iddr

  generate
  if (SINGLE_ENDED == 1) begin
  IBUF i_rx_data_ibuf (
    .I (rx_data_in_p),
    .O (rx_data_ibuf_s));
  end else begin
  IBUFDS i_rx_data_ibuf (
    .I (rx_data_in_p),
    .IB (rx_data_in_n),
    .O (rx_data_ibuf_s));
  end
  endgenerate

  // idelay

  generate if (IODELAY_ENABLE == 1) begin
  if (DEVICE_TYPE == VIRTEX6) begin
  (* IODELAY_GROUP = IODELAY_GROUP *)
  IODELAYE1 #(
    .CINVCTRL_SEL ("FALSE"),
    .DELAY_SRC ("I"),
    .HIGH_PERFORMANCE_MODE ("TRUE"),
    .IDELAY_TYPE ("VAR_LOADABLE"),
    .IDELAY_VALUE (0),
    .ODELAY_TYPE ("FIXED"),
    .ODELAY_VALUE (0),
    .REFCLK_FREQUENCY (200.0),
    .SIGNAL_PATTERN ("DATA"))
  i_rx_data_idelay (
    .T (1'b1),
    .CE (1'b0),
    .INC (1'b0),
    .CLKIN (1'b0),
    .DATAIN (1'b0),
    .ODATAIN (1'b0),
    .CINVCTRL (1'b0),
    .C (up_clk),
    .IDATAIN (rx_data_ibuf_s),
    .DATAOUT (rx_data_idelay_s),
    .RST (up_dld),
    .CNTVALUEIN (up_dwdata),
    .CNTVALUEOUT (up_drdata));
  end

  if (DEVICE_TYPE == VIRTEX7) begin
  (* IODELAY_GROUP = IODELAY_GROUP *)
  IDELAYE2 #(
    .CINVCTRL_SEL ("FALSE"),
    .DELAY_SRC ("IDATAIN"),
    .HIGH_PERFORMANCE_MODE ("FALSE"),
    .IDELAY_TYPE ("VAR_LOAD"),
    .IDELAY_VALUE (0),
    .REFCLK_FREQUENCY (200.0),
    .PIPE_SEL ("FALSE"),
    .SIGNAL_PATTERN ("DATA"))
  i_rx_data_idelay (
    .CE (1'b0),
    .INC (1'b0),
    .DATAIN (1'b0),
    .LDPIPEEN (1'b0),
    .CINVCTRL (1'b0),
    .REGRST (1'b0),
    .C (up_clk),
    .IDATAIN (rx_data_ibuf_s),
    .DATAOUT (rx_data_idelay_s),
    .LD (up_dld),
    .CNTVALUEIN (up_dwdata),
    .CNTVALUEOUT (up_drdata));
  end

  if (DEVICE_TYPE == ULTRASCALE) begin
  assign up_drdata = up_drdata_s[8:4];
  (* IODELAY_GROUP = IODELAY_GROUP *)
  IDELAYE3 #(
    .SIM_DEVICE ("ULTRASCALE"),
    .DELAY_SRC ("IDATAIN"),
    .DELAY_TYPE ("VAR_LOAD"),
    .REFCLK_FREQUENCY (200.0),
    .DELAY_FORMAT ("COUNT"))
  i_rx_data_idelay (
    .CASC_RETURN (1'b0),
    .CASC_IN (1'b0),
    .CASC_OUT (),
    .CE (1'b0),
    .CLK (up_clk),
    .INC (1'b0),
    .LOAD (up_dld),
    .CNTVALUEIN ({up_dwdata, 4'd0}),
    .CNTVALUEOUT (up_drdata_s),
    .DATAIN (1'b0),
    .IDATAIN (rx_data_ibuf_s),
    .DATAOUT (rx_data_idelay_s),
    .RST (1'b0),
    .EN_VTC (~up_dld));
  end

  if (DEVICE_TYPE == ULTRASCALE_PLUS) begin
  assign up_drdata = up_drdata_s[8:4];
  (* IODELAY_GROUP = IODELAY_GROUP *)
  IDELAYE3 #(
    .SIM_DEVICE ("ULTRASCALE_PLUS_ES1"),
    .DELAY_SRC ("IDATAIN"),
    .DELAY_TYPE ("VAR_LOAD"),
    .REFCLK_FREQUENCY (200.0),
    .DELAY_FORMAT ("COUNT"))
  i_rx_data_idelay (
    .CASC_RETURN (1'b0),
    .CASC_IN (1'b0),
    .CASC_OUT (),
    .CE (1'b0),
    .CLK (up_clk),
    .INC (1'b0),
    .LOAD (up_dld),
    .CNTVALUEIN ({up_dwdata, 4'd0}),
    .CNTVALUEOUT (up_drdata_s),
    .DATAIN (1'b0),
    .IDATAIN (rx_data_ibuf_s),
    .DATAOUT (rx_data_idelay_s),
    .RST (1'b0),
    .EN_VTC (~up_dld));
  end

  end else begin
    assign rx_data_idelay_s = rx_data_ibuf_s;
	assign up_drdata = 'h00;
  end
  endgenerate

  // iddr

  generate
  if (DEVICE_TYPE == ULTRASCALE) begin
  IDDRE1 #(
    .DDR_CLK_EDGE ("SAME_EDGE"))
  i_rx_data_iddr (
    .R (1'b0),
    .C (rx_clk),
    .CB (~rx_clk),
    .D (rx_data_idelay_s),
    .Q1 (rx_data_p),
    .Q2 (rx_data_n));
  end
  endgenerate

  generate
  if (DEVICE_TYPE == ULTRASCALE_PLUS) begin
  IDDRE1 #(
    .DDR_CLK_EDGE ("SAME_EDGE"))
  i_rx_data_iddr (
    .R (1'b0),
    .C (rx_clk),
    .CB (~rx_clk),
    .D (rx_data_idelay_s),
    .Q1 (rx_data_p),
    .Q2 (rx_data_n));
  end
  endgenerate

  generate
  if ((DEVICE_TYPE == VIRTEX7) || (DEVICE_TYPE == VIRTEX6)) begin
  IDDR #(
    .DDR_CLK_EDGE ("SAME_EDGE"),
    .INIT_Q1 (1'b0),
    .INIT_Q2 (1'b0),
    .SRTYPE ("ASYNC"))
  i_rx_data_iddr (
    .CE (1'b1),
    .R (1'b0),
    .S (1'b0),
    .C (rx_clk),
    .D (rx_data_idelay_s),
    .Q1 (rx_data_p),
    .Q2 (rx_data_n));
  end
  endgenerate

endmodule

// ***************************************************************************
// ***************************************************************************
