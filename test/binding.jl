# @testset "bind" begin
#     Proactive.async_mode(false)
#     A = Signal(1)
#     B = Signal(1)
#     C = Signal(B;state = 0) do b,state
#         state.x += 1
#         b + 1
#     end
#
#     @test B.state.x == 1
#     @test C.state.x == 1
#     A(1);A(1);
#     @test B.state.x == 1
#     @test C.state.x == 1
#     A(3.14)
#     @test B.state.x == 2
#     @test C.state.x == 2
# end
