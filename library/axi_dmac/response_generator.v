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

module dmac_response_generator (
  input clk,
  input resetn,

  input enable,
  output reg enabled,

  input [ID_WIDTH-1:0] request_id,
  output reg [ID_WIDTH-1:0] response_id,
  input sync_id,

  input eot,

  output resp_valid,
  input resp_ready,
  output resp_eot,
  output [1:0] resp_resp
);

parameter ID_WIDTH = 3;

`include "inc_id.h"
`include "resp.h"

assign resp_resp = RESP_OKAY;
assign resp_eot = eot;

assign resp_valid = request_id != response_id && enabled;

// We have to wait for all responses before we can disable the response handler
always @(posedge clk) begin
  if (resetn == 1'b0) begin
    enabled <= 1'b0;
  end else begin
    if (enable)
      enabled <= 1'b1;
    else if (request_id == response_id)
      enabled <= 1'b0;
  end
end

always @(posedge clk) begin
  if (resetn == 1'b0) begin
    response_id <= 'h0;
  end else begin
    if ((resp_valid && resp_ready) ||
      (sync_id && response_id != request_id))
      response_id <= inc_id(response_id);
  end
end

endmodule
