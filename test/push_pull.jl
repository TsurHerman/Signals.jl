@testset "push-pull" begin
    Proactive.async_mode(false)
    A = Signal(1)
    B = Signal(x->x+1,A)

    C = Signal(x->x+1,A)
    D = Signal(x->x+1,C)
    E = Signal((x,y)->x+y,B,D)
    @test E[] == 5
    A(2)
    @test E[] == 7
    A[] = 3
    @test E[] == 7 #still unaffected
    @test E() == 9 #properly pulled
    A(1.0)
    @test E[] === 5.0 #dynamic change of type
end
