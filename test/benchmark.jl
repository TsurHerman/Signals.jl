import Reactive
using BenchmarkTools
using StaticArrays
Reactive.async_mode.x = false

@testset "benchmark" begin
    println("")
    Signals.async_mode(false)
    n = 200
    signals = Vector{Signal}()
    push!(signals,Signal(1))
    for i=1:n
        A = Signal(signals[i]) do x
            x+1
        end
        push!(signals,A)
    end
    A = signals[1]
    bench = @benchmark begin;$A[] = 0 ;$signals[end]();end;
    ptime = median(bench).time
    println("Signals function call overhead on pull = $(ptime/n)ns") == nothing

    bench = @benchmark begin $A(1);end;
    ptime = median(bench).time
    println("Signals function call overhead on push = $(ptime/n)ns") == nothing

    signals = Vector{Reactive.Signal}()
    push!(signals,Reactive.Signal(1))
    for i=1:n
        A = Reactive.map(signals[i]) do x
            x+1
        end
        push!(signals,A)
    end
    A = signals[1]
    sleep(1)

    bench = @benchmark Reactive.push!($A,Reactive.value($A))
    rtime = median(bench).time

    println("Reactive function call overhead = $(rtime/n)ns") == nothing
    # @test ptime < rtime

    println("")

    typ = SMatrix{4,4,Float64,16}
    A = Signal(typ(rand(4,4)))
    B = Signal(typ(rand(4,4)))
    C = Signal(typ(rand(4,4)))
    D = Signal(typ(rand(4,4)))
    E = Signal(A,B) do a,b
        a*b
    end
    F = Signal(C,D) do a,b
        a*b
    end
    G = Signal(E,F) do e,f
        e*f
    end
    Z = typ(zeros(4,4))
    bench = @benchmark begin;$A[] = $Z ;$G();end
    ptime = median(bench).time
    println("Signals function call time on pull (4x4 SArray multiply)= $(ptime/2)ns") == nothing
    bench = @benchmark begin $A($Z);end
    ptime = median(bench).time
    println("Signals function call time on push (4x4 SArray multiply) = $(ptime/2)ns") == nothing

    A = Reactive.Signal(typ(rand(4,4)))
    B = Reactive.Signal(typ(rand(4,4)))
    C = Reactive.Signal(typ(rand(4,4)))
    D = Reactive.Signal(typ(rand(4,4)))
    E = Reactive.map(A,B) do a,b
        a*b
    end
    F = Reactive.map(C,D) do a,b
        a*b
    end
    G = Reactive.map(E,F) do e,f
        e*f
    end
    Z = typ(zeros(4,4))
    Reactive.async_mode.x = false
    sleep(1)
    bench = @benchmark Reactive.push!($A,Reactive.value($A))
    rtime = median(bench).time
    println("Reactive function call time on push (4x4 SArray multiply) = $(rtime/2)ns") == nothing
    # @test ptime < rtime

    println("")

    typ = Matrix
    A = Signal(typ(rand(4,4)))
    B = Signal(typ(rand(4,4)))
    C = Signal(typ(rand(4,4)))
    D = Signal(typ(rand(4,4)))
    E = Signal(A,B) do a,b
        a*b
    end
    F = Signal(C,D) do a,b
        a*b
    end
    G = Signal(E,F) do e,f
        e*f
    end
    Z = typ(zeros(4,4))
    bench = @benchmark begin;$A[] = $Z ;$G();end
    ptime = median(bench).time
    println("Signals function call time on pull (4x4 Matrix)= $(ptime/2)ns") == nothing
    bench = @benchmark begin $A($Z);end
    ptime = median(bench).time
    println("Signals function call time on push (4x4 Matrix) = $(ptime/2)ns") == nothing

    A = Reactive.Signal(typ(rand(4,4)))
    B = Reactive.Signal(typ(rand(4,4)))
    C = Reactive.Signal(typ(rand(4,4)))
    D = Reactive.Signal(typ(rand(4,4)))
    E = Reactive.map(A,B) do a,b
        a*b
    end
    F = Reactive.map(C,D) do a,b
        a*b
    end
    G = Reactive.map(E,F) do e,f
        e*f
    end
    Z = typ(zeros(4,4))
    sleep(1)
    bench = @benchmark Reactive.push!($A,Reactive.value($A))
    rtime = median(bench).time
    println("Reactive function call time on push (4x4 Matrix) = $(rtime/2)ns") == nothing
    # @test ptime < rtime

end
