/* verilator lint_off DECLFILENAME */
/* verilator lint_off MODDUP */
/* verilator lint_off MULTITOP */
/* verilator lint_off GENUNNAMED */
/* verilator lint_off VARHIDDEN */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off UNUSEDGENVAR */

module PlicGateway(
  input   clock,
  input   io_rst_n, // @[src/main/scala/plic/PlicGateway.scala 17:14]
  input   io_src, // @[src/main/scala/plic/PlicGateway.scala 17:14]
  input   io_edge_lvl, // @[src/main/scala/plic/PlicGateway.scala 17:14]
  output  io_ip, // @[src/main/scala/plic/PlicGateway.scala 17:14]
  input   io_claim, // @[src/main/scala/plic/PlicGateway.scala 17:14]
  input   io_complete // @[src/main/scala/plic/PlicGateway.scala 17:14]
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
`endif // RANDOMIZE_REG_INIT
  wire  asyncReset = ~io_rst_n; // @[src/main/scala/plic/PlicGateway.scala 19:32]
  reg  src_dly; // @[src/main/scala/plic/PlicGateway.scala 22:21]
  reg  src_edge; // @[src/main/scala/plic/PlicGateway.scala 23:21]
  reg [4:0] pending_cnt; // @[src/main/scala/plic/PlicGateway.scala 24:21]
  reg  decr_pending; // @[src/main/scala/plic/PlicGateway.scala 25:21]
  reg [1:0] ip_state; // @[src/main/scala/plic/PlicGateway.scala 27:21]
  wire [4:0] _nxt_pending_cnt_T_1 = pending_cnt - 5'h1; // @[src/main/scala/plic/PlicGateway.scala 39:62]
  wire [4:0] _GEN_0 = pending_cnt > 5'h0 ? _nxt_pending_cnt_T_1 : pending_cnt; // @[src/main/scala/plic/PlicGateway.scala 39:{29,47} 40:34]
  wire [4:0] _nxt_pending_cnt_T_3 = pending_cnt + 5'h1; // @[src/main/scala/plic/PlicGateway.scala 42:76]
  wire [4:0] _GEN_1 = pending_cnt < 5'h10 ? _nxt_pending_cnt_T_3 : pending_cnt; // @[src/main/scala/plic/PlicGateway.scala 42:{43,61} 43:34]
  wire [4:0] _GEN_2 = ~decr_pending & src_edge ? _GEN_1 : pending_cnt; // @[src/main/scala/plic/PlicGateway.scala 41:42 45:21]
  wire [4:0] nxt_pending_cnt = decr_pending & ~src_edge ? _GEN_0 : _GEN_2; // @[src/main/scala/plic/PlicGateway.scala 38:35]
  wire  _T_6 = ~io_edge_lvl; // @[src/main/scala/plic/PlicGateway.scala 48:8]
  wire  _T_12 = io_edge_lvl & nxt_pending_cnt != 5'h0 | _T_6 & io_src; // @[src/main/scala/plic/PlicGateway.scala 58:55]
  assign io_ip = ip_state == 2'h1; // @[src/main/scala/plic/PlicGateway.scala 71:21]
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicGateway.scala 22:21]
      src_dly <= 1'h0; // @[src/main/scala/plic/PlicGateway.scala 22:21]
    end else begin
      src_dly <= io_src; // @[src/main/scala/plic/PlicGateway.scala 34:11]
    end
  end
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicGateway.scala 35:22]
      src_edge <= 1'h0;
    end else begin
      src_edge <= io_src & ~src_dly;
    end
  end
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicGateway.scala 48:22]
      pending_cnt <= 5'h0; // @[src/main/scala/plic/PlicGateway.scala 49:17]
    end else if (~io_edge_lvl) begin // @[src/main/scala/plic/PlicGateway.scala 38:35]
      pending_cnt <= 5'h0; // @[src/main/scala/plic/PlicGateway.scala 39:{29,47} 40:34]
    end else if (decr_pending & ~src_edge) begin // @[src/main/scala/plic/PlicGateway.scala 41:42]
      if (pending_cnt > 5'h0) begin // @[src/main/scala/plic/PlicGateway.scala 42:43]
        pending_cnt <= _nxt_pending_cnt_T_1; // @[src/main/scala/plic/PlicGateway.scala 42:61]
      end
    end else if (~decr_pending & src_edge) begin // @[src/main/scala/plic/PlicGateway.scala 45:21]
      if (pending_cnt < 5'h10) begin
        pending_cnt <= _nxt_pending_cnt_T_3;
      end
    end
  end
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicGateway.scala 56:20]
      decr_pending <= 1'h0;
    end else begin
      decr_pending <= 2'h0 == ip_state & _T_12; // @[src/main/scala/plic/PlicGateway.scala 55:16]
    end
  end
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicGateway.scala 56:20]
      ip_state <= 2'h0; // @[src/main/scala/plic/PlicGateway.scala 58:84 59:18 27:21]
    end else if (2'h0 == ip_state) begin // @[src/main/scala/plic/PlicGateway.scala 56:20]
      if (io_edge_lvl & nxt_pending_cnt != 5'h0 | _T_6 & io_src) begin // @[src/main/scala/plic/PlicGateway.scala 64:22]
        ip_state <= 2'h1; // @[src/main/scala/plic/PlicGateway.scala 64:33]
      end
    end else if (2'h1 == ip_state) begin // @[src/main/scala/plic/PlicGateway.scala 56:20]
      if (io_claim) begin // @[src/main/scala/plic/PlicGateway.scala 67:25]
        ip_state <= 2'h2; // @[src/main/scala/plic/PlicGateway.scala 67:36]
      end
    end else if (2'h2 == ip_state) begin // @[src/main/scala/plic/PlicGateway.scala 27:21]
      if (io_complete) begin
        ip_state <= 2'h0;
      end
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  src_dly = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  src_edge = _RAND_1[0:0];
  _RAND_2 = {1{`RANDOM}};
  pending_cnt = _RAND_2[4:0];
  _RAND_3 = {1{`RANDOM}};
  decr_pending = _RAND_3[0:0];
  _RAND_4 = {1{`RANDOM}};
  ip_state = _RAND_4[1:0];
