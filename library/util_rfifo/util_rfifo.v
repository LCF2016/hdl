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

module util_rfifo #(

  parameter   NUM_OF_CHANNELS = 4,
  parameter   DIN_DATA_WIDTH = 32,
  parameter   DOUT_DATA_WIDTH = 64,
  parameter   DIN_ADDRESS_WIDTH = 8) (

  // d-in interface

  input                   din_rstn,
  input                   din_clk,
  output                  din_enable_0,
  output                  din_valid_0,
  input       [DIN_DATA_WIDTH-1:0]  din_data_0,
  output                  din_enable_1,
  output                  din_valid_1,
  input       [DIN_DATA_WIDTH-1:0]  din_data_1,
  output                  din_enable_2,
  output                  din_valid_2,
  input       [DIN_DATA_WIDTH-1:0]  din_data_2,
  output                  din_enable_3,
  output                  din_valid_3,
  input       [DIN_DATA_WIDTH-1:0]  din_data_3,
  output                  din_enable_4,
  output                  din_valid_4,
  input       [DIN_DATA_WIDTH-1:0]  din_data_4,
  output                  din_enable_5,
  output                  din_valid_5,
  input       [DIN_DATA_WIDTH-1:0]  din_data_5,
  output                  din_enable_6,
  output                  din_valid_6,
  input       [DIN_DATA_WIDTH-1:0]  din_data_6,
  output                  din_enable_7,
  output                  din_valid_7,
  input       [DIN_DATA_WIDTH-1:0]  din_data_7,
  input                   din_unf,

  // d-out interface

  input                   dout_rst,
  input                   dout_clk,
  input                   dout_enable_0,
  input                   dout_valid_0,
  output      [DOUT_DATA_WIDTH-1:0]  dout_data_0,
  input                   dout_enable_1,
  input                   dout_valid_1,
  output      [DOUT_DATA_WIDTH-1:0]  dout_data_1,
  input                   dout_enable_2,
  input                   dout_valid_2,
  output      [DOUT_DATA_WIDTH-1:0]  dout_data_2,
  input                   dout_enable_3,
  input                   dout_valid_3,
  output      [DOUT_DATA_WIDTH-1:0]  dout_data_3,
  input                   dout_enable_4,
  input                   dout_valid_4,
  output      [DOUT_DATA_WIDTH-1:0]  dout_data_4,
  input                   dout_enable_5,
  input                   dout_valid_5,
  output      [DOUT_DATA_WIDTH-1:0]  dout_data_5,
  input                   dout_enable_6,
  input                   dout_valid_6,
  output      [DOUT_DATA_WIDTH-1:0]  dout_data_6,
  input                   dout_enable_7,
  input                   dout_valid_7,
  output      [DOUT_DATA_WIDTH-1:0]  dout_data_7,
  output  reg             dout_unf);


  localparam  M_MEM_RATIO = DOUT_DATA_WIDTH/DIN_DATA_WIDTH;
  localparam  ADDRESS_WIDTH = (DIN_ADDRESS_WIDTH > 5) ? DIN_ADDRESS_WIDTH : 5;
  localparam  DATA_WIDTH = DOUT_DATA_WIDTH * NUM_OF_CHANNELS;
  localparam  T_DIN_DATA_WIDTH = DIN_DATA_WIDTH * 8;
  localparam  T_DOUT_DATA_WIDTH = DOUT_DATA_WIDTH * 8;

  // internal registers

  reg     [(DATA_WIDTH-1):0]          din_wdata = 'd0;
  reg     [(ADDRESS_WIDTH-1):0]       din_waddr = 'hc;
  reg                                 din_wr = 'd0;
  reg                                 din_valid = 'd0;
  reg     [ 6:0]                      din_req_cnt = 'd0;
  reg     [ 7:0]                      din_enable_m1 = 'd0;
  reg     [ 7:0]                      din_enable = 'd0;
  reg                                 din_req_t_m1 = 'd0;
  reg                                 din_req_t_m2 = 'd0;
  reg                                 din_req_t_m3 = 'd0;
  reg                                 din_req = 'd0;
  reg     [(ADDRESS_WIDTH-4):0]       din_rinit = 'd0;
  reg                                 din_unf_d = 'd0;
  reg     [(T_DOUT_DATA_WIDTH+1):0]   dout_data = 'd0;
  reg     [(DATA_WIDTH-1):0]          dout_rdata = 'd0;
  reg     [ 7:0]                      dout_enable = 'd0;
  reg                                 dout_req_t = 'd0;
  reg     [(ADDRESS_WIDTH-4):0]       dout_rinit = 'd0;
  reg     [(ADDRESS_WIDTH-1):0]       dout_raddr = 'd0;
  reg                                 dout_unf_m1 = 'd0;

  // internal signals

  wire    [(T_DIN_DATA_WIDTH-1):0]    din_data_s;
  wire                                din_req_s;
  wire    [ 7:0]                      dout_enable_s;
  wire    [ 7:0]                      dout_valid_s;
  wire    [(T_DOUT_DATA_WIDTH+1):0]   dout_data_s;
  wire    [(DATA_WIDTH-1):0]          dout_rdata_s;

  // variables

  genvar                              n;

  // enables & valids

  assign din_enable_7 = din_enable[7];
  assign din_enable_6 = din_enable[6];
  assign din_enable_5 = din_enable[5];
  assign din_enable_4 = din_enable[4];
  assign din_enable_3 = din_enable[3];
  assign din_enable_2 = din_enable[2];
  assign din_enable_1 = din_enable[1];
  assign din_enable_0 = din_enable[0];

  assign din_valid_7 = din_valid;
  assign din_valid_6 = din_valid;
  assign din_valid_5 = din_valid;
  assign din_valid_4 = din_valid;
  assign din_valid_3 = din_valid;
  assign din_valid_2 = din_valid;
  assign din_valid_1 = din_valid;
  assign din_valid_0 = din_valid;

  assign din_data_s = { din_data_7, din_data_6, din_data_5, din_data_4,
                        din_data_3, din_data_2, din_data_1, din_data_0};

  // simple data transfer-- no ovf/unf handling- read-bw > write-bw
  // dout_width >= din_width only

  generate
  for (n = 0; n < NUM_OF_CHANNELS; n = n + 1) begin: g_in
  if (M_MEM_RATIO == 1) begin
  always @(posedge din_clk) begin
    if (din_valid == 1'b1) begin
      din_wdata[((DOUT_DATA_WIDTH*(n+1))-1):(DOUT_DATA_WIDTH*n)] <=
        din_data_s[((DIN_DATA_WIDTH*(n+1))-1):(DIN_DATA_WIDTH*n)];
    end
  end
  end else begin
  always @(posedge din_clk) begin
    if (din_valid == 1'b1) begin
      din_wdata[((DOUT_DATA_WIDTH*(n+1))-1):(DOUT_DATA_WIDTH*n)] <=
        {din_data_s[((DIN_DATA_WIDTH*(n+1))-1):(DIN_DATA_WIDTH*n)],
        din_wdata[((DOUT_DATA_WIDTH*(n+1))-1):(DIN_DATA_WIDTH+(DOUT_DATA_WIDTH*n))]};
    end
  end
  end
  end
  endgenerate

  always @(posedge din_clk or negedge din_rstn) begin
    if (din_rstn == 1'b0) begin
      din_waddr <= 'hc;
      din_wr <= 1'd0;
    end else begin
      if (din_req == 1'b1) begin
        din_waddr <= {din_rinit, 3'd0};
      end else if (din_wr == 1'b1) begin
        din_waddr <= din_waddr + 1'b1;
      end
      case (M_MEM_RATIO)
        8: din_wr <= din_req_cnt[6] & din_req_cnt[2] & din_req_cnt[1] & din_req_cnt[0];
        4: din_wr <= din_req_cnt[6] & din_req_cnt[1] & din_req_cnt[0];
        2: din_wr <= din_req_cnt[6] & din_req_cnt[0];
        default: din_wr <= din_req_cnt[6];
      endcase
    end
  end

  always @(posedge din_clk or negedge din_rstn) begin
    if (din_rstn == 1'b0) begin
      din_valid <= 'd0;
      din_req_cnt <= 'd0;
    end else begin
      din_valid <= din_req_cnt[6];
      if (din_req_s == 1'b1) begin
        case (M_MEM_RATIO)
          8: din_req_cnt <= 7'h40;
          4: din_req_cnt <= 7'h60;
          2: din_req_cnt <= 7'h70;
          default: din_req_cnt <= 7'h78;
        endcase
      end else if (din_req_cnt[6] == 1'b1) begin
        din_req_cnt <= din_req_cnt + 1'b1;
      end
    end
  end

  assign din_req_s = din_req_t_m3 ^ din_req_t_m2;

  always @(posedge din_clk or negedge din_rstn) begin
    if (din_rstn == 1'b0) begin
      din_enable_m1 <= 'd0;
      din_enable <= 'd0;
      din_req_t_m1 <= 'd0;
      din_req_t_m2 <= 'd0;
      din_req_t_m3 <= 'd0;
      din_req <= 'd0;
      din_rinit <= 'd0;
      din_unf_d <= 'd0;
    end else begin
      din_enable_m1 <= dout_enable;
      din_enable <= din_enable_m1;
      din_req_t_m1 <= dout_req_t;
      din_req_t_m2 <= din_req_t_m1;
      din_req_t_m3 <= din_req_t_m2;
      din_req <= din_req_s;
      if (din_req_s == 1'b1) begin
        din_rinit <= dout_rinit;
      end
      din_unf_d <= din_unf;
    end
  end

  // read interface (bus expansion and/or clock conversion)

  assign dout_enable_s =  { dout_enable_7, dout_enable_6, dout_enable_5, dout_enable_4,
                            dout_enable_3, dout_enable_2, dout_enable_1, dout_enable_0};

  assign dout_valid_s = { dout_valid_7, dout_valid_6, dout_valid_5, dout_valid_4,
                          dout_valid_3, dout_valid_2, dout_valid_1, dout_valid_0};

  generate
  if (NUM_OF_CHANNELS >= 8) begin
  assign dout_data_s = dout_rdata;
  end else begin
  assign dout_data_s[(T_DOUT_DATA_WIDTH+1):DATA_WIDTH] = 'd0;
  assign dout_data_s[(DATA_WIDTH-1):0] = dout_rdata;
  end
  endgenerate

  assign dout_data_7 = dout_data[((DOUT_DATA_WIDTH*8)-1):(DOUT_DATA_WIDTH*7)];
  assign dout_data_6 = dout_data[((DOUT_DATA_WIDTH*7)-1):(DOUT_DATA_WIDTH*6)];
  assign dout_data_5 = dout_data[((DOUT_DATA_WIDTH*6)-1):(DOUT_DATA_WIDTH*5)];
  assign dout_data_4 = dout_data[((DOUT_DATA_WIDTH*5)-1):(DOUT_DATA_WIDTH*4)];
  assign dout_data_3 = dout_data[((DOUT_DATA_WIDTH*4)-1):(DOUT_DATA_WIDTH*3)];
  assign dout_data_2 = dout_data[((DOUT_DATA_WIDTH*3)-1):(DOUT_DATA_WIDTH*2)];
  assign dout_data_1 = dout_data[((DOUT_DATA_WIDTH*2)-1):(DOUT_DATA_WIDTH*1)];
  assign dout_data_0 = dout_data[((DOUT_DATA_WIDTH*1)-1):(DOUT_DATA_WIDTH*0)];

  generate
  for (n = 0; n < NUM_OF_CHANNELS; n = n + 1) begin: g_out
  always @(posedge dout_clk) begin
    if (dout_rst == 1'b1) begin
      dout_data[((DOUT_DATA_WIDTH*(n+1))-1):(DOUT_DATA_WIDTH*n)] <= 'd0;
    end else if (dout_valid_s[n] == 1'b1) begin
      dout_data[((DOUT_DATA_WIDTH*(n+1))-1):(DOUT_DATA_WIDTH*n)] <=
        dout_data_s[((DOUT_DATA_WIDTH*(n+1))-1):(DOUT_DATA_WIDTH*n)];
    end
  end
  end
  endgenerate

  always @(posedge dout_clk) begin
    dout_rdata <= dout_rdata_s;
  end

  always @(posedge dout_clk) begin
    if (dout_rst == 1'b1) begin
      dout_enable <= 'd0;
      dout_req_t <= 'd0;
      dout_rinit <= 'd0;
      dout_raddr <= 'd0;
    end else begin
      dout_enable <= dout_enable_s;
      if (dout_valid_s[0] == 1'b1) begin
        if (dout_raddr[2:0] == 3'd7) begin
          dout_req_t <= ~dout_req_t;
          dout_rinit <= dout_raddr[(ADDRESS_WIDTH-1):3] + 2'd2;
        end
        dout_raddr <= dout_raddr + 1'b1;
      end
    end
  end

  always @(posedge dout_clk) begin
    if (dout_rst == 1'b1) begin
      dout_unf_m1 <= 'd0;
      dout_unf <= 'd0;
    end else begin
      dout_unf_m1 <= din_unf_d;
      dout_unf <= dout_unf_m1;
    end
  end

  // instantiations

  ad_mem #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH)) i_mem (
    .clka (din_clk),
    .wea (din_wr),
    .addra (din_waddr),
    .dina (din_wdata),
    .clkb (dout_clk),
    .addrb (dout_raddr),
    .doutb (dout_rdata_s));

endmodule

// ***************************************************************************
// ***************************************************************************
