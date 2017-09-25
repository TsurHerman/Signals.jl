import Reactive
using BenchmarkTools
Reactive.async_mode.x = false

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

@testset "benchmark" begin
    Proactive.async_mode(false)

    A = Signal(1)
    B = Signal(x->x+1,A)
    C = Signal(x->x+1,B)
    D = Signal(x->x+1,C)
    E = Signal(x->x+1,D)
    F = Signal(x->x+1,E)
    G = Signal(x->x+1,F)

    ptime = @belapsed $A(1)
    println("Signals function call overhead = $(ptime*1e9/6)ns") == nothing

    A = Reactive.Signal(1)
    B = map(x->x+1,A)
    C = map(x->x+1,B)
    D = map(x->x+1,C)
    E = map(x->x+1,D)
    F = map(x->x+1,E)
    G = map(x->x+1,F)

    rtime = @belapsed Reactive.push!($A,Reactive.value($A))
    println("Reactive function call overhead = $(rtime*1e9/6)ns") == nothing
    @test ptime < rtime
end
