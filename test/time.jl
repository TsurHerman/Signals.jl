@testset "fps and every" begin
    #warmup
    A = fps(10; duration = 1)
    pA = previous(A)
    C = Signal(-, A, pA)
    nupdates = count(C)
    sum_updates = foldp(+, 0, C)
    avg_delay = Signal(/, sum_updates, nupdates)
    Signals.run_till_now()
    switch = Signal(false)
    A = fpswhen(switch, 10; duration = 1)

    #fps
    for tv in [true, false]
        Signals.async_mode(tv)
        A = fps(10; duration = 1)
        pA = previous(A)
        C = Signal(-, A, pA)
        nupdates = count(C)
        sum_updates = foldp(+, 0, C)
        avg_delay = Signal(/, sum_updates, nupdates)
        sleep(1)
        @test abs(avg_delay() - 1/10) < 0.05 # relax test to pass appveyor build test

        #every
        A = every(1/10; duration = 1.5)
        pA = previous(A)
        C = Signal(-, A, pA)
        nupdates = count(C)
        sum_updates = foldp(+, 0, C)
        avg_delay = Signal(/, sum_updates, nupdates)
        sleep(1)
        @test abs(avg_delay() - 1/10) < 0.05

        #fpswhen
        switch = Signal(false)
        A = fpswhen(switch, 10; duration = 1.2)
        C = count(A)
        sleep(1)
        @test C() <= 1

        switch(true)
        sleep(1.5)
        @test C() >= 9 # relax test to pass appveyor build test
    end
end

@testset "throttle and debounce" begin
    for tv in [true, false]
        Signals.async_mode(tv)
        #throttle
        A = every(1/100; duration = 1)
        C = throttle(x->x, A; maxfps = 10)
        nupdates = count(C)
        sleep(1)
        @test nupdates() <= 10

        #debounce
        A = Signal(time())
        B = debounce(A; delay = 1 ) do a
            time() - a
        end

        A(time())
        sleep(1.2)
        @test B() >= 1 # relax the test for appveyor windows
    end
end

@testset "for_signal" begin
    for tv in [true, false]
        Signals.async_mode(tv)
        #for_signal
        range = Signal(1:5)
        A = Signal(2)
        B = for_signal(range, A; fps = 30) do i, a
            # println(a^i)
            i+a
        end
        C = foldp(+, 0, B)
        D = count(B)
        @test D() == 1
        @test C() == 3

        D(0); state(D, 0)
        C(0)
        A(1)
        sleep(1)
        @test D() == 5
        @test C() == A()*5+6*5/2
    end
end

@testset "buffer" begin
    #warmup
    A = fps(30; duration = 1)
    B = buffer(A; buf_size = Inf, timespan = 0.5, type_stable = true)
    sleep(1)
    typeof(B()) == Vector{typeof(A())}
    abs(B()[end] - B()[1] - 0.5) < 0.15
    Signals.run_till_now()

    for tv in [true, false]
        Signals.async_mode(tv)
        A = Signal(2; strict_push = true)
        B = buffer(A; buf_size = 3, timespan = Inf)
        @test B() == [2]
        A(1.2)
        B() == [2, 1.2]
        @test typeof(B()) == Vector{Any}
        A(10); A(11); yield()
        @test B() == [2, 1.2, 10]
        A(12); A(13); yield()
        @test B() == [11, 12, 13]

        A = fps(30; duration = 1)
        B = buffer(A; buf_size = Inf, timespan = 0.5, type_stable = true)
        sleep(2)
        @test typeof(B()) == Vector{typeof(A())}
        @test abs(B()[end] - B()[1] - 0.5) < 0.15
    end
end
