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

@testset "strict_push" begin
    Proactive.async_mode(true)
    A_strict = Signal(1; strict_push = true)
    B_strict = Signal(A_strict;state = 0) do a,state
        state.x += a
        a + 1
    end

    A_soft = Signal(1)
    B_soft = Signal(A_soft;state = 0) do a,state
        state.x += a
        a + 1
    end

    A_soft(0);sleep(1) #restart the eventlopp

    @test B_soft.state.x == 1
    A_soft(10);A_soft(100);
    yield()
    @test B_soft.state.x == 101

    @test B_strict.state.x == 1
    A_strict(10);A_strict(100);
    yield()
    @test B_strict.state.x == 111
end