`endif // RANDOMIZE_REG_INIT
  if (asyncReset) begin
    src_dly = 1'h0;
  end
  if (asyncReset) begin
    src_edge = 1'h0;
  end
  if (asyncReset) begin
    pending_cnt = 5'h0;
  end
  if (asyncReset) begin
    decr_pending = 1'h0;
  end
  if (asyncReset) begin
    ip_state = 2'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module PlicCell(
  input        clock,
  input        io_rst_n, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ip, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ie, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input  [2:0] io_priority, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [3:0] io_id, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [2:0] io_priorityOut // @[src/main/scala/plic/PlicCell.scala 18:14]
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  asyncReset = ~io_rst_n; // @[src/main/scala/plic/PlicCell.scala 20:32]
  reg [2:0] priorityReg; // @[src/main/scala/plic/PlicCell.scala 23:20]
  reg [3:0] idReg; // @[src/main/scala/plic/PlicCell.scala 24:20]
  wire  _T = io_ip & io_ie; // @[src/main/scala/plic/PlicCell.scala 28:14]
  assign io_id = idReg; // @[src/main/scala/plic/PlicCell.scala 37:9]
  assign io_priorityOut = priorityReg; // @[src/main/scala/plic/PlicCell.scala 36:18]
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= 3'h0; // @[src/main/scala/plic/PlicCell.scala 29:17]
    end else if (io_ip & io_ie) begin // @[src/main/scala/plic/PlicCell.scala 32:17]
      priorityReg <= io_priority;
    end else begin
      priorityReg <= 3'h0;
    end
  end
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 24:20]
      idReg <= 4'h0; // @[src/main/scala/plic/PlicCell.scala 24:20]
    end else begin
      idReg <= {{3'd0}, _T};
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  priorityReg = _RAND_0[2:0];
  _RAND_1 = {1{`RANDOM}};
  idReg = _RAND_1[3:0];
`endif // RANDOMIZE_REG_INIT
  if (asyncReset) begin
    priorityReg = 3'h0;
  end
  if (asyncReset) begin
    idReg = 4'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module PlicCell_1(
  input        clock,
  input        io_rst_n, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ip, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ie, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input  [2:0] io_priority, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [3:0] io_id, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [2:0] io_priorityOut // @[src/main/scala/plic/PlicCell.scala 18:14]
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  asyncReset = ~io_rst_n; // @[src/main/scala/plic/PlicCell.scala 20:32]
  reg [2:0] priorityReg; // @[src/main/scala/plic/PlicCell.scala 23:20]
  reg [3:0] idReg; // @[src/main/scala/plic/PlicCell.scala 24:20]
  wire [1:0] _GEN_1 = io_ip & io_ie ? 2'h2 : 2'h0; // @[src/main/scala/plic/PlicCell.scala 28:24 30:11 33:11]
  assign io_id = idReg; // @[src/main/scala/plic/PlicCell.scala 37:9]
  assign io_priorityOut = priorityReg; // @[src/main/scala/plic/PlicCell.scala 36:18]
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= 3'h0; // @[src/main/scala/plic/PlicCell.scala 29:17]
    end else if (io_ip & io_ie) begin // @[src/main/scala/plic/PlicCell.scala 32:17]
      priorityReg <= io_priority;
    end else begin
      priorityReg <= 3'h0;
    end
  end
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 24:20]
      idReg <= 4'h0; // @[src/main/scala/plic/PlicCell.scala 24:20]
    end else begin
      idReg <= {{2'd0}, _GEN_1};
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  priorityReg = _RAND_0[2:0];
  _RAND_1 = {1{`RANDOM}};
  idReg = _RAND_1[3:0];
`endif // RANDOMIZE_REG_INIT
  if (asyncReset) begin
    priorityReg = 3'h0;
  end
  if (asyncReset) begin
    idReg = 4'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module PlicCell_2(
  input        clock,
  input        io_rst_n, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ip, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ie, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input  [2:0] io_priority, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [3:0] io_id, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [2:0] io_priorityOut // @[src/main/scala/plic/PlicCell.scala 18:14]
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  asyncReset = ~io_rst_n; // @[src/main/scala/plic/PlicCell.scala 20:32]
  reg [2:0] priorityReg; // @[src/main/scala/plic/PlicCell.scala 23:20]
  reg [3:0] idReg; // @[src/main/scala/plic/PlicCell.scala 24:20]
  wire [1:0] _GEN_1 = io_ip & io_ie ? 2'h3 : 2'h0; // @[src/main/scala/plic/PlicCell.scala 28:24 30:11 33:11]
  assign io_id = idReg; // @[src/main/scala/plic/PlicCell.scala 37:9]
  assign io_priorityOut = priorityReg; // @[src/main/scala/plic/PlicCell.scala 36:18]
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= 3'h0; // @[src/main/scala/plic/PlicCell.scala 29:17]
    end else if (io_ip & io_ie) begin // @[src/main/scala/plic/PlicCell.scala 32:17]
      priorityReg <= io_priority;
    end else begin
      priorityReg <= 3'h0;
    end
  end
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 24:20]
      idReg <= 4'h0; // @[src/main/scala/plic/PlicCell.scala 24:20]
    end else begin
      idReg <= {{2'd0}, _GEN_1};
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  priorityReg = _RAND_0[2:0];
  _RAND_1 = {1{`RANDOM}};
  idReg = _RAND_1[3:0];
`endif // RANDOMIZE_REG_INIT
  if (asyncReset) begin
    priorityReg = 3'h0;
  end
  if (asyncReset) begin
    idReg = 4'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module PlicCell_3(
  input        clock,
  input        io_rst_n, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ip, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ie, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input  [2:0] io_priority, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [3:0] io_id, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [2:0] io_priorityOut // @[src/main/scala/plic/PlicCell.scala 18:14]
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  asyncReset = ~io_rst_n; // @[src/main/scala/plic/PlicCell.scala 20:32]
  reg [2:0] priorityReg; // @[src/main/scala/plic/PlicCell.scala 23:20]
  reg [3:0] idReg; // @[src/main/scala/plic/PlicCell.scala 24:20]
  wire [2:0] _GEN_1 = io_ip & io_ie ? 3'h4 : 3'h0; // @[src/main/scala/plic/PlicCell.scala 28:24 30:11 33:11]
  assign io_id = idReg; // @[src/main/scala/plic/PlicCell.scala 37:9]
  assign io_priorityOut = priorityReg; // @[src/main/scala/plic/PlicCell.scala 36:18]
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= 3'h0; // @[src/main/scala/plic/PlicCell.scala 29:17]
    end else if (io_ip & io_ie) begin // @[src/main/scala/plic/PlicCell.scala 32:17]
      priorityReg <= io_priority;
    end else begin
      priorityReg <= 3'h0;
    end
  end
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 24:20]
      idReg <= 4'h0; // @[src/main/scala/plic/PlicCell.scala 24:20]
    end else begin
      idReg <= {{1'd0}, _GEN_1};
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  priorityReg = _RAND_0[2:0];
  _RAND_1 = {1{`RANDOM}};
  idReg = _RAND_1[3:0];
