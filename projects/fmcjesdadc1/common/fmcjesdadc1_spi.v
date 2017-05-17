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

module fmcjesdadc1_spi (

  input                   spi_csn,
  input                   spi_clk,
  input                   spi_mosi,
  output                  spi_miso,

  inout                   spi_sdio);

  localparam  FMC27X_CPLD = 8'h00;
  localparam  FMC27X_AD9517 = 8'h84;
  localparam  FMC27X_AD9250_0 = 8'h80;
  localparam  FMC27X_AD9250_1 = 8'h81;
  localparam  FMC27X_AD9129_0 = 8'h82;
  localparam  FMC27X_AD9129_1 = 8'h83;

  // internal registers

  reg     [ 7:0]  spi_devid = 'd0;
  reg     [ 5:0]  spi_count = 'd0;
  reg             spi_rd_wr_n = 'd0;
  reg             spi_enable = 'd0;

  // internal signals

  wire            spi_enable_s;

  // check on rising edge and change on falling edge

  assign spi_enable_s = spi_enable & ~spi_csn;

  always @(posedge spi_clk or posedge spi_csn) begin
    if (spi_csn == 1'b1) begin
      spi_count <= 6'd0;
      spi_devid <= 8'd0;
      spi_rd_wr_n <= 1'd0;
    end else begin
      spi_count <= spi_count + 1'b1;
      if (spi_count <= 6'd7) begin
        spi_devid <= {spi_devid[6:0], spi_mosi};
      end
      if (spi_count == 6'd8) begin
        spi_rd_wr_n <= spi_mosi;
      end
    end
  end

  always @(negedge spi_clk or posedge spi_csn) begin
    if (spi_csn == 1'b1) begin
      spi_enable <= 1'b0;
    end else begin
      if (((spi_count == 6'd16) && (spi_devid == FMC27X_CPLD)) ||
          ((spi_count == 6'd16) && (spi_devid == FMC27X_AD9129_0)) ||
          ((spi_count == 6'd16) && (spi_devid == FMC27X_AD9129_1)) ||
          ((spi_count == 6'd24) && (spi_devid == FMC27X_AD9517)) ||
          ((spi_count == 6'd24) && (spi_devid == FMC27X_AD9250_0)) ||
          ((spi_count == 6'd24) && (spi_devid == FMC27X_AD9250_1))) begin
        spi_enable <= spi_rd_wr_n;
      end
    end
  end

  assign spi_miso = spi_sdio;
  assign spi_sdio = (spi_enable_s == 1'b1) ? 1'bz : spi_mosi;

endmodule

// ***************************************************************************
// ***************************************************************************
