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
    n = 20
    signals = Vector{Signal}()
    push!(signals,Signal(1))
    for i=1:n
        A = Signal(signals[i]) do x
            x+1
        end
        push!(signals,A)
    end
    A = signals[1]
    ptime = @belapsed begin;$A[] = 0 ;$signals[end]();end
    println("Proactive function call overhead on pull = $(ptime*1e9/n)ns") == nothing

    ptime = @belapsed begin $A(1);end
    println("Proactive function call overhead on push = $(ptime*1e9/n)ns") == nothing

    signals = Vector{Reactive.Signal}()
    push!(signals,Reactive.Signal(1))
    for i=1:n
        A = Reactive.map(signals[i]) do x
            x+1
        end
        push!(signals,A)
    end
    A = signals[1]

    rtime = @belapsed Reactive.push!($A,Reactive.value($A))
    println("Reactive function call overhead = $(rtime*1e9/n)ns") == nothing
    @test ptime < rtime
end
