FIRRTL version 1.2.0
circuit PlicCell :
  module PlicCell :
    input clock : Clock
    input reset : UInt<1>
    input io_rst_n : UInt<1> @[src/main/scala/plic/PlicCell.scala 18:14]
    input io_ip : UInt<1> @[src/main/scala/plic/PlicCell.scala 18:14]
    input io_ie : UInt<1> @[src/main/scala/plic/PlicCell.scala 18:14]
    input io_priority : UInt<3> @[src/main/scala/plic/PlicCell.scala 18:14]
    output io_id : UInt<4> @[src/main/scala/plic/PlicCell.scala 18:14]
    output io_priorityOut : UInt<3> @[src/main/scala/plic/PlicCell.scala 18:14]

    node _asyncReset_T = eq(io_rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicCell.scala 20:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicCell.scala 20:32]
    reg priorityReg : UInt<3>, clock with :
      reset => (asyncReset, UInt<3>("h0")) @[src/main/scala/plic/PlicCell.scala 23:20]
    reg idReg : UInt<4>, clock with :
      reset => (asyncReset, UInt<4>("h0")) @[src/main/scala/plic/PlicCell.scala 24:20]
    node _T = and(io_ip, io_ie) @[src/main/scala/plic/PlicCell.scala 28:14]
    node _GEN_0 = mux(_T, io_priority, UInt<1>("h0")) @[src/main/scala/plic/PlicCell.scala 28:24 29:17 32:17]
    node _GEN_1 = mux(_T, UInt<3>("h5"), UInt<1>("h0")) @[src/main/scala/plic/PlicCell.scala 28:24 30:11 33:11]
    io_id <= idReg @[src/main/scala/plic/PlicCell.scala 37:9]
    io_priorityOut <= priorityReg @[src/main/scala/plic/PlicCell.scala 36:18]
    priorityReg <= _GEN_0 @[src/main/scala/plic/PlicCell.scala 23:{20,20}]
    idReg <= pad(_GEN_1, 4) @[src/main/scala/plic/PlicCell.scala 24:{20,20}]
