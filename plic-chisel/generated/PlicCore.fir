FIRRTL version 1.2.0
circuit PlicCore :
  module PlicGateway :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip src : UInt<1>, flip edge_lvl : UInt<1>, ip : UInt<1>, flip claim : UInt<1>, flip complete : UInt<1>} @[src/main/scala/plic/PlicGateway.scala 17:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 19:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicGateway.scala 19:32]
    reg src_dly : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 22:21]
    reg src_edge : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 23:21]
    reg pending_cnt : UInt<5>, clock with :
      reset => (asyncReset, UInt<5>("h0")) @[src/main/scala/plic/PlicGateway.scala 24:21]
    reg decr_pending : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 25:21]
    reg ip_state : UInt<2>, clock with :
      reset => (asyncReset, UInt<2>("h0")) @[src/main/scala/plic/PlicGateway.scala 27:21]
    wire nxt_pending_cnt : UInt<5> @[src/main/scala/plic/PlicGateway.scala 31:29]
    src_dly <= io.src @[src/main/scala/plic/PlicGateway.scala 34:11]
    node _src_edge_T = eq(src_dly, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 35:25]
    node _src_edge_T_1 = and(io.src, _src_edge_T) @[src/main/scala/plic/PlicGateway.scala 35:22]
    src_edge <= _src_edge_T_1 @[src/main/scala/plic/PlicGateway.scala 35:12]
    node _T = eq(src_edge, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 38:24]
    node _T_1 = and(decr_pending, _T) @[src/main/scala/plic/PlicGateway.scala 38:21]
    when _T_1 : @[src/main/scala/plic/PlicGateway.scala 38:35]
      node _T_2 = gt(pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 39:22]
      when _T_2 : @[src/main/scala/plic/PlicGateway.scala 39:29]
        node _nxt_pending_cnt_T = sub(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 39:62]
        node _nxt_pending_cnt_T_1 = tail(_nxt_pending_cnt_T, 1) @[src/main/scala/plic/PlicGateway.scala 39:62]
        nxt_pending_cnt <= _nxt_pending_cnt_T_1 @[src/main/scala/plic/PlicGateway.scala 39:47]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 40:34]
    else :
      node _T_3 = eq(decr_pending, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 41:15]
      node _T_4 = and(_T_3, src_edge) @[src/main/scala/plic/PlicGateway.scala 41:29]
      when _T_4 : @[src/main/scala/plic/PlicGateway.scala 41:42]
        node _T_5 = lt(pending_cnt, UInt<5>("h10")) @[src/main/scala/plic/PlicGateway.scala 42:22]
        when _T_5 : @[src/main/scala/plic/PlicGateway.scala 42:43]
          node _nxt_pending_cnt_T_2 = add(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 42:76]
          node _nxt_pending_cnt_T_3 = tail(_nxt_pending_cnt_T_2, 1) @[src/main/scala/plic/PlicGateway.scala 42:76]
          nxt_pending_cnt <= _nxt_pending_cnt_T_3 @[src/main/scala/plic/PlicGateway.scala 42:61]
        else :
          nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 43:34]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 45:21]
    node _T_6 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 48:8]
    when _T_6 : @[src/main/scala/plic/PlicGateway.scala 48:22]
      pending_cnt <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 49:17]
    else :
      pending_cnt <= nxt_pending_cnt @[src/main/scala/plic/PlicGateway.scala 51:17]
    decr_pending <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 55:16]
    node _T_7 = eq(UInt<1>("h0"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
    when _T_7 : @[src/main/scala/plic/PlicGateway.scala 56:20]
      node _T_8 = neq(nxt_pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:45]
      node _T_9 = and(io.edge_lvl, _T_8) @[src/main/scala/plic/PlicGateway.scala 58:25]
      node _T_10 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:59]
      node _T_11 = and(_T_10, io.src) @[src/main/scala/plic/PlicGateway.scala 58:72]
      node _T_12 = or(_T_9, _T_11) @[src/main/scala/plic/PlicGateway.scala 58:55]
      when _T_12 : @[src/main/scala/plic/PlicGateway.scala 58:84]
        ip_state <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 59:18]
        decr_pending <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 60:22]
    else :
      node _T_13 = eq(UInt<1>("h1"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
      when _T_13 : @[src/main/scala/plic/PlicGateway.scala 56:20]
        when io.claim : @[src/main/scala/plic/PlicGateway.scala 64:22]
          ip_state <= UInt<2>("h2") @[src/main/scala/plic/PlicGateway.scala 64:33]
      else :
        node _T_14 = eq(UInt<2>("h2"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
        when _T_14 : @[src/main/scala/plic/PlicGateway.scala 56:20]
          when io.complete : @[src/main/scala/plic/PlicGateway.scala 67:25]
            ip_state <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 67:36]
    node _io_ip_T = eq(ip_state, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 71:21]
    io.ip <= _io_ip_T @[src/main/scala/plic/PlicGateway.scala 71:9]

  module PlicGateway_1 :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip src : UInt<1>, flip edge_lvl : UInt<1>, ip : UInt<1>, flip claim : UInt<1>, flip complete : UInt<1>} @[src/main/scala/plic/PlicGateway.scala 17:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 19:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicGateway.scala 19:32]
    reg src_dly : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 22:21]
    reg src_edge : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 23:21]
    reg pending_cnt : UInt<5>, clock with :
      reset => (asyncReset, UInt<5>("h0")) @[src/main/scala/plic/PlicGateway.scala 24:21]
    reg decr_pending : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 25:21]
    reg ip_state : UInt<2>, clock with :
      reset => (asyncReset, UInt<2>("h0")) @[src/main/scala/plic/PlicGateway.scala 27:21]
    wire nxt_pending_cnt : UInt<5> @[src/main/scala/plic/PlicGateway.scala 31:29]
    src_dly <= io.src @[src/main/scala/plic/PlicGateway.scala 34:11]
    node _src_edge_T = eq(src_dly, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 35:25]
    node _src_edge_T_1 = and(io.src, _src_edge_T) @[src/main/scala/plic/PlicGateway.scala 35:22]
    src_edge <= _src_edge_T_1 @[src/main/scala/plic/PlicGateway.scala 35:12]
    node _T = eq(src_edge, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 38:24]
    node _T_1 = and(decr_pending, _T) @[src/main/scala/plic/PlicGateway.scala 38:21]
    when _T_1 : @[src/main/scala/plic/PlicGateway.scala 38:35]
      node _T_2 = gt(pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 39:22]
      when _T_2 : @[src/main/scala/plic/PlicGateway.scala 39:29]
        node _nxt_pending_cnt_T = sub(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 39:62]
        node _nxt_pending_cnt_T_1 = tail(_nxt_pending_cnt_T, 1) @[src/main/scala/plic/PlicGateway.scala 39:62]
        nxt_pending_cnt <= _nxt_pending_cnt_T_1 @[src/main/scala/plic/PlicGateway.scala 39:47]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 40:34]
    else :
      node _T_3 = eq(decr_pending, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 41:15]
      node _T_4 = and(_T_3, src_edge) @[src/main/scala/plic/PlicGateway.scala 41:29]
      when _T_4 : @[src/main/scala/plic/PlicGateway.scala 41:42]
        node _T_5 = lt(pending_cnt, UInt<5>("h10")) @[src/main/scala/plic/PlicGateway.scala 42:22]
        when _T_5 : @[src/main/scala/plic/PlicGateway.scala 42:43]
          node _nxt_pending_cnt_T_2 = add(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 42:76]
          node _nxt_pending_cnt_T_3 = tail(_nxt_pending_cnt_T_2, 1) @[src/main/scala/plic/PlicGateway.scala 42:76]
          nxt_pending_cnt <= _nxt_pending_cnt_T_3 @[src/main/scala/plic/PlicGateway.scala 42:61]
        else :
          nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 43:34]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 45:21]
    node _T_6 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 48:8]
    when _T_6 : @[src/main/scala/plic/PlicGateway.scala 48:22]
      pending_cnt <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 49:17]
    else :
      pending_cnt <= nxt_pending_cnt @[src/main/scala/plic/PlicGateway.scala 51:17]
    decr_pending <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 55:16]
    node _T_7 = eq(UInt<1>("h0"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
    when _T_7 : @[src/main/scala/plic/PlicGateway.scala 56:20]
      node _T_8 = neq(nxt_pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:45]
      node _T_9 = and(io.edge_lvl, _T_8) @[src/main/scala/plic/PlicGateway.scala 58:25]
      node _T_10 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:59]
      node _T_11 = and(_T_10, io.src) @[src/main/scala/plic/PlicGateway.scala 58:72]
      node _T_12 = or(_T_9, _T_11) @[src/main/scala/plic/PlicGateway.scala 58:55]
      when _T_12 : @[src/main/scala/plic/PlicGateway.scala 58:84]
        ip_state <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 59:18]
        decr_pending <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 60:22]
    else :
      node _T_13 = eq(UInt<1>("h1"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
      when _T_13 : @[src/main/scala/plic/PlicGateway.scala 56:20]
        when io.claim : @[src/main/scala/plic/PlicGateway.scala 64:22]
          ip_state <= UInt<2>("h2") @[src/main/scala/plic/PlicGateway.scala 64:33]
      else :
        node _T_14 = eq(UInt<2>("h2"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
        when _T_14 : @[src/main/scala/plic/PlicGateway.scala 56:20]
          when io.complete : @[src/main/scala/plic/PlicGateway.scala 67:25]
            ip_state <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 67:36]
    node _io_ip_T = eq(ip_state, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 71:21]
    io.ip <= _io_ip_T @[src/main/scala/plic/PlicGateway.scala 71:9]

  module PlicGateway_2 :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip src : UInt<1>, flip edge_lvl : UInt<1>, ip : UInt<1>, flip claim : UInt<1>, flip complete : UInt<1>} @[src/main/scala/plic/PlicGateway.scala 17:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 19:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicGateway.scala 19:32]
    reg src_dly : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 22:21]
    reg src_edge : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 23:21]
    reg pending_cnt : UInt<5>, clock with :
      reset => (asyncReset, UInt<5>("h0")) @[src/main/scala/plic/PlicGateway.scala 24:21]
    reg decr_pending : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 25:21]
    reg ip_state : UInt<2>, clock with :
      reset => (asyncReset, UInt<2>("h0")) @[src/main/scala/plic/PlicGateway.scala 27:21]
    wire nxt_pending_cnt : UInt<5> @[src/main/scala/plic/PlicGateway.scala 31:29]
    src_dly <= io.src @[src/main/scala/plic/PlicGateway.scala 34:11]
    node _src_edge_T = eq(src_dly, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 35:25]
    node _src_edge_T_1 = and(io.src, _src_edge_T) @[src/main/scala/plic/PlicGateway.scala 35:22]
    src_edge <= _src_edge_T_1 @[src/main/scala/plic/PlicGateway.scala 35:12]
    node _T = eq(src_edge, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 38:24]
    node _T_1 = and(decr_pending, _T) @[src/main/scala/plic/PlicGateway.scala 38:21]
    when _T_1 : @[src/main/scala/plic/PlicGateway.scala 38:35]
      node _T_2 = gt(pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 39:22]
      when _T_2 : @[src/main/scala/plic/PlicGateway.scala 39:29]
        node _nxt_pending_cnt_T = sub(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 39:62]
        node _nxt_pending_cnt_T_1 = tail(_nxt_pending_cnt_T, 1) @[src/main/scala/plic/PlicGateway.scala 39:62]
        nxt_pending_cnt <= _nxt_pending_cnt_T_1 @[src/main/scala/plic/PlicGateway.scala 39:47]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 40:34]
    else :
      node _T_3 = eq(decr_pending, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 41:15]
      node _T_4 = and(_T_3, src_edge) @[src/main/scala/plic/PlicGateway.scala 41:29]
      when _T_4 : @[src/main/scala/plic/PlicGateway.scala 41:42]
        node _T_5 = lt(pending_cnt, UInt<5>("h10")) @[src/main/scala/plic/PlicGateway.scala 42:22]
        when _T_5 : @[src/main/scala/plic/PlicGateway.scala 42:43]
          node _nxt_pending_cnt_T_2 = add(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 42:76]
          node _nxt_pending_cnt_T_3 = tail(_nxt_pending_cnt_T_2, 1) @[src/main/scala/plic/PlicGateway.scala 42:76]
          nxt_pending_cnt <= _nxt_pending_cnt_T_3 @[src/main/scala/plic/PlicGateway.scala 42:61]
        else :
          nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 43:34]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 45:21]
    node _T_6 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 48:8]
    when _T_6 : @[src/main/scala/plic/PlicGateway.scala 48:22]
      pending_cnt <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 49:17]
    else :
      pending_cnt <= nxt_pending_cnt @[src/main/scala/plic/PlicGateway.scala 51:17]
    decr_pending <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 55:16]
    node _T_7 = eq(UInt<1>("h0"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
    when _T_7 : @[src/main/scala/plic/PlicGateway.scala 56:20]
      node _T_8 = neq(nxt_pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:45]
      node _T_9 = and(io.edge_lvl, _T_8) @[src/main/scala/plic/PlicGateway.scala 58:25]
      node _T_10 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:59]
      node _T_11 = and(_T_10, io.src) @[src/main/scala/plic/PlicGateway.scala 58:72]
      node _T_12 = or(_T_9, _T_11) @[src/main/scala/plic/PlicGateway.scala 58:55]
      when _T_12 : @[src/main/scala/plic/PlicGateway.scala 58:84]
        ip_state <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 59:18]
        decr_pending <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 60:22]
    else :
      node _T_13 = eq(UInt<1>("h1"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
      when _T_13 : @[src/main/scala/plic/PlicGateway.scala 56:20]
        when io.claim : @[src/main/scala/plic/PlicGateway.scala 64:22]
          ip_state <= UInt<2>("h2") @[src/main/scala/plic/PlicGateway.scala 64:33]
      else :
        node _T_14 = eq(UInt<2>("h2"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
        when _T_14 : @[src/main/scala/plic/PlicGateway.scala 56:20]
          when io.complete : @[src/main/scala/plic/PlicGateway.scala 67:25]
            ip_state <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 67:36]
    node _io_ip_T = eq(ip_state, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 71:21]
    io.ip <= _io_ip_T @[src/main/scala/plic/PlicGateway.scala 71:9]

  module PlicGateway_3 :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip src : UInt<1>, flip edge_lvl : UInt<1>, ip : UInt<1>, flip claim : UInt<1>, flip complete : UInt<1>} @[src/main/scala/plic/PlicGateway.scala 17:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 19:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicGateway.scala 19:32]
    reg src_dly : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 22:21]
    reg src_edge : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 23:21]
    reg pending_cnt : UInt<5>, clock with :
      reset => (asyncReset, UInt<5>("h0")) @[src/main/scala/plic/PlicGateway.scala 24:21]
    reg decr_pending : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 25:21]
    reg ip_state : UInt<2>, clock with :
      reset => (asyncReset, UInt<2>("h0")) @[src/main/scala/plic/PlicGateway.scala 27:21]
    wire nxt_pending_cnt : UInt<5> @[src/main/scala/plic/PlicGateway.scala 31:29]
    src_dly <= io.src @[src/main/scala/plic/PlicGateway.scala 34:11]
    node _src_edge_T = eq(src_dly, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 35:25]
    node _src_edge_T_1 = and(io.src, _src_edge_T) @[src/main/scala/plic/PlicGateway.scala 35:22]
    src_edge <= _src_edge_T_1 @[src/main/scala/plic/PlicGateway.scala 35:12]
    node _T = eq(src_edge, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 38:24]
    node _T_1 = and(decr_pending, _T) @[src/main/scala/plic/PlicGateway.scala 38:21]
    when _T_1 : @[src/main/scala/plic/PlicGateway.scala 38:35]
      node _T_2 = gt(pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 39:22]
      when _T_2 : @[src/main/scala/plic/PlicGateway.scala 39:29]
        node _nxt_pending_cnt_T = sub(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 39:62]
        node _nxt_pending_cnt_T_1 = tail(_nxt_pending_cnt_T, 1) @[src/main/scala/plic/PlicGateway.scala 39:62]
        nxt_pending_cnt <= _nxt_pending_cnt_T_1 @[src/main/scala/plic/PlicGateway.scala 39:47]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 40:34]
    else :
      node _T_3 = eq(decr_pending, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 41:15]
      node _T_4 = and(_T_3, src_edge) @[src/main/scala/plic/PlicGateway.scala 41:29]
      when _T_4 : @[src/main/scala/plic/PlicGateway.scala 41:42]
        node _T_5 = lt(pending_cnt, UInt<5>("h10")) @[src/main/scala/plic/PlicGateway.scala 42:22]
        when _T_5 : @[src/main/scala/plic/PlicGateway.scala 42:43]
          node _nxt_pending_cnt_T_2 = add(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 42:76]
          node _nxt_pending_cnt_T_3 = tail(_nxt_pending_cnt_T_2, 1) @[src/main/scala/plic/PlicGateway.scala 42:76]
          nxt_pending_cnt <= _nxt_pending_cnt_T_3 @[src/main/scala/plic/PlicGateway.scala 42:61]
        else :
          nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 43:34]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 45:21]
    node _T_6 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 48:8]
    when _T_6 : @[src/main/scala/plic/PlicGateway.scala 48:22]
      pending_cnt <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 49:17]
    else :
      pending_cnt <= nxt_pending_cnt @[src/main/scala/plic/PlicGateway.scala 51:17]
    decr_pending <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 55:16]
    node _T_7 = eq(UInt<1>("h0"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
    when _T_7 : @[src/main/scala/plic/PlicGateway.scala 56:20]
      node _T_8 = neq(nxt_pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:45]
      node _T_9 = and(io.edge_lvl, _T_8) @[src/main/scala/plic/PlicGateway.scala 58:25]
      node _T_10 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:59]
      node _T_11 = and(_T_10, io.src) @[src/main/scala/plic/PlicGateway.scala 58:72]
      node _T_12 = or(_T_9, _T_11) @[src/main/scala/plic/PlicGateway.scala 58:55]
      when _T_12 : @[src/main/scala/plic/PlicGateway.scala 58:84]
        ip_state <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 59:18]
        decr_pending <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 60:22]
    else :
      node _T_13 = eq(UInt<1>("h1"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
      when _T_13 : @[src/main/scala/plic/PlicGateway.scala 56:20]
        when io.claim : @[src/main/scala/plic/PlicGateway.scala 64:22]
          ip_state <= UInt<2>("h2") @[src/main/scala/plic/PlicGateway.scala 64:33]
      else :
        node _T_14 = eq(UInt<2>("h2"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
        when _T_14 : @[src/main/scala/plic/PlicGateway.scala 56:20]
          when io.complete : @[src/main/scala/plic/PlicGateway.scala 67:25]
            ip_state <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 67:36]
    node _io_ip_T = eq(ip_state, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 71:21]
    io.ip <= _io_ip_T @[src/main/scala/plic/PlicGateway.scala 71:9]

  module PlicGateway_4 :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip src : UInt<1>, flip edge_lvl : UInt<1>, ip : UInt<1>, flip claim : UInt<1>, flip complete : UInt<1>} @[src/main/scala/plic/PlicGateway.scala 17:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 19:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicGateway.scala 19:32]
    reg src_dly : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 22:21]
    reg src_edge : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 23:21]
    reg pending_cnt : UInt<5>, clock with :
      reset => (asyncReset, UInt<5>("h0")) @[src/main/scala/plic/PlicGateway.scala 24:21]
    reg decr_pending : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 25:21]
    reg ip_state : UInt<2>, clock with :
      reset => (asyncReset, UInt<2>("h0")) @[src/main/scala/plic/PlicGateway.scala 27:21]
    wire nxt_pending_cnt : UInt<5> @[src/main/scala/plic/PlicGateway.scala 31:29]
    src_dly <= io.src @[src/main/scala/plic/PlicGateway.scala 34:11]
    node _src_edge_T = eq(src_dly, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 35:25]
    node _src_edge_T_1 = and(io.src, _src_edge_T) @[src/main/scala/plic/PlicGateway.scala 35:22]
    src_edge <= _src_edge_T_1 @[src/main/scala/plic/PlicGateway.scala 35:12]
    node _T = eq(src_edge, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 38:24]
    node _T_1 = and(decr_pending, _T) @[src/main/scala/plic/PlicGateway.scala 38:21]
    when _T_1 : @[src/main/scala/plic/PlicGateway.scala 38:35]
      node _T_2 = gt(pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 39:22]
      when _T_2 : @[src/main/scala/plic/PlicGateway.scala 39:29]
        node _nxt_pending_cnt_T = sub(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 39:62]
        node _nxt_pending_cnt_T_1 = tail(_nxt_pending_cnt_T, 1) @[src/main/scala/plic/PlicGateway.scala 39:62]
        nxt_pending_cnt <= _nxt_pending_cnt_T_1 @[src/main/scala/plic/PlicGateway.scala 39:47]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 40:34]
    else :
      node _T_3 = eq(decr_pending, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 41:15]
      node _T_4 = and(_T_3, src_edge) @[src/main/scala/plic/PlicGateway.scala 41:29]
      when _T_4 : @[src/main/scala/plic/PlicGateway.scala 41:42]
        node _T_5 = lt(pending_cnt, UInt<5>("h10")) @[src/main/scala/plic/PlicGateway.scala 42:22]
        when _T_5 : @[src/main/scala/plic/PlicGateway.scala 42:43]
          node _nxt_pending_cnt_T_2 = add(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 42:76]
          node _nxt_pending_cnt_T_3 = tail(_nxt_pending_cnt_T_2, 1) @[src/main/scala/plic/PlicGateway.scala 42:76]
          nxt_pending_cnt <= _nxt_pending_cnt_T_3 @[src/main/scala/plic/PlicGateway.scala 42:61]
        else :
          nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 43:34]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 45:21]
    node _T_6 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 48:8]
    when _T_6 : @[src/main/scala/plic/PlicGateway.scala 48:22]
      pending_cnt <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 49:17]
    else :
      pending_cnt <= nxt_pending_cnt @[src/main/scala/plic/PlicGateway.scala 51:17]
    decr_pending <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 55:16]
    node _T_7 = eq(UInt<1>("h0"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
    when _T_7 : @[src/main/scala/plic/PlicGateway.scala 56:20]
      node _T_8 = neq(nxt_pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:45]
      node _T_9 = and(io.edge_lvl, _T_8) @[src/main/scala/plic/PlicGateway.scala 58:25]
      node _T_10 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:59]
      node _T_11 = and(_T_10, io.src) @[src/main/scala/plic/PlicGateway.scala 58:72]
      node _T_12 = or(_T_9, _T_11) @[src/main/scala/plic/PlicGateway.scala 58:55]
      when _T_12 : @[src/main/scala/plic/PlicGateway.scala 58:84]
        ip_state <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 59:18]
        decr_pending <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 60:22]
    else :
      node _T_13 = eq(UInt<1>("h1"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
      when _T_13 : @[src/main/scala/plic/PlicGateway.scala 56:20]
        when io.claim : @[src/main/scala/plic/PlicGateway.scala 64:22]
          ip_state <= UInt<2>("h2") @[src/main/scala/plic/PlicGateway.scala 64:33]
      else :
        node _T_14 = eq(UInt<2>("h2"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
        when _T_14 : @[src/main/scala/plic/PlicGateway.scala 56:20]
          when io.complete : @[src/main/scala/plic/PlicGateway.scala 67:25]
            ip_state <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 67:36]
    node _io_ip_T = eq(ip_state, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 71:21]
    io.ip <= _io_ip_T @[src/main/scala/plic/PlicGateway.scala 71:9]

  module PlicGateway_5 :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip src : UInt<1>, flip edge_lvl : UInt<1>, ip : UInt<1>, flip claim : UInt<1>, flip complete : UInt<1>} @[src/main/scala/plic/PlicGateway.scala 17:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 19:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicGateway.scala 19:32]
    reg src_dly : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 22:21]
    reg src_edge : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 23:21]
    reg pending_cnt : UInt<5>, clock with :
      reset => (asyncReset, UInt<5>("h0")) @[src/main/scala/plic/PlicGateway.scala 24:21]
    reg decr_pending : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 25:21]
    reg ip_state : UInt<2>, clock with :
      reset => (asyncReset, UInt<2>("h0")) @[src/main/scala/plic/PlicGateway.scala 27:21]
    wire nxt_pending_cnt : UInt<5> @[src/main/scala/plic/PlicGateway.scala 31:29]
    src_dly <= io.src @[src/main/scala/plic/PlicGateway.scala 34:11]
    node _src_edge_T = eq(src_dly, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 35:25]
    node _src_edge_T_1 = and(io.src, _src_edge_T) @[src/main/scala/plic/PlicGateway.scala 35:22]
    src_edge <= _src_edge_T_1 @[src/main/scala/plic/PlicGateway.scala 35:12]
    node _T = eq(src_edge, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 38:24]
    node _T_1 = and(decr_pending, _T) @[src/main/scala/plic/PlicGateway.scala 38:21]
    when _T_1 : @[src/main/scala/plic/PlicGateway.scala 38:35]
      node _T_2 = gt(pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 39:22]
      when _T_2 : @[src/main/scala/plic/PlicGateway.scala 39:29]
        node _nxt_pending_cnt_T = sub(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 39:62]
        node _nxt_pending_cnt_T_1 = tail(_nxt_pending_cnt_T, 1) @[src/main/scala/plic/PlicGateway.scala 39:62]
        nxt_pending_cnt <= _nxt_pending_cnt_T_1 @[src/main/scala/plic/PlicGateway.scala 39:47]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 40:34]
    else :
      node _T_3 = eq(decr_pending, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 41:15]
      node _T_4 = and(_T_3, src_edge) @[src/main/scala/plic/PlicGateway.scala 41:29]
      when _T_4 : @[src/main/scala/plic/PlicGateway.scala 41:42]
        node _T_5 = lt(pending_cnt, UInt<5>("h10")) @[src/main/scala/plic/PlicGateway.scala 42:22]
        when _T_5 : @[src/main/scala/plic/PlicGateway.scala 42:43]
          node _nxt_pending_cnt_T_2 = add(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 42:76]
          node _nxt_pending_cnt_T_3 = tail(_nxt_pending_cnt_T_2, 1) @[src/main/scala/plic/PlicGateway.scala 42:76]
          nxt_pending_cnt <= _nxt_pending_cnt_T_3 @[src/main/scala/plic/PlicGateway.scala 42:61]
        else :
          nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 43:34]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 45:21]
    node _T_6 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 48:8]
    when _T_6 : @[src/main/scala/plic/PlicGateway.scala 48:22]
      pending_cnt <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 49:17]
    else :
      pending_cnt <= nxt_pending_cnt @[src/main/scala/plic/PlicGateway.scala 51:17]
    decr_pending <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 55:16]
    node _T_7 = eq(UInt<1>("h0"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
    when _T_7 : @[src/main/scala/plic/PlicGateway.scala 56:20]
      node _T_8 = neq(nxt_pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:45]
      node _T_9 = and(io.edge_lvl, _T_8) @[src/main/scala/plic/PlicGateway.scala 58:25]
      node _T_10 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:59]
      node _T_11 = and(_T_10, io.src) @[src/main/scala/plic/PlicGateway.scala 58:72]
      node _T_12 = or(_T_9, _T_11) @[src/main/scala/plic/PlicGateway.scala 58:55]
      when _T_12 : @[src/main/scala/plic/PlicGateway.scala 58:84]
        ip_state <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 59:18]
        decr_pending <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 60:22]
    else :
      node _T_13 = eq(UInt<1>("h1"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
      when _T_13 : @[src/main/scala/plic/PlicGateway.scala 56:20]
        when io.claim : @[src/main/scala/plic/PlicGateway.scala 64:22]
          ip_state <= UInt<2>("h2") @[src/main/scala/plic/PlicGateway.scala 64:33]
      else :
        node _T_14 = eq(UInt<2>("h2"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
        when _T_14 : @[src/main/scala/plic/PlicGateway.scala 56:20]
          when io.complete : @[src/main/scala/plic/PlicGateway.scala 67:25]
            ip_state <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 67:36]
    node _io_ip_T = eq(ip_state, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 71:21]
    io.ip <= _io_ip_T @[src/main/scala/plic/PlicGateway.scala 71:9]

  module PlicGateway_6 :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip src : UInt<1>, flip edge_lvl : UInt<1>, ip : UInt<1>, flip claim : UInt<1>, flip complete : UInt<1>} @[src/main/scala/plic/PlicGateway.scala 17:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 19:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicGateway.scala 19:32]
    reg src_dly : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 22:21]
    reg src_edge : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 23:21]
    reg pending_cnt : UInt<5>, clock with :
      reset => (asyncReset, UInt<5>("h0")) @[src/main/scala/plic/PlicGateway.scala 24:21]
    reg decr_pending : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 25:21]
    reg ip_state : UInt<2>, clock with :
      reset => (asyncReset, UInt<2>("h0")) @[src/main/scala/plic/PlicGateway.scala 27:21]
    wire nxt_pending_cnt : UInt<5> @[src/main/scala/plic/PlicGateway.scala 31:29]
    src_dly <= io.src @[src/main/scala/plic/PlicGateway.scala 34:11]
    node _src_edge_T = eq(src_dly, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 35:25]
    node _src_edge_T_1 = and(io.src, _src_edge_T) @[src/main/scala/plic/PlicGateway.scala 35:22]
    src_edge <= _src_edge_T_1 @[src/main/scala/plic/PlicGateway.scala 35:12]
    node _T = eq(src_edge, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 38:24]
    node _T_1 = and(decr_pending, _T) @[src/main/scala/plic/PlicGateway.scala 38:21]
    when _T_1 : @[src/main/scala/plic/PlicGateway.scala 38:35]
      node _T_2 = gt(pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 39:22]
      when _T_2 : @[src/main/scala/plic/PlicGateway.scala 39:29]
        node _nxt_pending_cnt_T = sub(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 39:62]
        node _nxt_pending_cnt_T_1 = tail(_nxt_pending_cnt_T, 1) @[src/main/scala/plic/PlicGateway.scala 39:62]
        nxt_pending_cnt <= _nxt_pending_cnt_T_1 @[src/main/scala/plic/PlicGateway.scala 39:47]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 40:34]
    else :
      node _T_3 = eq(decr_pending, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 41:15]
      node _T_4 = and(_T_3, src_edge) @[src/main/scala/plic/PlicGateway.scala 41:29]
      when _T_4 : @[src/main/scala/plic/PlicGateway.scala 41:42]
        node _T_5 = lt(pending_cnt, UInt<5>("h10")) @[src/main/scala/plic/PlicGateway.scala 42:22]
        when _T_5 : @[src/main/scala/plic/PlicGateway.scala 42:43]
          node _nxt_pending_cnt_T_2 = add(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 42:76]
          node _nxt_pending_cnt_T_3 = tail(_nxt_pending_cnt_T_2, 1) @[src/main/scala/plic/PlicGateway.scala 42:76]
          nxt_pending_cnt <= _nxt_pending_cnt_T_3 @[src/main/scala/plic/PlicGateway.scala 42:61]
        else :
          nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 43:34]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 45:21]
    node _T_6 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 48:8]
    when _T_6 : @[src/main/scala/plic/PlicGateway.scala 48:22]
      pending_cnt <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 49:17]
    else :
      pending_cnt <= nxt_pending_cnt @[src/main/scala/plic/PlicGateway.scala 51:17]
    decr_pending <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 55:16]
    node _T_7 = eq(UInt<1>("h0"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
    when _T_7 : @[src/main/scala/plic/PlicGateway.scala 56:20]
      node _T_8 = neq(nxt_pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:45]
      node _T_9 = and(io.edge_lvl, _T_8) @[src/main/scala/plic/PlicGateway.scala 58:25]
      node _T_10 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:59]
      node _T_11 = and(_T_10, io.src) @[src/main/scala/plic/PlicGateway.scala 58:72]
      node _T_12 = or(_T_9, _T_11) @[src/main/scala/plic/PlicGateway.scala 58:55]
      when _T_12 : @[src/main/scala/plic/PlicGateway.scala 58:84]
        ip_state <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 59:18]
        decr_pending <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 60:22]
    else :
      node _T_13 = eq(UInt<1>("h1"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
      when _T_13 : @[src/main/scala/plic/PlicGateway.scala 56:20]
        when io.claim : @[src/main/scala/plic/PlicGateway.scala 64:22]
          ip_state <= UInt<2>("h2") @[src/main/scala/plic/PlicGateway.scala 64:33]
      else :
        node _T_14 = eq(UInt<2>("h2"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
        when _T_14 : @[src/main/scala/plic/PlicGateway.scala 56:20]
          when io.complete : @[src/main/scala/plic/PlicGateway.scala 67:25]
            ip_state <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 67:36]
    node _io_ip_T = eq(ip_state, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 71:21]
    io.ip <= _io_ip_T @[src/main/scala/plic/PlicGateway.scala 71:9]

  module PlicGateway_7 :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip src : UInt<1>, flip edge_lvl : UInt<1>, ip : UInt<1>, flip claim : UInt<1>, flip complete : UInt<1>} @[src/main/scala/plic/PlicGateway.scala 17:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 19:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicGateway.scala 19:32]
    reg src_dly : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 22:21]
    reg src_edge : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 23:21]
    reg pending_cnt : UInt<5>, clock with :
      reset => (asyncReset, UInt<5>("h0")) @[src/main/scala/plic/PlicGateway.scala 24:21]
    reg decr_pending : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 25:21]
    reg ip_state : UInt<2>, clock with :
      reset => (asyncReset, UInt<2>("h0")) @[src/main/scala/plic/PlicGateway.scala 27:21]
    wire nxt_pending_cnt : UInt<5> @[src/main/scala/plic/PlicGateway.scala 31:29]
    src_dly <= io.src @[src/main/scala/plic/PlicGateway.scala 34:11]
    node _src_edge_T = eq(src_dly, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 35:25]
    node _src_edge_T_1 = and(io.src, _src_edge_T) @[src/main/scala/plic/PlicGateway.scala 35:22]
    src_edge <= _src_edge_T_1 @[src/main/scala/plic/PlicGateway.scala 35:12]
    node _T = eq(src_edge, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 38:24]
    node _T_1 = and(decr_pending, _T) @[src/main/scala/plic/PlicGateway.scala 38:21]
    when _T_1 : @[src/main/scala/plic/PlicGateway.scala 38:35]
      node _T_2 = gt(pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 39:22]
      when _T_2 : @[src/main/scala/plic/PlicGateway.scala 39:29]
        node _nxt_pending_cnt_T = sub(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 39:62]
        node _nxt_pending_cnt_T_1 = tail(_nxt_pending_cnt_T, 1) @[src/main/scala/plic/PlicGateway.scala 39:62]
        nxt_pending_cnt <= _nxt_pending_cnt_T_1 @[src/main/scala/plic/PlicGateway.scala 39:47]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 40:34]
    else :
      node _T_3 = eq(decr_pending, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 41:15]
      node _T_4 = and(_T_3, src_edge) @[src/main/scala/plic/PlicGateway.scala 41:29]
      when _T_4 : @[src/main/scala/plic/PlicGateway.scala 41:42]
        node _T_5 = lt(pending_cnt, UInt<5>("h10")) @[src/main/scala/plic/PlicGateway.scala 42:22]
        when _T_5 : @[src/main/scala/plic/PlicGateway.scala 42:43]
          node _nxt_pending_cnt_T_2 = add(pending_cnt, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 42:76]
          node _nxt_pending_cnt_T_3 = tail(_nxt_pending_cnt_T_2, 1) @[src/main/scala/plic/PlicGateway.scala 42:76]
          nxt_pending_cnt <= _nxt_pending_cnt_T_3 @[src/main/scala/plic/PlicGateway.scala 42:61]
        else :
          nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 43:34]
      else :
        nxt_pending_cnt <= pending_cnt @[src/main/scala/plic/PlicGateway.scala 45:21]
    node _T_6 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 48:8]
    when _T_6 : @[src/main/scala/plic/PlicGateway.scala 48:22]
      pending_cnt <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 49:17]
    else :
      pending_cnt <= nxt_pending_cnt @[src/main/scala/plic/PlicGateway.scala 51:17]
    decr_pending <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 55:16]
    node _T_7 = eq(UInt<1>("h0"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
    when _T_7 : @[src/main/scala/plic/PlicGateway.scala 56:20]
      node _T_8 = neq(nxt_pending_cnt, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:45]
      node _T_9 = and(io.edge_lvl, _T_8) @[src/main/scala/plic/PlicGateway.scala 58:25]
      node _T_10 = eq(io.edge_lvl, UInt<1>("h0")) @[src/main/scala/plic/PlicGateway.scala 58:59]
      node _T_11 = and(_T_10, io.src) @[src/main/scala/plic/PlicGateway.scala 58:72]
      node _T_12 = or(_T_9, _T_11) @[src/main/scala/plic/PlicGateway.scala 58:55]
      when _T_12 : @[src/main/scala/plic/PlicGateway.scala 58:84]
        ip_state <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 59:18]
        decr_pending <= UInt<1>("h1") @[src/main/scala/plic/PlicGateway.scala 60:22]
    else :
      node _T_13 = eq(UInt<1>("h1"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
      when _T_13 : @[src/main/scala/plic/PlicGateway.scala 56:20]
        when io.claim : @[src/main/scala/plic/PlicGateway.scala 64:22]
          ip_state <= UInt<2>("h2") @[src/main/scala/plic/PlicGateway.scala 64:33]
      else :
        node _T_14 = eq(UInt<2>("h2"), ip_state) @[src/main/scala/plic/PlicGateway.scala 56:20]
        when _T_14 : @[src/main/scala/plic/PlicGateway.scala 56:20]
          when io.complete : @[src/main/scala/plic/PlicGateway.scala 67:25]
            ip_state <= UInt<1>("h0") @[src/main/scala/plic/PlicGateway.scala 67:36]
    node _io_ip_T = eq(ip_state, UInt<1>("h1")) @[src/main/scala/plic/PlicGateway.scala 71:21]
    io.ip <= _io_ip_T @[src/main/scala/plic/PlicGateway.scala 71:9]

  module PlicCell :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip ip : UInt<1>, flip ie : UInt<1>, flip priority : UInt<3>, id : UInt<4>, priorityOut : UInt<3>} @[src/main/scala/plic/PlicCell.scala 18:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicCell.scala 20:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicCell.scala 20:32]
    reg priorityReg : UInt<3>, clock with :
      reset => (asyncReset, UInt<3>("h0")) @[src/main/scala/plic/PlicCell.scala 23:20]
    reg idReg : UInt<4>, clock with :
      reset => (asyncReset, UInt<4>("h0")) @[src/main/scala/plic/PlicCell.scala 24:20]
    node _T = and(io.ip, io.ie) @[src/main/scala/plic/PlicCell.scala 28:14]
    when _T : @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= io.priority @[src/main/scala/plic/PlicCell.scala 29:17]
      idReg <= UInt<1>("h1") @[src/main/scala/plic/PlicCell.scala 30:11]
    else :
      priorityReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 32:17]
      idReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 33:11]
    io.priorityOut <= priorityReg @[src/main/scala/plic/PlicCell.scala 36:18]
    io.id <= idReg @[src/main/scala/plic/PlicCell.scala 37:9]

  module PlicCell_1 :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip ip : UInt<1>, flip ie : UInt<1>, flip priority : UInt<3>, id : UInt<4>, priorityOut : UInt<3>} @[src/main/scala/plic/PlicCell.scala 18:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicCell.scala 20:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicCell.scala 20:32]
    reg priorityReg : UInt<3>, clock with :
      reset => (asyncReset, UInt<3>("h0")) @[src/main/scala/plic/PlicCell.scala 23:20]
    reg idReg : UInt<4>, clock with :
      reset => (asyncReset, UInt<4>("h0")) @[src/main/scala/plic/PlicCell.scala 24:20]
    node _T = and(io.ip, io.ie) @[src/main/scala/plic/PlicCell.scala 28:14]
    when _T : @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= io.priority @[src/main/scala/plic/PlicCell.scala 29:17]
      idReg <= UInt<2>("h2") @[src/main/scala/plic/PlicCell.scala 30:11]
    else :
      priorityReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 32:17]
      idReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 33:11]
    io.priorityOut <= priorityReg @[src/main/scala/plic/PlicCell.scala 36:18]
    io.id <= idReg @[src/main/scala/plic/PlicCell.scala 37:9]

  module PlicCell_2 :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip ip : UInt<1>, flip ie : UInt<1>, flip priority : UInt<3>, id : UInt<4>, priorityOut : UInt<3>} @[src/main/scala/plic/PlicCell.scala 18:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicCell.scala 20:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicCell.scala 20:32]
    reg priorityReg : UInt<3>, clock with :
      reset => (asyncReset, UInt<3>("h0")) @[src/main/scala/plic/PlicCell.scala 23:20]
    reg idReg : UInt<4>, clock with :
      reset => (asyncReset, UInt<4>("h0")) @[src/main/scala/plic/PlicCell.scala 24:20]
    node _T = and(io.ip, io.ie) @[src/main/scala/plic/PlicCell.scala 28:14]
    when _T : @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= io.priority @[src/main/scala/plic/PlicCell.scala 29:17]
      idReg <= UInt<2>("h3") @[src/main/scala/plic/PlicCell.scala 30:11]
    else :
      priorityReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 32:17]
      idReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 33:11]
    io.priorityOut <= priorityReg @[src/main/scala/plic/PlicCell.scala 36:18]
    io.id <= idReg @[src/main/scala/plic/PlicCell.scala 37:9]

  module PlicCell_3 :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip ip : UInt<1>, flip ie : UInt<1>, flip priority : UInt<3>, id : UInt<4>, priorityOut : UInt<3>} @[src/main/scala/plic/PlicCell.scala 18:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicCell.scala 20:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicCell.scala 20:32]
    reg priorityReg : UInt<3>, clock with :
      reset => (asyncReset, UInt<3>("h0")) @[src/main/scala/plic/PlicCell.scala 23:20]
    reg idReg : UInt<4>, clock with :
      reset => (asyncReset, UInt<4>("h0")) @[src/main/scala/plic/PlicCell.scala 24:20]
    node _T = and(io.ip, io.ie) @[src/main/scala/plic/PlicCell.scala 28:14]
    when _T : @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= io.priority @[src/main/scala/plic/PlicCell.scala 29:17]
      idReg <= UInt<3>("h4") @[src/main/scala/plic/PlicCell.scala 30:11]
    else :
      priorityReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 32:17]
      idReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 33:11]
    io.priorityOut <= priorityReg @[src/main/scala/plic/PlicCell.scala 36:18]
    io.id <= idReg @[src/main/scala/plic/PlicCell.scala 37:9]

  module PlicCell_4 :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip ip : UInt<1>, flip ie : UInt<1>, flip priority : UInt<3>, id : UInt<4>, priorityOut : UInt<3>} @[src/main/scala/plic/PlicCell.scala 18:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicCell.scala 20:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicCell.scala 20:32]
    reg priorityReg : UInt<3>, clock with :
      reset => (asyncReset, UInt<3>("h0")) @[src/main/scala/plic/PlicCell.scala 23:20]
    reg idReg : UInt<4>, clock with :
      reset => (asyncReset, UInt<4>("h0")) @[src/main/scala/plic/PlicCell.scala 24:20]
    node _T = and(io.ip, io.ie) @[src/main/scala/plic/PlicCell.scala 28:14]
    when _T : @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= io.priority @[src/main/scala/plic/PlicCell.scala 29:17]
      idReg <= UInt<3>("h5") @[src/main/scala/plic/PlicCell.scala 30:11]
    else :
      priorityReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 32:17]
      idReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 33:11]
    io.priorityOut <= priorityReg @[src/main/scala/plic/PlicCell.scala 36:18]
    io.id <= idReg @[src/main/scala/plic/PlicCell.scala 37:9]

  module PlicCell_5 :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip ip : UInt<1>, flip ie : UInt<1>, flip priority : UInt<3>, id : UInt<4>, priorityOut : UInt<3>} @[src/main/scala/plic/PlicCell.scala 18:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicCell.scala 20:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicCell.scala 20:32]
    reg priorityReg : UInt<3>, clock with :
      reset => (asyncReset, UInt<3>("h0")) @[src/main/scala/plic/PlicCell.scala 23:20]
    reg idReg : UInt<4>, clock with :
      reset => (asyncReset, UInt<4>("h0")) @[src/main/scala/plic/PlicCell.scala 24:20]
    node _T = and(io.ip, io.ie) @[src/main/scala/plic/PlicCell.scala 28:14]
    when _T : @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= io.priority @[src/main/scala/plic/PlicCell.scala 29:17]
      idReg <= UInt<3>("h6") @[src/main/scala/plic/PlicCell.scala 30:11]
    else :
      priorityReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 32:17]
      idReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 33:11]
    io.priorityOut <= priorityReg @[src/main/scala/plic/PlicCell.scala 36:18]
    io.id <= idReg @[src/main/scala/plic/PlicCell.scala 37:9]

  module PlicCell_6 :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip ip : UInt<1>, flip ie : UInt<1>, flip priority : UInt<3>, id : UInt<4>, priorityOut : UInt<3>} @[src/main/scala/plic/PlicCell.scala 18:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicCell.scala 20:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicCell.scala 20:32]
    reg priorityReg : UInt<3>, clock with :
      reset => (asyncReset, UInt<3>("h0")) @[src/main/scala/plic/PlicCell.scala 23:20]
    reg idReg : UInt<4>, clock with :
      reset => (asyncReset, UInt<4>("h0")) @[src/main/scala/plic/PlicCell.scala 24:20]
    node _T = and(io.ip, io.ie) @[src/main/scala/plic/PlicCell.scala 28:14]
    when _T : @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= io.priority @[src/main/scala/plic/PlicCell.scala 29:17]
      idReg <= UInt<3>("h7") @[src/main/scala/plic/PlicCell.scala 30:11]
    else :
      priorityReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 32:17]
      idReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 33:11]
    io.priorityOut <= priorityReg @[src/main/scala/plic/PlicCell.scala 36:18]
    io.id <= idReg @[src/main/scala/plic/PlicCell.scala 37:9]

  module PlicCell_7 :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip ip : UInt<1>, flip ie : UInt<1>, flip priority : UInt<3>, id : UInt<4>, priorityOut : UInt<3>} @[src/main/scala/plic/PlicCell.scala 18:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicCell.scala 20:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicCell.scala 20:32]
    reg priorityReg : UInt<3>, clock with :
      reset => (asyncReset, UInt<3>("h0")) @[src/main/scala/plic/PlicCell.scala 23:20]
    reg idReg : UInt<4>, clock with :
      reset => (asyncReset, UInt<4>("h0")) @[src/main/scala/plic/PlicCell.scala 24:20]
    node _T = and(io.ip, io.ie) @[src/main/scala/plic/PlicCell.scala 28:14]
    when _T : @[src/main/scala/plic/PlicCell.scala 28:24]
      priorityReg <= io.priority @[src/main/scala/plic/PlicCell.scala 29:17]
      idReg <= UInt<4>("h8") @[src/main/scala/plic/PlicCell.scala 30:11]
    else :
      priorityReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 32:17]
      idReg <= UInt<1>("h0") @[src/main/scala/plic/PlicCell.scala 33:11]
    io.priorityOut <= priorityReg @[src/main/scala/plic/PlicCell.scala 36:18]
    io.id <= idReg @[src/main/scala/plic/PlicCell.scala 37:9]

  module PlicTarget :
    input clock : Clock
    input reset : Reset
    output io : { flip rst_n : UInt<1>, flip id_i : UInt<4>[8], flip priority_i : UInt<3>[8], flip threshold_i : UInt<3>, ireq_o : UInt<1>, id_o : UInt<4>} @[src/main/scala/plic/PlicTarget.scala 16:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicTarget.scala 17:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicTarget.scala 17:32]
    node sel = gt(io.priority_i[0], UInt<3>("h0")) @[src/main/scala/plic/PlicTarget.scala 25:32]
    node nbp = mux(sel, io.priority_i[0], UInt<3>("h0")) @[src/main/scala/plic/PlicTarget.scala 26:18]
    node nbi = mux(sel, io.id_i[0], UInt<4>("h0")) @[src/main/scala/plic/PlicTarget.scala 27:18]
    node sel_1 = gt(io.priority_i[1], nbp) @[src/main/scala/plic/PlicTarget.scala 25:32]
    node nbp_1 = mux(sel_1, io.priority_i[1], nbp) @[src/main/scala/plic/PlicTarget.scala 26:18]
    node nbi_1 = mux(sel_1, io.id_i[1], nbi) @[src/main/scala/plic/PlicTarget.scala 27:18]
    node sel_2 = gt(io.priority_i[2], nbp_1) @[src/main/scala/plic/PlicTarget.scala 25:32]
    node nbp_2 = mux(sel_2, io.priority_i[2], nbp_1) @[src/main/scala/plic/PlicTarget.scala 26:18]
    node nbi_2 = mux(sel_2, io.id_i[2], nbi_1) @[src/main/scala/plic/PlicTarget.scala 27:18]
    node sel_3 = gt(io.priority_i[3], nbp_2) @[src/main/scala/plic/PlicTarget.scala 25:32]
    node nbp_3 = mux(sel_3, io.priority_i[3], nbp_2) @[src/main/scala/plic/PlicTarget.scala 26:18]
    node nbi_3 = mux(sel_3, io.id_i[3], nbi_2) @[src/main/scala/plic/PlicTarget.scala 27:18]
    node sel_4 = gt(io.priority_i[4], nbp_3) @[src/main/scala/plic/PlicTarget.scala 25:32]
    node nbp_4 = mux(sel_4, io.priority_i[4], nbp_3) @[src/main/scala/plic/PlicTarget.scala 26:18]
    node nbi_4 = mux(sel_4, io.id_i[4], nbi_3) @[src/main/scala/plic/PlicTarget.scala 27:18]
    node sel_5 = gt(io.priority_i[5], nbp_4) @[src/main/scala/plic/PlicTarget.scala 25:32]
    node nbp_5 = mux(sel_5, io.priority_i[5], nbp_4) @[src/main/scala/plic/PlicTarget.scala 26:18]
    node nbi_5 = mux(sel_5, io.id_i[5], nbi_4) @[src/main/scala/plic/PlicTarget.scala 27:18]
    node sel_6 = gt(io.priority_i[6], nbp_5) @[src/main/scala/plic/PlicTarget.scala 25:32]
    node nbp_6 = mux(sel_6, io.priority_i[6], nbp_5) @[src/main/scala/plic/PlicTarget.scala 26:18]
    node nbi_6 = mux(sel_6, io.id_i[6], nbi_5) @[src/main/scala/plic/PlicTarget.scala 27:18]
    node sel_7 = gt(io.priority_i[7], nbp_6) @[src/main/scala/plic/PlicTarget.scala 25:32]
    node bestP = mux(sel_7, io.priority_i[7], nbp_6) @[src/main/scala/plic/PlicTarget.scala 26:18]
    node bestI = mux(sel_7, io.id_i[7], nbi_6) @[src/main/scala/plic/PlicTarget.scala 27:18]
    reg ireq_reg : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicTarget.scala 31:49]
    reg id_reg : UInt<4>, clock with :
      reset => (asyncReset, UInt<4>("h0")) @[src/main/scala/plic/PlicTarget.scala 32:47]
    node _T = gt(bestP, io.threshold_i) @[src/main/scala/plic/PlicTarget.scala 34:14]
    when _T : @[src/main/scala/plic/PlicTarget.scala 34:32]
      ireq_reg <= UInt<1>("h1") @[src/main/scala/plic/PlicTarget.scala 34:43]
    else :
      ireq_reg <= UInt<1>("h0") @[src/main/scala/plic/PlicTarget.scala 34:77]
    id_reg <= bestI @[src/main/scala/plic/PlicTarget.scala 35:10]
    io.ireq_o <= ireq_reg @[src/main/scala/plic/PlicTarget.scala 37:13]
    io.id_o <= id_reg @[src/main/scala/plic/PlicTarget.scala 38:11]

  module PlicCore :
    input clock : Clock
    input reset : UInt<1>
    output io : { flip rst_n : UInt<1>, flip src : UInt<1>[8], flip el : UInt<1>[8], ip : UInt<1>[8], flip ie : UInt<1>[8][1], flip ipriority : UInt<3>[8], flip threshold : UInt<3>[1], ireq : UInt<1>[1], id : UInt<4>[1], flip claim : UInt<1>[1], flip complete : UInt<1>[1]} @[src/main/scala/plic/PlicCore.scala 24:14]

    node _asyncReset_T = eq(io.rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicCore.scala 25:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicCore.scala 25:32]
    wire id_array_0_0 : UInt<4> @[src/main/scala/plic/PlicCore.scala 28:58]
    wire id_array_0_1 : UInt<4> @[src/main/scala/plic/PlicCore.scala 28:58]
    wire id_array_0_2 : UInt<4> @[src/main/scala/plic/PlicCore.scala 28:58]
    wire id_array_0_3 : UInt<4> @[src/main/scala/plic/PlicCore.scala 28:58]
    wire id_array_0_4 : UInt<4> @[src/main/scala/plic/PlicCore.scala 28:58]
    wire id_array_0_5 : UInt<4> @[src/main/scala/plic/PlicCore.scala 28:58]
    wire id_array_0_6 : UInt<4> @[src/main/scala/plic/PlicCore.scala 28:58]
    wire id_array_0_7 : UInt<4> @[src/main/scala/plic/PlicCore.scala 28:58]
    wire pr_array_0_0 : UInt<3> @[src/main/scala/plic/PlicCore.scala 29:58]
    wire pr_array_0_1 : UInt<3> @[src/main/scala/plic/PlicCore.scala 29:58]
    wire pr_array_0_2 : UInt<3> @[src/main/scala/plic/PlicCore.scala 29:58]
    wire pr_array_0_3 : UInt<3> @[src/main/scala/plic/PlicCore.scala 29:58]
    wire pr_array_0_4 : UInt<3> @[src/main/scala/plic/PlicCore.scala 29:58]
    wire pr_array_0_5 : UInt<3> @[src/main/scala/plic/PlicCore.scala 29:58]
    wire pr_array_0_6 : UInt<3> @[src/main/scala/plic/PlicCore.scala 29:58]
    wire pr_array_0_7 : UInt<3> @[src/main/scala/plic/PlicCore.scala 29:58]
    wire _id_claimed_WIRE : UInt<4>[1] @[src/main/scala/plic/PlicCore.scala 32:59]
    _id_claimed_WIRE[0] <= UInt<4>("h0") @[src/main/scala/plic/PlicCore.scala 32:59]
    reg id_claimed : UInt<4>[1], clock with :
      reset => (asyncReset, _id_claimed_WIRE) @[src/main/scala/plic/PlicCore.scala 32:51]
    wire claim_array_0 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 35:43]
    wire claim_array_1 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 35:43]
    wire claim_array_2 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 35:43]
    wire claim_array_3 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 35:43]
    wire claim_array_4 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 35:43]
    wire claim_array_5 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 35:43]
    wire claim_array_6 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 35:43]
    wire claim_array_7 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 35:43]
    wire complete_array_0 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 36:46]
    wire complete_array_1 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 36:46]
    wire complete_array_2 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 36:46]
    wire complete_array_3 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 36:46]
    wire complete_array_4 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 36:46]
    wire complete_array_5 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 36:46]
    wire complete_array_6 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 36:46]
    wire complete_array_7 : UInt<1>[1] @[src/main/scala/plic/PlicCore.scala 36:46]
    inst gateways_0 of PlicGateway @[src/main/scala/plic/PlicCore.scala 39:42]
    gateways_0.clock <= clock
    gateways_0.reset <= reset
    inst gateways_1 of PlicGateway_1 @[src/main/scala/plic/PlicCore.scala 39:42]
    gateways_1.clock <= clock
    gateways_1.reset <= reset
    inst gateways_2 of PlicGateway_2 @[src/main/scala/plic/PlicCore.scala 39:42]
    gateways_2.clock <= clock
    gateways_2.reset <= reset
    inst gateways_3 of PlicGateway_3 @[src/main/scala/plic/PlicCore.scala 39:42]
    gateways_3.clock <= clock
    gateways_3.reset <= reset
    inst gateways_4 of PlicGateway_4 @[src/main/scala/plic/PlicCore.scala 39:42]
    gateways_4.clock <= clock
    gateways_4.reset <= reset
    inst gateways_5 of PlicGateway_5 @[src/main/scala/plic/PlicCore.scala 39:42]
    gateways_5.clock <= clock
    gateways_5.reset <= reset
    inst gateways_6 of PlicGateway_6 @[src/main/scala/plic/PlicCore.scala 39:42]
    gateways_6.clock <= clock
    gateways_6.reset <= reset
    inst gateways_7 of PlicGateway_7 @[src/main/scala/plic/PlicCore.scala 39:42]
    gateways_7.clock <= clock
    gateways_7.reset <= reset
    gateways_0.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 41:26]
    gateways_0.io.src <= io.src[0] @[src/main/scala/plic/PlicCore.scala 42:24]
    gateways_0.io.edge_lvl <= io.el[0] @[src/main/scala/plic/PlicCore.scala 43:29]
    gateways_1.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 41:26]
    gateways_1.io.src <= io.src[1] @[src/main/scala/plic/PlicCore.scala 42:24]
    gateways_1.io.edge_lvl <= io.el[1] @[src/main/scala/plic/PlicCore.scala 43:29]
    gateways_2.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 41:26]
    gateways_2.io.src <= io.src[2] @[src/main/scala/plic/PlicCore.scala 42:24]
    gateways_2.io.edge_lvl <= io.el[2] @[src/main/scala/plic/PlicCore.scala 43:29]
    gateways_3.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 41:26]
    gateways_3.io.src <= io.src[3] @[src/main/scala/plic/PlicCore.scala 42:24]
    gateways_3.io.edge_lvl <= io.el[3] @[src/main/scala/plic/PlicCore.scala 43:29]
    gateways_4.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 41:26]
    gateways_4.io.src <= io.src[4] @[src/main/scala/plic/PlicCore.scala 42:24]
    gateways_4.io.edge_lvl <= io.el[4] @[src/main/scala/plic/PlicCore.scala 43:29]
    gateways_5.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 41:26]
    gateways_5.io.src <= io.src[5] @[src/main/scala/plic/PlicCore.scala 42:24]
    gateways_5.io.edge_lvl <= io.el[5] @[src/main/scala/plic/PlicCore.scala 43:29]
    gateways_6.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 41:26]
    gateways_6.io.src <= io.src[6] @[src/main/scala/plic/PlicCore.scala 42:24]
    gateways_6.io.edge_lvl <= io.el[6] @[src/main/scala/plic/PlicCore.scala 43:29]
    gateways_7.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 41:26]
    gateways_7.io.src <= io.src[7] @[src/main/scala/plic/PlicCore.scala 42:24]
    gateways_7.io.edge_lvl <= io.el[7] @[src/main/scala/plic/PlicCore.scala 43:29]
    inst cell of PlicCell @[src/main/scala/plic/PlicCore.scala 49:24]
    cell.clock <= clock
    cell.reset <= reset
    cell.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 50:21]
    cell.io.ip <= gateways_0.io.ip @[src/main/scala/plic/PlicCore.scala 51:18]
    cell.io.ie <= io.ie[0][0] @[src/main/scala/plic/PlicCore.scala 52:18]
    cell.io.priority <= io.ipriority[0] @[src/main/scala/plic/PlicCore.scala 53:24]
    id_array_0_0 <= cell.io.id @[src/main/scala/plic/PlicCore.scala 54:22]
    pr_array_0_0 <= cell.io.priorityOut @[src/main/scala/plic/PlicCore.scala 55:22]
    inst cell_1 of PlicCell_1 @[src/main/scala/plic/PlicCore.scala 49:24]
    cell_1.clock <= clock
    cell_1.reset <= reset
    cell_1.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 50:21]
    cell_1.io.ip <= gateways_1.io.ip @[src/main/scala/plic/PlicCore.scala 51:18]
    cell_1.io.ie <= io.ie[0][1] @[src/main/scala/plic/PlicCore.scala 52:18]
    cell_1.io.priority <= io.ipriority[1] @[src/main/scala/plic/PlicCore.scala 53:24]
    id_array_0_1 <= cell_1.io.id @[src/main/scala/plic/PlicCore.scala 54:22]
    pr_array_0_1 <= cell_1.io.priorityOut @[src/main/scala/plic/PlicCore.scala 55:22]
    inst cell_2 of PlicCell_2 @[src/main/scala/plic/PlicCore.scala 49:24]
    cell_2.clock <= clock
    cell_2.reset <= reset
    cell_2.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 50:21]
    cell_2.io.ip <= gateways_2.io.ip @[src/main/scala/plic/PlicCore.scala 51:18]
    cell_2.io.ie <= io.ie[0][2] @[src/main/scala/plic/PlicCore.scala 52:18]
    cell_2.io.priority <= io.ipriority[2] @[src/main/scala/plic/PlicCore.scala 53:24]
    id_array_0_2 <= cell_2.io.id @[src/main/scala/plic/PlicCore.scala 54:22]
    pr_array_0_2 <= cell_2.io.priorityOut @[src/main/scala/plic/PlicCore.scala 55:22]
    inst cell_3 of PlicCell_3 @[src/main/scala/plic/PlicCore.scala 49:24]
    cell_3.clock <= clock
    cell_3.reset <= reset
    cell_3.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 50:21]
    cell_3.io.ip <= gateways_3.io.ip @[src/main/scala/plic/PlicCore.scala 51:18]
    cell_3.io.ie <= io.ie[0][3] @[src/main/scala/plic/PlicCore.scala 52:18]
    cell_3.io.priority <= io.ipriority[3] @[src/main/scala/plic/PlicCore.scala 53:24]
    id_array_0_3 <= cell_3.io.id @[src/main/scala/plic/PlicCore.scala 54:22]
    pr_array_0_3 <= cell_3.io.priorityOut @[src/main/scala/plic/PlicCore.scala 55:22]
    inst cell_4 of PlicCell_4 @[src/main/scala/plic/PlicCore.scala 49:24]
    cell_4.clock <= clock
    cell_4.reset <= reset
    cell_4.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 50:21]
    cell_4.io.ip <= gateways_4.io.ip @[src/main/scala/plic/PlicCore.scala 51:18]
    cell_4.io.ie <= io.ie[0][4] @[src/main/scala/plic/PlicCore.scala 52:18]
    cell_4.io.priority <= io.ipriority[4] @[src/main/scala/plic/PlicCore.scala 53:24]
    id_array_0_4 <= cell_4.io.id @[src/main/scala/plic/PlicCore.scala 54:22]
    pr_array_0_4 <= cell_4.io.priorityOut @[src/main/scala/plic/PlicCore.scala 55:22]
    inst cell_5 of PlicCell_5 @[src/main/scala/plic/PlicCore.scala 49:24]
    cell_5.clock <= clock
    cell_5.reset <= reset
    cell_5.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 50:21]
    cell_5.io.ip <= gateways_5.io.ip @[src/main/scala/plic/PlicCore.scala 51:18]
    cell_5.io.ie <= io.ie[0][5] @[src/main/scala/plic/PlicCore.scala 52:18]
    cell_5.io.priority <= io.ipriority[5] @[src/main/scala/plic/PlicCore.scala 53:24]
    id_array_0_5 <= cell_5.io.id @[src/main/scala/plic/PlicCore.scala 54:22]
    pr_array_0_5 <= cell_5.io.priorityOut @[src/main/scala/plic/PlicCore.scala 55:22]
    inst cell_6 of PlicCell_6 @[src/main/scala/plic/PlicCore.scala 49:24]
    cell_6.clock <= clock
    cell_6.reset <= reset
    cell_6.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 50:21]
    cell_6.io.ip <= gateways_6.io.ip @[src/main/scala/plic/PlicCore.scala 51:18]
    cell_6.io.ie <= io.ie[0][6] @[src/main/scala/plic/PlicCore.scala 52:18]
    cell_6.io.priority <= io.ipriority[6] @[src/main/scala/plic/PlicCore.scala 53:24]
    id_array_0_6 <= cell_6.io.id @[src/main/scala/plic/PlicCore.scala 54:22]
    pr_array_0_6 <= cell_6.io.priorityOut @[src/main/scala/plic/PlicCore.scala 55:22]
    inst cell_7 of PlicCell_7 @[src/main/scala/plic/PlicCore.scala 49:24]
    cell_7.clock <= clock
    cell_7.reset <= reset
    cell_7.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 50:21]
    cell_7.io.ip <= gateways_7.io.ip @[src/main/scala/plic/PlicCore.scala 51:18]
    cell_7.io.ie <= io.ie[0][7] @[src/main/scala/plic/PlicCore.scala 52:18]
    cell_7.io.priority <= io.ipriority[7] @[src/main/scala/plic/PlicCore.scala 53:24]
    id_array_0_7 <= cell_7.io.id @[src/main/scala/plic/PlicCore.scala 54:22]
    pr_array_0_7 <= cell_7.io.priorityOut @[src/main/scala/plic/PlicCore.scala 55:22]
    when io.claim[0] : @[src/main/scala/plic/PlicCore.scala 61:23]
      id_claimed[0] <= io.id[0] @[src/main/scala/plic/PlicCore.scala 62:21]
    node _claim_array_0_0_T = eq(io.id[0], UInt<1>("h1")) @[src/main/scala/plic/PlicCore.scala 69:38]
    node _claim_array_0_0_T_1 = and(_claim_array_0_0_T, io.claim[0]) @[src/main/scala/plic/PlicCore.scala 69:53]
    claim_array_0[0] <= _claim_array_0_0_T_1 @[src/main/scala/plic/PlicCore.scala 69:25]
    node _complete_array_0_0_T = eq(id_claimed[0], UInt<1>("h1")) @[src/main/scala/plic/PlicCore.scala 70:46]
    node _complete_array_0_0_T_1 = and(_complete_array_0_0_T, io.complete[0]) @[src/main/scala/plic/PlicCore.scala 70:61]
    complete_array_0[0] <= _complete_array_0_0_T_1 @[src/main/scala/plic/PlicCore.scala 70:28]
    node _claim_array_1_0_T = eq(io.id[0], UInt<2>("h2")) @[src/main/scala/plic/PlicCore.scala 69:38]
    node _claim_array_1_0_T_1 = and(_claim_array_1_0_T, io.claim[0]) @[src/main/scala/plic/PlicCore.scala 69:53]
    claim_array_1[0] <= _claim_array_1_0_T_1 @[src/main/scala/plic/PlicCore.scala 69:25]
    node _complete_array_1_0_T = eq(id_claimed[0], UInt<2>("h2")) @[src/main/scala/plic/PlicCore.scala 70:46]
    node _complete_array_1_0_T_1 = and(_complete_array_1_0_T, io.complete[0]) @[src/main/scala/plic/PlicCore.scala 70:61]
    complete_array_1[0] <= _complete_array_1_0_T_1 @[src/main/scala/plic/PlicCore.scala 70:28]
    node _claim_array_2_0_T = eq(io.id[0], UInt<2>("h3")) @[src/main/scala/plic/PlicCore.scala 69:38]
    node _claim_array_2_0_T_1 = and(_claim_array_2_0_T, io.claim[0]) @[src/main/scala/plic/PlicCore.scala 69:53]
    claim_array_2[0] <= _claim_array_2_0_T_1 @[src/main/scala/plic/PlicCore.scala 69:25]
    node _complete_array_2_0_T = eq(id_claimed[0], UInt<2>("h3")) @[src/main/scala/plic/PlicCore.scala 70:46]
    node _complete_array_2_0_T_1 = and(_complete_array_2_0_T, io.complete[0]) @[src/main/scala/plic/PlicCore.scala 70:61]
    complete_array_2[0] <= _complete_array_2_0_T_1 @[src/main/scala/plic/PlicCore.scala 70:28]
    node _claim_array_3_0_T = eq(io.id[0], UInt<3>("h4")) @[src/main/scala/plic/PlicCore.scala 69:38]
    node _claim_array_3_0_T_1 = and(_claim_array_3_0_T, io.claim[0]) @[src/main/scala/plic/PlicCore.scala 69:53]
    claim_array_3[0] <= _claim_array_3_0_T_1 @[src/main/scala/plic/PlicCore.scala 69:25]
    node _complete_array_3_0_T = eq(id_claimed[0], UInt<3>("h4")) @[src/main/scala/plic/PlicCore.scala 70:46]
    node _complete_array_3_0_T_1 = and(_complete_array_3_0_T, io.complete[0]) @[src/main/scala/plic/PlicCore.scala 70:61]
    complete_array_3[0] <= _complete_array_3_0_T_1 @[src/main/scala/plic/PlicCore.scala 70:28]
    node _claim_array_4_0_T = eq(io.id[0], UInt<3>("h5")) @[src/main/scala/plic/PlicCore.scala 69:38]
    node _claim_array_4_0_T_1 = and(_claim_array_4_0_T, io.claim[0]) @[src/main/scala/plic/PlicCore.scala 69:53]
    claim_array_4[0] <= _claim_array_4_0_T_1 @[src/main/scala/plic/PlicCore.scala 69:25]
    node _complete_array_4_0_T = eq(id_claimed[0], UInt<3>("h5")) @[src/main/scala/plic/PlicCore.scala 70:46]
    node _complete_array_4_0_T_1 = and(_complete_array_4_0_T, io.complete[0]) @[src/main/scala/plic/PlicCore.scala 70:61]
    complete_array_4[0] <= _complete_array_4_0_T_1 @[src/main/scala/plic/PlicCore.scala 70:28]
    node _claim_array_5_0_T = eq(io.id[0], UInt<3>("h6")) @[src/main/scala/plic/PlicCore.scala 69:38]
    node _claim_array_5_0_T_1 = and(_claim_array_5_0_T, io.claim[0]) @[src/main/scala/plic/PlicCore.scala 69:53]
    claim_array_5[0] <= _claim_array_5_0_T_1 @[src/main/scala/plic/PlicCore.scala 69:25]
    node _complete_array_5_0_T = eq(id_claimed[0], UInt<3>("h6")) @[src/main/scala/plic/PlicCore.scala 70:46]
    node _complete_array_5_0_T_1 = and(_complete_array_5_0_T, io.complete[0]) @[src/main/scala/plic/PlicCore.scala 70:61]
    complete_array_5[0] <= _complete_array_5_0_T_1 @[src/main/scala/plic/PlicCore.scala 70:28]
    node _claim_array_6_0_T = eq(io.id[0], UInt<3>("h7")) @[src/main/scala/plic/PlicCore.scala 69:38]
    node _claim_array_6_0_T_1 = and(_claim_array_6_0_T, io.claim[0]) @[src/main/scala/plic/PlicCore.scala 69:53]
    claim_array_6[0] <= _claim_array_6_0_T_1 @[src/main/scala/plic/PlicCore.scala 69:25]
    node _complete_array_6_0_T = eq(id_claimed[0], UInt<3>("h7")) @[src/main/scala/plic/PlicCore.scala 70:46]
    node _complete_array_6_0_T_1 = and(_complete_array_6_0_T, io.complete[0]) @[src/main/scala/plic/PlicCore.scala 70:61]
    complete_array_6[0] <= _complete_array_6_0_T_1 @[src/main/scala/plic/PlicCore.scala 70:28]
    node _claim_array_7_0_T = eq(io.id[0], UInt<4>("h8")) @[src/main/scala/plic/PlicCore.scala 69:38]
    node _claim_array_7_0_T_1 = and(_claim_array_7_0_T, io.claim[0]) @[src/main/scala/plic/PlicCore.scala 69:53]
    claim_array_7[0] <= _claim_array_7_0_T_1 @[src/main/scala/plic/PlicCore.scala 69:25]
    node _complete_array_7_0_T = eq(id_claimed[0], UInt<4>("h8")) @[src/main/scala/plic/PlicCore.scala 70:46]
    node _complete_array_7_0_T_1 = and(_complete_array_7_0_T, io.complete[0]) @[src/main/scala/plic/PlicCore.scala 70:61]
    complete_array_7[0] <= _complete_array_7_0_T_1 @[src/main/scala/plic/PlicCore.scala 70:28]
    node _gateways_0_io_claim_T = orr(claim_array_0[0]) @[src/main/scala/plic/PlicCore.scala 76:51]
    gateways_0.io.claim <= _gateways_0_io_claim_T @[src/main/scala/plic/PlicCore.scala 76:26]
    node _gateways_0_io_complete_T = orr(complete_array_0[0]) @[src/main/scala/plic/PlicCore.scala 77:57]
    gateways_0.io.complete <= _gateways_0_io_complete_T @[src/main/scala/plic/PlicCore.scala 77:29]
    io.ip[0] <= gateways_0.io.ip @[src/main/scala/plic/PlicCore.scala 78:14]
    node _gateways_1_io_claim_T = orr(claim_array_1[0]) @[src/main/scala/plic/PlicCore.scala 76:51]
    gateways_1.io.claim <= _gateways_1_io_claim_T @[src/main/scala/plic/PlicCore.scala 76:26]
    node _gateways_1_io_complete_T = orr(complete_array_1[0]) @[src/main/scala/plic/PlicCore.scala 77:57]
    gateways_1.io.complete <= _gateways_1_io_complete_T @[src/main/scala/plic/PlicCore.scala 77:29]
    io.ip[1] <= gateways_1.io.ip @[src/main/scala/plic/PlicCore.scala 78:14]
    node _gateways_2_io_claim_T = orr(claim_array_2[0]) @[src/main/scala/plic/PlicCore.scala 76:51]
    gateways_2.io.claim <= _gateways_2_io_claim_T @[src/main/scala/plic/PlicCore.scala 76:26]
    node _gateways_2_io_complete_T = orr(complete_array_2[0]) @[src/main/scala/plic/PlicCore.scala 77:57]
    gateways_2.io.complete <= _gateways_2_io_complete_T @[src/main/scala/plic/PlicCore.scala 77:29]
    io.ip[2] <= gateways_2.io.ip @[src/main/scala/plic/PlicCore.scala 78:14]
    node _gateways_3_io_claim_T = orr(claim_array_3[0]) @[src/main/scala/plic/PlicCore.scala 76:51]
    gateways_3.io.claim <= _gateways_3_io_claim_T @[src/main/scala/plic/PlicCore.scala 76:26]
    node _gateways_3_io_complete_T = orr(complete_array_3[0]) @[src/main/scala/plic/PlicCore.scala 77:57]
    gateways_3.io.complete <= _gateways_3_io_complete_T @[src/main/scala/plic/PlicCore.scala 77:29]
    io.ip[3] <= gateways_3.io.ip @[src/main/scala/plic/PlicCore.scala 78:14]
    node _gateways_4_io_claim_T = orr(claim_array_4[0]) @[src/main/scala/plic/PlicCore.scala 76:51]
    gateways_4.io.claim <= _gateways_4_io_claim_T @[src/main/scala/plic/PlicCore.scala 76:26]
    node _gateways_4_io_complete_T = orr(complete_array_4[0]) @[src/main/scala/plic/PlicCore.scala 77:57]
    gateways_4.io.complete <= _gateways_4_io_complete_T @[src/main/scala/plic/PlicCore.scala 77:29]
    io.ip[4] <= gateways_4.io.ip @[src/main/scala/plic/PlicCore.scala 78:14]
    node _gateways_5_io_claim_T = orr(claim_array_5[0]) @[src/main/scala/plic/PlicCore.scala 76:51]
    gateways_5.io.claim <= _gateways_5_io_claim_T @[src/main/scala/plic/PlicCore.scala 76:26]
    node _gateways_5_io_complete_T = orr(complete_array_5[0]) @[src/main/scala/plic/PlicCore.scala 77:57]
    gateways_5.io.complete <= _gateways_5_io_complete_T @[src/main/scala/plic/PlicCore.scala 77:29]
    io.ip[5] <= gateways_5.io.ip @[src/main/scala/plic/PlicCore.scala 78:14]
    node _gateways_6_io_claim_T = orr(claim_array_6[0]) @[src/main/scala/plic/PlicCore.scala 76:51]
    gateways_6.io.claim <= _gateways_6_io_claim_T @[src/main/scala/plic/PlicCore.scala 76:26]
    node _gateways_6_io_complete_T = orr(complete_array_6[0]) @[src/main/scala/plic/PlicCore.scala 77:57]
    gateways_6.io.complete <= _gateways_6_io_complete_T @[src/main/scala/plic/PlicCore.scala 77:29]
    io.ip[6] <= gateways_6.io.ip @[src/main/scala/plic/PlicCore.scala 78:14]
    node _gateways_7_io_claim_T = orr(claim_array_7[0]) @[src/main/scala/plic/PlicCore.scala 76:51]
    gateways_7.io.claim <= _gateways_7_io_claim_T @[src/main/scala/plic/PlicCore.scala 76:26]
    node _gateways_7_io_complete_T = orr(complete_array_7[0]) @[src/main/scala/plic/PlicCore.scala 77:57]
    gateways_7.io.complete <= _gateways_7_io_complete_T @[src/main/scala/plic/PlicCore.scala 77:29]
    io.ip[7] <= gateways_7.io.ip @[src/main/scala/plic/PlicCore.scala 78:14]
    inst tgt of PlicTarget @[src/main/scala/plic/PlicCore.scala 83:21]
    tgt.clock <= clock
    tgt.reset <= reset
    tgt.io.rst_n <= io.rst_n @[src/main/scala/plic/PlicCore.scala 84:18]
    tgt.io.id_i[0] <= id_array_0_0 @[src/main/scala/plic/PlicCore.scala 87:22]
    tgt.io.priority_i[0] <= pr_array_0_0 @[src/main/scala/plic/PlicCore.scala 88:28]
    tgt.io.id_i[1] <= id_array_0_1 @[src/main/scala/plic/PlicCore.scala 87:22]
    tgt.io.priority_i[1] <= pr_array_0_1 @[src/main/scala/plic/PlicCore.scala 88:28]
    tgt.io.id_i[2] <= id_array_0_2 @[src/main/scala/plic/PlicCore.scala 87:22]
    tgt.io.priority_i[2] <= pr_array_0_2 @[src/main/scala/plic/PlicCore.scala 88:28]
    tgt.io.id_i[3] <= id_array_0_3 @[src/main/scala/plic/PlicCore.scala 87:22]
    tgt.io.priority_i[3] <= pr_array_0_3 @[src/main/scala/plic/PlicCore.scala 88:28]
    tgt.io.id_i[4] <= id_array_0_4 @[src/main/scala/plic/PlicCore.scala 87:22]
    tgt.io.priority_i[4] <= pr_array_0_4 @[src/main/scala/plic/PlicCore.scala 88:28]
    tgt.io.id_i[5] <= id_array_0_5 @[src/main/scala/plic/PlicCore.scala 87:22]
    tgt.io.priority_i[5] <= pr_array_0_5 @[src/main/scala/plic/PlicCore.scala 88:28]
    tgt.io.id_i[6] <= id_array_0_6 @[src/main/scala/plic/PlicCore.scala 87:22]
    tgt.io.priority_i[6] <= pr_array_0_6 @[src/main/scala/plic/PlicCore.scala 88:28]
    tgt.io.id_i[7] <= id_array_0_7 @[src/main/scala/plic/PlicCore.scala 87:22]
    tgt.io.priority_i[7] <= pr_array_0_7 @[src/main/scala/plic/PlicCore.scala 88:28]
    tgt.io.threshold_i <= io.threshold[0] @[src/main/scala/plic/PlicCore.scala 90:24]
    io.ireq[0] <= tgt.io.ireq_o @[src/main/scala/plic/PlicCore.scala 91:16]
    io.id[0] <= tgt.io.id_o @[src/main/scala/plic/PlicCore.scala 92:14]

