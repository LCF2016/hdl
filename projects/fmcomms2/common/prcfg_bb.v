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
// black box definition for pr module

`timescale 1ns/100ps

(* black_box *)

module prcfg (

  input               clk,
  input   [31:0]      adc_gpio_input,
  output  [31:0]      adc_gpio_output,
  input   [31:0]      dac_gpio_input,
  output  [31:0]      dac_gpio_output,
  input               dma_dac_i0_enable,
  output  [15:0]      dma_dac_i0_data,
  input               dma_dac_i0_valid,
  input               dma_dac_q0_enable,
  output  [15:0]      dma_dac_q0_data,
  input               dma_dac_q0_valid,
  input               dma_dac_i1_enable,
  output  [15:0]      dma_dac_i1_data,
  input               dma_dac_i1_valid,
  input               dma_dac_q1_enable,
  output  [15:0]      dma_dac_q1_data,
  input               dma_dac_q1_valid,
  output              core_dac_i0_enable,
  input   [15:0]      core_dac_i0_data,
  output              core_dac_i0_valid,
  output              core_dac_q0_enable,
  input   [15:0]      core_dac_q0_data,
  output              core_dac_q0_valid,
  output              core_dac_i1_enable,
  input   [15:0]      core_dac_i1_data,
  output              core_dac_i1_valid,
  output              core_dac_q1_enable,
  input   [15:0]      core_dac_q1_data,
  output              core_dac_q1_valid,
  input               dma_adc_i0_enable,
  input   [15:0]      dma_adc_i0_data,
  input               dma_adc_i0_valid,
  input               dma_adc_q0_enable,
  input   [15:0]      dma_adc_q0_data,
  input               dma_adc_q0_valid,
  input               dma_adc_i1_enable,
  input   [15:0]      dma_adc_i1_data,
  input               dma_adc_i1_valid,
  input               dma_adc_q1_enable,
  input   [15:0]      dma_adc_q1_data,
  input               dma_adc_q1_valid,
  output              core_adc_i0_enable,
  output  [15:0]      core_adc_i0_data,
  output              core_adc_i0_valid,
  output              core_adc_q0_enable,
  output  [15:0]      core_adc_q0_data,
  output              core_adc_q0_valid,
  output              core_adc_i1_enable,
  output  [15:0]      core_adc_i1_data,
  output              core_adc_i1_valid,
  output              core_adc_q1_enable,
  output  [15:0]      core_adc_q1_data,
  output              core_adc_q1_valid
  );

endmodule

// ***************************************************************************
// ***************************************************************************
