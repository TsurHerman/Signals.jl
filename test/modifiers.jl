
@testset "drop_repeats" begin
    Proactive.async_mode(false)
    A = Signal(1)
    B = Signal(droprepeats(A);state = 0) do a,state
        state.x += 1
        a + 1
    end
    C = Signal(B;state = 0) do b,state
        state.x += 1
        b + 1
    end

    @test B.state.x == 1
    @test C.state.x == 1
    A(1);A(1);
    @test B.state.x == 1
    @test C.state.x == 1
    A(3.14)
    @test B.state.x == 2
    @test C.state.x == 2
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