`endif // RANDOMIZE_REG_INIT
  if (asyncReset) begin
    priorityReg = 3'h0;
  end
  if (asyncReset) begin
    idReg = 4'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module PlicCell_4(
  input        clock,
  input        io_rst_n, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ip, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ie, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input  [2:0] io_priority, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [3:0] io_id, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [2:0] io_priorityOut // @[src/main/scala/plic/PlicCell.scala 18:14]
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  asyncReset = ~io_rst_n; // @[src/main/scala/plic/PlicCell.scala 20:32]
  reg [2:0] priorityReg; // @[src/main/scala/plic/PlicCell.scala 23:20]
  reg [3:0] idReg; // @[src/main/scala/plic/PlicCell.scala 24:20]
  wire [2:0] _GEN_1 = io_ip & io_ie ? 3'h5 : 3'h0; // @[src/main/scala/plic/PlicCell.scala 28:24 30:11 33:11]
  assign io_id = idReg; // @[src/main/scala/plic/PlicCell.scala 37:9]
  assign io_priorityOut = priorityReg; // @[src/main/scala/plic/PlicCell.scala 36:18]
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= 3'h0; // @[src/main/scala/plic/PlicCell.scala 29:17]
    end else if (io_ip & io_ie) begin // @[src/main/scala/plic/PlicCell.scala 32:17]
      priorityReg <= io_priority;
    end else begin
      priorityReg <= 3'h0;
    end
  end
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 24:20]
      idReg <= 4'h0; // @[src/main/scala/plic/PlicCell.scala 24:20]
    end else begin
      idReg <= {{1'd0}, _GEN_1};
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  priorityReg = _RAND_0[2:0];
  _RAND_1 = {1{`RANDOM}};
  idReg = _RAND_1[3:0];
`endif // RANDOMIZE_REG_INIT
  if (asyncReset) begin
    priorityReg = 3'h0;
  end
  if (asyncReset) begin
    idReg = 4'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module PlicCell_5(
  input        clock,
  input        io_rst_n, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ip, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ie, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input  [2:0] io_priority, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [3:0] io_id, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [2:0] io_priorityOut // @[src/main/scala/plic/PlicCell.scala 18:14]
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  asyncReset = ~io_rst_n; // @[src/main/scala/plic/PlicCell.scala 20:32]
  reg [2:0] priorityReg; // @[src/main/scala/plic/PlicCell.scala 23:20]
  reg [3:0] idReg; // @[src/main/scala/plic/PlicCell.scala 24:20]
  wire [2:0] _GEN_1 = io_ip & io_ie ? 3'h6 : 3'h0; // @[src/main/scala/plic/PlicCell.scala 28:24 30:11 33:11]
  assign io_id = idReg; // @[src/main/scala/plic/PlicCell.scala 37:9]
  assign io_priorityOut = priorityReg; // @[src/main/scala/plic/PlicCell.scala 36:18]
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= 3'h0; // @[src/main/scala/plic/PlicCell.scala 29:17]
    end else if (io_ip & io_ie) begin // @[src/main/scala/plic/PlicCell.scala 32:17]
      priorityReg <= io_priority;
    end else begin
      priorityReg <= 3'h0;
    end
  end
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 24:20]
      idReg <= 4'h0; // @[src/main/scala/plic/PlicCell.scala 24:20]
    end else begin
      idReg <= {{1'd0}, _GEN_1};
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  priorityReg = _RAND_0[2:0];
  _RAND_1 = {1{`RANDOM}};
  idReg = _RAND_1[3:0];
`endif // RANDOMIZE_REG_INIT
  if (asyncReset) begin
    priorityReg = 3'h0;
  end
  if (asyncReset) begin
    idReg = 4'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module PlicCell_6(
  input        clock,
  input        io_rst_n, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ip, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ie, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input  [2:0] io_priority, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [3:0] io_id, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [2:0] io_priorityOut // @[src/main/scala/plic/PlicCell.scala 18:14]
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  asyncReset = ~io_rst_n; // @[src/main/scala/plic/PlicCell.scala 20:32]
  reg [2:0] priorityReg; // @[src/main/scala/plic/PlicCell.scala 23:20]
  reg [3:0] idReg; // @[src/main/scala/plic/PlicCell.scala 24:20]
  wire [2:0] _GEN_1 = io_ip & io_ie ? 3'h7 : 3'h0; // @[src/main/scala/plic/PlicCell.scala 28:24 30:11 33:11]
  assign io_id = idReg; // @[src/main/scala/plic/PlicCell.scala 37:9]
  assign io_priorityOut = priorityReg; // @[src/main/scala/plic/PlicCell.scala 36:18]
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= 3'h0; // @[src/main/scala/plic/PlicCell.scala 29:17]
    end else if (io_ip & io_ie) begin // @[src/main/scala/plic/PlicCell.scala 32:17]
      priorityReg <= io_priority;
    end else begin
      priorityReg <= 3'h0;
    end
  end
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 24:20]
      idReg <= 4'h0; // @[src/main/scala/plic/PlicCell.scala 24:20]
    end else begin
      idReg <= {{1'd0}, _GEN_1};
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  priorityReg = _RAND_0[2:0];
  _RAND_1 = {1{`RANDOM}};
  idReg = _RAND_1[3:0];
`endif // RANDOMIZE_REG_INIT
  if (asyncReset) begin
    priorityReg = 3'h0;
  end
  if (asyncReset) begin
    idReg = 4'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module PlicCell_7(
  input        clock,
  input        io_rst_n, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ip, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input        io_ie, // @[src/main/scala/plic/PlicCell.scala 18:14]
  input  [2:0] io_priority, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [3:0] io_id, // @[src/main/scala/plic/PlicCell.scala 18:14]
  output [2:0] io_priorityOut // @[src/main/scala/plic/PlicCell.scala 18:14]
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  asyncReset = ~io_rst_n; // @[src/main/scala/plic/PlicCell.scala 20:32]
  reg [2:0] priorityReg; // @[src/main/scala/plic/PlicCell.scala 23:20]
  reg [3:0] idReg; // @[src/main/scala/plic/PlicCell.scala 24:20]
  assign io_id = idReg; // @[src/main/scala/plic/PlicCell.scala 37:9]
  assign io_priorityOut = priorityReg; // @[src/main/scala/plic/PlicCell.scala 36:18]
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= 3'h0; // @[src/main/scala/plic/PlicCell.scala 29:17]
    end else if (io_ip & io_ie) begin // @[src/main/scala/plic/PlicCell.scala 32:17]
      priorityReg <= io_priority;
    end else begin
      priorityReg <= 3'h0;
    end
  end
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCell.scala 28:24]
      idReg <= 4'h0; // @[src/main/scala/plic/PlicCell.scala 30:11]
    end else if (io_ip & io_ie) begin // @[src/main/scala/plic/PlicCell.scala 33:11]
      idReg <= 4'h8;
    end else begin
      idReg <= 4'h0;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  priorityReg = _RAND_0[2:0];
  _RAND_1 = {1{`RANDOM}};
  idReg = _RAND_1[3:0];
