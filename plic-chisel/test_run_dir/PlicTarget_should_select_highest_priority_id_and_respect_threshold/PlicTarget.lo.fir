FIRRTL version 1.2.0
circuit PlicTarget :
  module PlicTarget :
    input clock : Clock
    input reset : UInt<1>
    input io_rst_n : UInt<1> @[src/main/scala/plic/PlicTarget.scala 16:14]
    input io_id_i_0 : UInt<3> @[src/main/scala/plic/PlicTarget.scala 16:14]
    input io_id_i_1 : UInt<3> @[src/main/scala/plic/PlicTarget.scala 16:14]
    input io_id_i_2 : UInt<3> @[src/main/scala/plic/PlicTarget.scala 16:14]
    input io_id_i_3 : UInt<3> @[src/main/scala/plic/PlicTarget.scala 16:14]
    input io_priority_i_0 : UInt<3> @[src/main/scala/plic/PlicTarget.scala 16:14]
    input io_priority_i_1 : UInt<3> @[src/main/scala/plic/PlicTarget.scala 16:14]
    input io_priority_i_2 : UInt<3> @[src/main/scala/plic/PlicTarget.scala 16:14]
    input io_priority_i_3 : UInt<3> @[src/main/scala/plic/PlicTarget.scala 16:14]
    input io_threshold_i : UInt<3> @[src/main/scala/plic/PlicTarget.scala 16:14]
    output io_ireq_o : UInt<1> @[src/main/scala/plic/PlicTarget.scala 16:14]
    output io_id_o : UInt<3> @[src/main/scala/plic/PlicTarget.scala 16:14]

    node _asyncReset_T = eq(io_rst_n, UInt<1>("h0")) @[src/main/scala/plic/PlicTarget.scala 17:21]
    node asyncReset = asAsyncReset(_asyncReset_T) @[src/main/scala/plic/PlicTarget.scala 17:32]
    node sel = gt(io_priority_i_0, UInt<3>("h0")) @[src/main/scala/plic/PlicTarget.scala 25:32]
    node nbp = mux(sel, io_priority_i_0, UInt<3>("h0")) @[src/main/scala/plic/PlicTarget.scala 26:18]
    node nbi = mux(sel, io_id_i_0, UInt<3>("h0")) @[src/main/scala/plic/PlicTarget.scala 27:18]
    node sel_1 = gt(io_priority_i_1, nbp) @[src/main/scala/plic/PlicTarget.scala 25:32]
    node nbp_1 = mux(sel_1, io_priority_i_1, nbp) @[src/main/scala/plic/PlicTarget.scala 26:18]
    node nbi_1 = mux(sel_1, io_id_i_1, nbi) @[src/main/scala/plic/PlicTarget.scala 27:18]
    node sel_2 = gt(io_priority_i_2, nbp_1) @[src/main/scala/plic/PlicTarget.scala 25:32]
    node nbp_2 = mux(sel_2, io_priority_i_2, nbp_1) @[src/main/scala/plic/PlicTarget.scala 26:18]
    node nbi_2 = mux(sel_2, io_id_i_2, nbi_1) @[src/main/scala/plic/PlicTarget.scala 27:18]
    node sel_3 = gt(io_priority_i_3, nbp_2) @[src/main/scala/plic/PlicTarget.scala 25:32]
    node bestP = mux(sel_3, io_priority_i_3, nbp_2) @[src/main/scala/plic/PlicTarget.scala 26:18]
    node bestI = mux(sel_3, io_id_i_3, nbi_2) @[src/main/scala/plic/PlicTarget.scala 27:18]
    reg ireq_reg : UInt<1>, clock with :
      reset => (asyncReset, UInt<1>("h0")) @[src/main/scala/plic/PlicTarget.scala 31:49]
    reg id_reg : UInt<3>, clock with :
      reset => (asyncReset, UInt<3>("h0")) @[src/main/scala/plic/PlicTarget.scala 32:47]
    node _T = gt(bestP, io_threshold_i) @[src/main/scala/plic/PlicTarget.scala 34:14]
    node _GEN_0 = mux(_T, UInt<1>("h1"), UInt<1>("h0")) @[src/main/scala/plic/PlicTarget.scala 34:{32,43,77}]
    io_ireq_o <= ireq_reg @[src/main/scala/plic/PlicTarget.scala 37:13]
    io_id_o <= id_reg @[src/main/scala/plic/PlicTarget.scala 38:11]
    ireq_reg <= _GEN_0 @[src/main/scala/plic/PlicTarget.scala 31:{49,49}]
    id_reg <= bestI @[src/main/scala/plic/PlicTarget.scala 32:{47,47} 35:10]