`endif // RANDOMIZE_REG_INIT
  if (asyncReset) begin
    priorityReg = 3'h0;
  end
  if (asyncReset) begin
    idReg = 4'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module PlicTarget(
  input        clock,
  input        io_rst_n, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [3:0] io_id_i_0, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [3:0] io_id_i_1, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [3:0] io_id_i_2, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [3:0] io_id_i_3, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [3:0] io_id_i_4, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [3:0] io_id_i_5, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [3:0] io_id_i_6, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [3:0] io_id_i_7, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [2:0] io_priority_i_0, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [2:0] io_priority_i_1, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [2:0] io_priority_i_2, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [2:0] io_priority_i_3, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [2:0] io_priority_i_4, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [2:0] io_priority_i_5, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [2:0] io_priority_i_6, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [2:0] io_priority_i_7, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  input  [2:0] io_threshold_i, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  output       io_ireq_o, // @[src/main/scala/plic/PlicTarget.scala 16:14]
  output [3:0] io_id_o // @[src/main/scala/plic/PlicTarget.scala 16:14]
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  asyncReset = ~io_rst_n; // @[src/main/scala/plic/PlicTarget.scala 17:32]
  wire  sel = io_priority_i_0 > 3'h0; // @[src/main/scala/plic/PlicTarget.scala 25:32]
  wire [2:0] nbp = sel ? io_priority_i_0 : 3'h0; // @[src/main/scala/plic/PlicTarget.scala 26:18]
  wire [3:0] nbi = sel ? io_id_i_0 : 4'h0; // @[src/main/scala/plic/PlicTarget.scala 27:18]
  wire  sel_1 = io_priority_i_1 > nbp; // @[src/main/scala/plic/PlicTarget.scala 25:32]
  wire [2:0] nbp_1 = sel_1 ? io_priority_i_1 : nbp; // @[src/main/scala/plic/PlicTarget.scala 26:18]
  wire [3:0] nbi_1 = sel_1 ? io_id_i_1 : nbi; // @[src/main/scala/plic/PlicTarget.scala 27:18]
  wire  sel_2 = io_priority_i_2 > nbp_1; // @[src/main/scala/plic/PlicTarget.scala 25:32]
  wire [2:0] nbp_2 = sel_2 ? io_priority_i_2 : nbp_1; // @[src/main/scala/plic/PlicTarget.scala 26:18]
  wire [3:0] nbi_2 = sel_2 ? io_id_i_2 : nbi_1; // @[src/main/scala/plic/PlicTarget.scala 27:18]
  wire  sel_3 = io_priority_i_3 > nbp_2; // @[src/main/scala/plic/PlicTarget.scala 25:32]
  wire [2:0] nbp_3 = sel_3 ? io_priority_i_3 : nbp_2; // @[src/main/scala/plic/PlicTarget.scala 26:18]
  wire [3:0] nbi_3 = sel_3 ? io_id_i_3 : nbi_2; // @[src/main/scala/plic/PlicTarget.scala 27:18]
  wire  sel_4 = io_priority_i_4 > nbp_3; // @[src/main/scala/plic/PlicTarget.scala 25:32]
  wire [2:0] nbp_4 = sel_4 ? io_priority_i_4 : nbp_3; // @[src/main/scala/plic/PlicTarget.scala 26:18]
  wire  sel_5 = io_priority_i_5 > nbp_4; // @[src/main/scala/plic/PlicTarget.scala 25:32]
  wire [2:0] nbp_5 = sel_5 ? io_priority_i_5 : nbp_4; // @[src/main/scala/plic/PlicTarget.scala 26:18]
  wire  sel_6 = io_priority_i_6 > nbp_5; // @[src/main/scala/plic/PlicTarget.scala 25:32]
  wire [2:0] nbp_6 = sel_6 ? io_priority_i_6 : nbp_5; // @[src/main/scala/plic/PlicTarget.scala 26:18]
  wire  sel_7 = io_priority_i_7 > nbp_6; // @[src/main/scala/plic/PlicTarget.scala 25:32]
  wire [2:0] bestP = sel_7 ? io_priority_i_7 : nbp_6; // @[src/main/scala/plic/PlicTarget.scala 26:18]
  reg  ireq_reg; // @[src/main/scala/plic/PlicTarget.scala 31:49]
  reg [3:0] id_reg; // @[src/main/scala/plic/PlicTarget.scala 32:47]
  assign io_ireq_o = ireq_reg; // @[src/main/scala/plic/PlicTarget.scala 37:13]
  assign io_id_o = id_reg; // @[src/main/scala/plic/PlicTarget.scala 38:11]
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicTarget.scala 34:14]
      ireq_reg <= 1'h0;
    end else begin
      ireq_reg <= bestP > io_threshold_i;
    end
  end
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicTarget.scala 27:18]
      id_reg <= 4'h0;
    end else if (sel_7) begin // @[src/main/scala/plic/PlicTarget.scala 27:18]
      id_reg <= io_id_i_7;
    end else if (sel_6) begin // @[src/main/scala/plic/PlicTarget.scala 27:18]
      id_reg <= io_id_i_6;
    end else if (sel_5) begin // @[src/main/scala/plic/PlicTarget.scala 27:18]
      id_reg <= io_id_i_5;
    end else if (sel_4) begin
      id_reg <= io_id_i_4;
    end else begin
      id_reg <= nbi_3;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  ireq_reg = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  id_reg = _RAND_1[3:0];
`endif // RANDOMIZE_REG_INIT
  if (asyncReset) begin
    ireq_reg = 1'h0;
  end
  if (asyncReset) begin
    id_reg = 4'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module PlicCore(
  input        clock,
  input        reset,
  input        io_rst_n, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_src_0, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_src_1, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_src_2, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_src_3, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_src_4, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_src_5, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_src_6, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_src_7, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_el_0, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_el_1, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_el_2, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_el_3, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_el_4, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_el_5, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_el_6, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_el_7, // @[src/main/scala/plic/PlicCore.scala 24:14]
  output       io_ip_0, // @[src/main/scala/plic/PlicCore.scala 24:14]
  output       io_ip_1, // @[src/main/scala/plic/PlicCore.scala 24:14]
  output       io_ip_2, // @[src/main/scala/plic/PlicCore.scala 24:14]
  output       io_ip_3, // @[src/main/scala/plic/PlicCore.scala 24:14]
  output       io_ip_4, // @[src/main/scala/plic/PlicCore.scala 24:14]
  output       io_ip_5, // @[src/main/scala/plic/PlicCore.scala 24:14]
  output       io_ip_6, // @[src/main/scala/plic/PlicCore.scala 24:14]
  output       io_ip_7, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_ie_0_0, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_ie_0_1, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_ie_0_2, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_ie_0_3, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_ie_0_4, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_ie_0_5, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_ie_0_6, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_ie_0_7, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input  [2:0] io_ipriority_0, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input  [2:0] io_ipriority_1, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input  [2:0] io_ipriority_2, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input  [2:0] io_ipriority_3, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input  [2:0] io_ipriority_4, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input  [2:0] io_ipriority_5, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input  [2:0] io_ipriority_6, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input  [2:0] io_ipriority_7, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input  [2:0] io_threshold_0, // @[src/main/scala/plic/PlicCore.scala 24:14]
  output       io_ireq_0, // @[src/main/scala/plic/PlicCore.scala 24:14]
  output [3:0] io_id_0, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_claim_0, // @[src/main/scala/plic/PlicCore.scala 24:14]
  input        io_complete_0 // @[src/main/scala/plic/PlicCore.scala 24:14]
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_REG_INIT
  wire  gateways_0_clock; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_0_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_0_io_src; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_0_io_edge_lvl; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_0_io_ip; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_0_io_claim; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_0_io_complete; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_1_clock; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_1_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_1_io_src; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_1_io_edge_lvl; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_1_io_ip; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_1_io_claim; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_1_io_complete; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_2_clock; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_2_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_2_io_src; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_2_io_edge_lvl; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_2_io_ip; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_2_io_claim; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_2_io_complete; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_3_clock; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_3_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_3_io_src; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_3_io_edge_lvl; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_3_io_ip; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_3_io_claim; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_3_io_complete; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_4_clock; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_4_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_4_io_src; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_4_io_edge_lvl; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_4_io_ip; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_4_io_claim; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_4_io_complete; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_5_clock; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_5_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_5_io_src; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_5_io_edge_lvl; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_5_io_ip; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_5_io_claim; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_5_io_complete; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_6_clock; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_6_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_6_io_src; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_6_io_edge_lvl; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_6_io_ip; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_6_io_claim; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_6_io_complete; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_7_clock; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_7_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_7_io_src; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_7_io_edge_lvl; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_7_io_ip; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_7_io_claim; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  gateways_7_io_complete; // @[src/main/scala/plic/PlicCore.scala 39:42]
  wire  cell__clock; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell__io_rst_n; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell__io_ip; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell__io_ie; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell__io_priority; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [3:0] cell__io_id; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell__io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_1_clock; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_1_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_1_io_ip; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_1_io_ie; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell_1_io_priority; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [3:0] cell_1_io_id; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell_1_io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_2_clock; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_2_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_2_io_ip; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_2_io_ie; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell_2_io_priority; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [3:0] cell_2_io_id; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell_2_io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_3_clock; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_3_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_3_io_ip; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_3_io_ie; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell_3_io_priority; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [3:0] cell_3_io_id; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell_3_io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_4_clock; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_4_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_4_io_ip; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_4_io_ie; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell_4_io_priority; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [3:0] cell_4_io_id; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell_4_io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_5_clock; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_5_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_5_io_ip; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_5_io_ie; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell_5_io_priority; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [3:0] cell_5_io_id; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell_5_io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_6_clock; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_6_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_6_io_ip; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_6_io_ie; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell_6_io_priority; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [3:0] cell_6_io_id; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell_6_io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_7_clock; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_7_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_7_io_ip; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  cell_7_io_ie; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell_7_io_priority; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [3:0] cell_7_io_id; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire [2:0] cell_7_io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 49:24]
  wire  tgt_clock; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire  tgt_io_rst_n; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [3:0] tgt_io_id_i_0; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [3:0] tgt_io_id_i_1; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [3:0] tgt_io_id_i_2; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [3:0] tgt_io_id_i_3; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [3:0] tgt_io_id_i_4; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [3:0] tgt_io_id_i_5; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [3:0] tgt_io_id_i_6; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [3:0] tgt_io_id_i_7; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [2:0] tgt_io_priority_i_0; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [2:0] tgt_io_priority_i_1; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [2:0] tgt_io_priority_i_2; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [2:0] tgt_io_priority_i_3; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [2:0] tgt_io_priority_i_4; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [2:0] tgt_io_priority_i_5; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [2:0] tgt_io_priority_i_6; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [2:0] tgt_io_priority_i_7; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [2:0] tgt_io_threshold_i; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire  tgt_io_ireq_o; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire [3:0] tgt_io_id_o; // @[src/main/scala/plic/PlicCore.scala 83:21]
  wire  asyncReset = ~io_rst_n; // @[src/main/scala/plic/PlicCore.scala 25:32]
  reg [3:0] id_claimed_0; // @[src/main/scala/plic/PlicCore.scala 32:51]
  wire  claim_array_0_0 = io_id_0 == 4'h1 & io_claim_0; // @[src/main/scala/plic/PlicCore.scala 69:53]
  wire  complete_array_0_0 = id_claimed_0 == 4'h1 & io_complete_0; // @[src/main/scala/plic/PlicCore.scala 70:61]
  wire  claim_array_1_0 = io_id_0 == 4'h2 & io_claim_0; // @[src/main/scala/plic/PlicCore.scala 69:53]
  wire  complete_array_1_0 = id_claimed_0 == 4'h2 & io_complete_0; // @[src/main/scala/plic/PlicCore.scala 70:61]
  wire  claim_array_2_0 = io_id_0 == 4'h3 & io_claim_0; // @[src/main/scala/plic/PlicCore.scala 69:53]
  wire  complete_array_2_0 = id_claimed_0 == 4'h3 & io_complete_0; // @[src/main/scala/plic/PlicCore.scala 70:61]
  wire  claim_array_3_0 = io_id_0 == 4'h4 & io_claim_0; // @[src/main/scala/plic/PlicCore.scala 69:53]
  wire  complete_array_3_0 = id_claimed_0 == 4'h4 & io_complete_0; // @[src/main/scala/plic/PlicCore.scala 70:61]
  wire  claim_array_4_0 = io_id_0 == 4'h5 & io_claim_0; // @[src/main/scala/plic/PlicCore.scala 69:53]
  wire  complete_array_4_0 = id_claimed_0 == 4'h5 & io_complete_0; // @[src/main/scala/plic/PlicCore.scala 70:61]
  wire  claim_array_5_0 = io_id_0 == 4'h6 & io_claim_0; // @[src/main/scala/plic/PlicCore.scala 69:53]
  wire  complete_array_5_0 = id_claimed_0 == 4'h6 & io_complete_0; // @[src/main/scala/plic/PlicCore.scala 70:61]
  wire  claim_array_6_0 = io_id_0 == 4'h7 & io_claim_0; // @[src/main/scala/plic/PlicCore.scala 69:53]
  wire  complete_array_6_0 = id_claimed_0 == 4'h7 & io_complete_0; // @[src/main/scala/plic/PlicCore.scala 70:61]
  wire  claim_array_7_0 = io_id_0 == 4'h8 & io_claim_0; // @[src/main/scala/plic/PlicCore.scala 69:53]
  wire  complete_array_7_0 = id_claimed_0 == 4'h8 & io_complete_0; // @[src/main/scala/plic/PlicCore.scala 70:61]
  PlicGateway gateways_0 ( // @[src/main/scala/plic/PlicCore.scala 39:42]
    .clock(gateways_0_clock),
    .io_rst_n(gateways_0_io_rst_n),
    .io_src(gateways_0_io_src),
    .io_edge_lvl(gateways_0_io_edge_lvl),
    .io_ip(gateways_0_io_ip),
    .io_claim(gateways_0_io_claim),
    .io_complete(gateways_0_io_complete)
  );
  PlicGateway gateways_1 ( // @[src/main/scala/plic/PlicCore.scala 39:42]
    .clock(gateways_1_clock),
    .io_rst_n(gateways_1_io_rst_n),
    .io_src(gateways_1_io_src),
    .io_edge_lvl(gateways_1_io_edge_lvl),
    .io_ip(gateways_1_io_ip),
    .io_claim(gateways_1_io_claim),
    .io_complete(gateways_1_io_complete)
  );
  PlicGateway gateways_2 ( // @[src/main/scala/plic/PlicCore.scala 39:42]
    .clock(gateways_2_clock),
    .io_rst_n(gateways_2_io_rst_n),
    .io_src(gateways_2_io_src),
    .io_edge_lvl(gateways_2_io_edge_lvl),
    .io_ip(gateways_2_io_ip),
    .io_claim(gateways_2_io_claim),
    .io_complete(gateways_2_io_complete)
  );
  PlicGateway gateways_3 ( // @[src/main/scala/plic/PlicCore.scala 39:42]
    .clock(gateways_3_clock),
    .io_rst_n(gateways_3_io_rst_n),
    .io_src(gateways_3_io_src),
    .io_edge_lvl(gateways_3_io_edge_lvl),
    .io_ip(gateways_3_io_ip),
    .io_claim(gateways_3_io_claim),
    .io_complete(gateways_3_io_complete)
  );
  PlicGateway gateways_4 ( // @[src/main/scala/plic/PlicCore.scala 39:42]
    .clock(gateways_4_clock),
    .io_rst_n(gateways_4_io_rst_n),
    .io_src(gateways_4_io_src),
    .io_edge_lvl(gateways_4_io_edge_lvl),
    .io_ip(gateways_4_io_ip),
    .io_claim(gateways_4_io_claim),
    .io_complete(gateways_4_io_complete)
  );
  PlicGateway gateways_5 ( // @[src/main/scala/plic/PlicCore.scala 39:42]
    .clock(gateways_5_clock),
    .io_rst_n(gateways_5_io_rst_n),
    .io_src(gateways_5_io_src),
    .io_edge_lvl(gateways_5_io_edge_lvl),
    .io_ip(gateways_5_io_ip),
    .io_claim(gateways_5_io_claim),
    .io_complete(gateways_5_io_complete)
  );
  PlicGateway gateways_6 ( // @[src/main/scala/plic/PlicCore.scala 39:42]
    .clock(gateways_6_clock),
    .io_rst_n(gateways_6_io_rst_n),
    .io_src(gateways_6_io_src),
    .io_edge_lvl(gateways_6_io_edge_lvl),
    .io_ip(gateways_6_io_ip),
    .io_claim(gateways_6_io_claim),
    .io_complete(gateways_6_io_complete)
  );
  PlicGateway gateways_7 ( // @[src/main/scala/plic/PlicCore.scala 39:42]
    .clock(gateways_7_clock),
    .io_rst_n(gateways_7_io_rst_n),
    .io_src(gateways_7_io_src),
    .io_edge_lvl(gateways_7_io_edge_lvl),
    .io_ip(gateways_7_io_ip),
    .io_claim(gateways_7_io_claim),
    .io_complete(gateways_7_io_complete)
  );
  PlicCell cell_ ( // @[src/main/scala/plic/PlicCore.scala 49:24]
    .clock(cell__clock),
    .io_rst_n(cell__io_rst_n),
    .io_ip(cell__io_ip),
    .io_ie(cell__io_ie),
    .io_priority(cell__io_priority),
    .io_id(cell__io_id),
    .io_priorityOut(cell__io_priorityOut)
  );
  PlicCell_1 cell_1 ( // @[src/main/scala/plic/PlicCore.scala 49:24]
    .clock(cell_1_clock),
    .io_rst_n(cell_1_io_rst_n),
    .io_ip(cell_1_io_ip),
    .io_ie(cell_1_io_ie),
    .io_priority(cell_1_io_priority),
    .io_id(cell_1_io_id),
    .io_priorityOut(cell_1_io_priorityOut)
  );
  PlicCell_2 cell_2 ( // @[src/main/scala/plic/PlicCore.scala 49:24]
    .clock(cell_2_clock),
    .io_rst_n(cell_2_io_rst_n),
    .io_ip(cell_2_io_ip),
    .io_ie(cell_2_io_ie),
    .io_priority(cell_2_io_priority),
    .io_id(cell_2_io_id),
    .io_priorityOut(cell_2_io_priorityOut)
  );
  PlicCell_3 cell_3 ( // @[src/main/scala/plic/PlicCore.scala 49:24]
    .clock(cell_3_clock),
    .io_rst_n(cell_3_io_rst_n),
    .io_ip(cell_3_io_ip),
    .io_ie(cell_3_io_ie),
    .io_priority(cell_3_io_priority),
    .io_id(cell_3_io_id),
    .io_priorityOut(cell_3_io_priorityOut)
  );
  PlicCell_4 cell_4 ( // @[src/main/scala/plic/PlicCore.scala 49:24]
    .clock(cell_4_clock),
    .io_rst_n(cell_4_io_rst_n),
    .io_ip(cell_4_io_ip),
    .io_ie(cell_4_io_ie),
    .io_priority(cell_4_io_priority),
    .io_id(cell_4_io_id),
    .io_priorityOut(cell_4_io_priorityOut)
  );
  PlicCell_5 cell_5 ( // @[src/main/scala/plic/PlicCore.scala 49:24]
    .clock(cell_5_clock),
    .io_rst_n(cell_5_io_rst_n),
    .io_ip(cell_5_io_ip),
    .io_ie(cell_5_io_ie),
    .io_priority(cell_5_io_priority),
    .io_id(cell_5_io_id),
    .io_priorityOut(cell_5_io_priorityOut)
  );
  PlicCell_6 cell_6 ( // @[src/main/scala/plic/PlicCore.scala 49:24]
    .clock(cell_6_clock),
    .io_rst_n(cell_6_io_rst_n),
    .io_ip(cell_6_io_ip),
    .io_ie(cell_6_io_ie),
    .io_priority(cell_6_io_priority),
    .io_id(cell_6_io_id),
    .io_priorityOut(cell_6_io_priorityOut)
  );
  PlicCell_7 cell_7 ( // @[src/main/scala/plic/PlicCore.scala 49:24]
    .clock(cell_7_clock),
    .io_rst_n(cell_7_io_rst_n),
    .io_ip(cell_7_io_ip),
    .io_ie(cell_7_io_ie),
    .io_priority(cell_7_io_priority),
    .io_id(cell_7_io_id),
    .io_priorityOut(cell_7_io_priorityOut)
  );
  PlicTarget tgt ( // @[src/main/scala/plic/PlicCore.scala 83:21]
    .clock(tgt_clock),
    .io_rst_n(tgt_io_rst_n),
    .io_id_i_0(tgt_io_id_i_0),
    .io_id_i_1(tgt_io_id_i_1),
    .io_id_i_2(tgt_io_id_i_2),
    .io_id_i_3(tgt_io_id_i_3),
    .io_id_i_4(tgt_io_id_i_4),
    .io_id_i_5(tgt_io_id_i_5),
    .io_id_i_6(tgt_io_id_i_6),
    .io_id_i_7(tgt_io_id_i_7),
    .io_priority_i_0(tgt_io_priority_i_0),
    .io_priority_i_1(tgt_io_priority_i_1),
    .io_priority_i_2(tgt_io_priority_i_2),
    .io_priority_i_3(tgt_io_priority_i_3),
    .io_priority_i_4(tgt_io_priority_i_4),
    .io_priority_i_5(tgt_io_priority_i_5),
    .io_priority_i_6(tgt_io_priority_i_6),
    .io_priority_i_7(tgt_io_priority_i_7),
    .io_threshold_i(tgt_io_threshold_i),
    .io_ireq_o(tgt_io_ireq_o),
    .io_id_o(tgt_io_id_o)
  );
  assign io_ip_0 = gateways_0_io_ip; // @[src/main/scala/plic/PlicCore.scala 78:14]
  assign io_ip_1 = gateways_1_io_ip; // @[src/main/scala/plic/PlicCore.scala 78:14]
  assign io_ip_2 = gateways_2_io_ip; // @[src/main/scala/plic/PlicCore.scala 78:14]
  assign io_ip_3 = gateways_3_io_ip; // @[src/main/scala/plic/PlicCore.scala 78:14]
  assign io_ip_4 = gateways_4_io_ip; // @[src/main/scala/plic/PlicCore.scala 78:14]
  assign io_ip_5 = gateways_5_io_ip; // @[src/main/scala/plic/PlicCore.scala 78:14]
  assign io_ip_6 = gateways_6_io_ip; // @[src/main/scala/plic/PlicCore.scala 78:14]
  assign io_ip_7 = gateways_7_io_ip; // @[src/main/scala/plic/PlicCore.scala 78:14]
  assign io_ireq_0 = tgt_io_ireq_o; // @[src/main/scala/plic/PlicCore.scala 91:16]
  assign io_id_0 = tgt_io_id_o; // @[src/main/scala/plic/PlicCore.scala 92:14]
  assign gateways_0_clock = clock;
  assign gateways_0_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 41:26]
  assign gateways_0_io_src = io_src_0; // @[src/main/scala/plic/PlicCore.scala 42:24]
  assign gateways_0_io_edge_lvl = io_el_0; // @[src/main/scala/plic/PlicCore.scala 43:29]
  assign gateways_0_io_claim = |claim_array_0_0; // @[src/main/scala/plic/PlicCore.scala 76:51]
  assign gateways_0_io_complete = |complete_array_0_0; // @[src/main/scala/plic/PlicCore.scala 77:57]
  assign gateways_1_clock = clock;
  assign gateways_1_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 41:26]
  assign gateways_1_io_src = io_src_1; // @[src/main/scala/plic/PlicCore.scala 42:24]
  assign gateways_1_io_edge_lvl = io_el_1; // @[src/main/scala/plic/PlicCore.scala 43:29]
  assign gateways_1_io_claim = |claim_array_1_0; // @[src/main/scala/plic/PlicCore.scala 76:51]
  assign gateways_1_io_complete = |complete_array_1_0; // @[src/main/scala/plic/PlicCore.scala 77:57]
  assign gateways_2_clock = clock;
  assign gateways_2_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 41:26]
  assign gateways_2_io_src = io_src_2; // @[src/main/scala/plic/PlicCore.scala 42:24]
  assign gateways_2_io_edge_lvl = io_el_2; // @[src/main/scala/plic/PlicCore.scala 43:29]
  assign gateways_2_io_claim = |claim_array_2_0; // @[src/main/scala/plic/PlicCore.scala 76:51]
  assign gateways_2_io_complete = |complete_array_2_0; // @[src/main/scala/plic/PlicCore.scala 77:57]
  assign gateways_3_clock = clock;
  assign gateways_3_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 41:26]
  assign gateways_3_io_src = io_src_3; // @[src/main/scala/plic/PlicCore.scala 42:24]
  assign gateways_3_io_edge_lvl = io_el_3; // @[src/main/scala/plic/PlicCore.scala 43:29]
  assign gateways_3_io_claim = |claim_array_3_0; // @[src/main/scala/plic/PlicCore.scala 76:51]
  assign gateways_3_io_complete = |complete_array_3_0; // @[src/main/scala/plic/PlicCore.scala 77:57]
  assign gateways_4_clock = clock;
  assign gateways_4_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 41:26]
  assign gateways_4_io_src = io_src_4; // @[src/main/scala/plic/PlicCore.scala 42:24]
  assign gateways_4_io_edge_lvl = io_el_4; // @[src/main/scala/plic/PlicCore.scala 43:29]
  assign gateways_4_io_claim = |claim_array_4_0; // @[src/main/scala/plic/PlicCore.scala 76:51]
  assign gateways_4_io_complete = |complete_array_4_0; // @[src/main/scala/plic/PlicCore.scala 77:57]
  assign gateways_5_clock = clock;
  assign gateways_5_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 41:26]
  assign gateways_5_io_src = io_src_5; // @[src/main/scala/plic/PlicCore.scala 42:24]
  assign gateways_5_io_edge_lvl = io_el_5; // @[src/main/scala/plic/PlicCore.scala 43:29]
  assign gateways_5_io_claim = |claim_array_5_0; // @[src/main/scala/plic/PlicCore.scala 76:51]
  assign gateways_5_io_complete = |complete_array_5_0; // @[src/main/scala/plic/PlicCore.scala 77:57]
  assign gateways_6_clock = clock;
  assign gateways_6_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 41:26]
  assign gateways_6_io_src = io_src_6; // @[src/main/scala/plic/PlicCore.scala 42:24]
  assign gateways_6_io_edge_lvl = io_el_6; // @[src/main/scala/plic/PlicCore.scala 43:29]
  assign gateways_6_io_claim = |claim_array_6_0; // @[src/main/scala/plic/PlicCore.scala 76:51]
  assign gateways_6_io_complete = |complete_array_6_0; // @[src/main/scala/plic/PlicCore.scala 77:57]
  assign gateways_7_clock = clock;
  assign gateways_7_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 41:26]
  assign gateways_7_io_src = io_src_7; // @[src/main/scala/plic/PlicCore.scala 42:24]
  assign gateways_7_io_edge_lvl = io_el_7; // @[src/main/scala/plic/PlicCore.scala 43:29]
  assign gateways_7_io_claim = |claim_array_7_0; // @[src/main/scala/plic/PlicCore.scala 76:51]
  assign gateways_7_io_complete = |complete_array_7_0; // @[src/main/scala/plic/PlicCore.scala 77:57]
  assign cell__clock = clock;
  assign cell__io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 50:21]
  assign cell__io_ip = gateways_0_io_ip; // @[src/main/scala/plic/PlicCore.scala 51:18]
  assign cell__io_ie = io_ie_0_0; // @[src/main/scala/plic/PlicCore.scala 52:18]
  assign cell__io_priority = io_ipriority_0; // @[src/main/scala/plic/PlicCore.scala 53:24]
  assign cell_1_clock = clock;
  assign cell_1_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 50:21]
  assign cell_1_io_ip = gateways_1_io_ip; // @[src/main/scala/plic/PlicCore.scala 51:18]
  assign cell_1_io_ie = io_ie_0_1; // @[src/main/scala/plic/PlicCore.scala 52:18]
  assign cell_1_io_priority = io_ipriority_1; // @[src/main/scala/plic/PlicCore.scala 53:24]
  assign cell_2_clock = clock;
  assign cell_2_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 50:21]
  assign cell_2_io_ip = gateways_2_io_ip; // @[src/main/scala/plic/PlicCore.scala 51:18]
  assign cell_2_io_ie = io_ie_0_2; // @[src/main/scala/plic/PlicCore.scala 52:18]
  assign cell_2_io_priority = io_ipriority_2; // @[src/main/scala/plic/PlicCore.scala 53:24]
  assign cell_3_clock = clock;
  assign cell_3_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 50:21]
  assign cell_3_io_ip = gateways_3_io_ip; // @[src/main/scala/plic/PlicCore.scala 51:18]
  assign cell_3_io_ie = io_ie_0_3; // @[src/main/scala/plic/PlicCore.scala 52:18]
  assign cell_3_io_priority = io_ipriority_3; // @[src/main/scala/plic/PlicCore.scala 53:24]
  assign cell_4_clock = clock;
  assign cell_4_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 50:21]
  assign cell_4_io_ip = gateways_4_io_ip; // @[src/main/scala/plic/PlicCore.scala 51:18]
  assign cell_4_io_ie = io_ie_0_4; // @[src/main/scala/plic/PlicCore.scala 52:18]
  assign cell_4_io_priority = io_ipriority_4; // @[src/main/scala/plic/PlicCore.scala 53:24]
  assign cell_5_clock = clock;
  assign cell_5_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 50:21]
  assign cell_5_io_ip = gateways_5_io_ip; // @[src/main/scala/plic/PlicCore.scala 51:18]
  assign cell_5_io_ie = io_ie_0_5; // @[src/main/scala/plic/PlicCore.scala 52:18]
  assign cell_5_io_priority = io_ipriority_5; // @[src/main/scala/plic/PlicCore.scala 53:24]
  assign cell_6_clock = clock;
  assign cell_6_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 50:21]
  assign cell_6_io_ip = gateways_6_io_ip; // @[src/main/scala/plic/PlicCore.scala 51:18]
  assign cell_6_io_ie = io_ie_0_6; // @[src/main/scala/plic/PlicCore.scala 52:18]
  assign cell_6_io_priority = io_ipriority_6; // @[src/main/scala/plic/PlicCore.scala 53:24]
  assign cell_7_clock = clock;
  assign cell_7_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 50:21]
  assign cell_7_io_ip = gateways_7_io_ip; // @[src/main/scala/plic/PlicCore.scala 51:18]
  assign cell_7_io_ie = io_ie_0_7; // @[src/main/scala/plic/PlicCore.scala 52:18]
  assign cell_7_io_priority = io_ipriority_7; // @[src/main/scala/plic/PlicCore.scala 53:24]
  assign tgt_clock = clock;
  assign tgt_io_rst_n = io_rst_n; // @[src/main/scala/plic/PlicCore.scala 84:18]
  assign tgt_io_id_i_0 = cell__io_id; // @[src/main/scala/plic/PlicCore.scala 28:58 54:22]
  assign tgt_io_id_i_1 = cell_1_io_id; // @[src/main/scala/plic/PlicCore.scala 28:58 54:22]
  assign tgt_io_id_i_2 = cell_2_io_id; // @[src/main/scala/plic/PlicCore.scala 28:58 54:22]
  assign tgt_io_id_i_3 = cell_3_io_id; // @[src/main/scala/plic/PlicCore.scala 28:58 54:22]
  assign tgt_io_id_i_4 = cell_4_io_id; // @[src/main/scala/plic/PlicCore.scala 28:58 54:22]
  assign tgt_io_id_i_5 = cell_5_io_id; // @[src/main/scala/plic/PlicCore.scala 28:58 54:22]
  assign tgt_io_id_i_6 = cell_6_io_id; // @[src/main/scala/plic/PlicCore.scala 28:58 54:22]
  assign tgt_io_id_i_7 = cell_7_io_id; // @[src/main/scala/plic/PlicCore.scala 28:58 54:22]
  assign tgt_io_priority_i_0 = cell__io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 29:58 55:22]
  assign tgt_io_priority_i_1 = cell_1_io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 29:58 55:22]
  assign tgt_io_priority_i_2 = cell_2_io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 29:58 55:22]
  assign tgt_io_priority_i_3 = cell_3_io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 29:58 55:22]
  assign tgt_io_priority_i_4 = cell_4_io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 29:58 55:22]
  assign tgt_io_priority_i_5 = cell_5_io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 29:58 55:22]
  assign tgt_io_priority_i_6 = cell_6_io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 29:58 55:22]
  assign tgt_io_priority_i_7 = cell_7_io_priorityOut; // @[src/main/scala/plic/PlicCore.scala 29:58 55:22]
  assign tgt_io_threshold_i = io_threshold_0; // @[src/main/scala/plic/PlicCore.scala 90:24]
  always @(posedge clock or posedge asyncReset) begin
    if (asyncReset) begin // @[src/main/scala/plic/PlicCore.scala 61:23]
      id_claimed_0 <= 4'h0; // @[src/main/scala/plic/PlicCore.scala 62:21]
    end else if (io_claim_0) begin // @[src/main/scala/plic/PlicCore.scala 32:51]
      id_claimed_0 <= io_id_0;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  id_claimed_0 = _RAND_0[3:0];
`endif // RANDOMIZE_REG_INIT
  if (asyncReset) begin
    id_claimed_0 = 4'h0;
  end
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
