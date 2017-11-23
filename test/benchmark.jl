import Reactive
using BenchmarkTools
using StaticArrays
Reactive.async_mode.x = false

@testset "benchmark" begin
    println("")
    Signals.async_mode(false)
    n = 20
    signals = Vector{Signal}()
    push!(signals,Signal(1))
    for i=1:n
        A = Signal(signals[i];state = 0) do x,state
            state.x += 1
            x+1
        end
        push!(signals,A)
    end
    A = signals[1]
    ptime = @belapsed begin;$A[] = 0 ;$signals[end]();end
    ptime = @belapsed begin;$A[] = 0 ;$signals[end]();end
    println("Signals function call overhead on pull = $(ptime*1e9/n)ns") == nothing

    ptime = @belapsed begin $A(1);end
    println("Signals function call overhead on push = $(ptime*1e9/n)ns") == nothing

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
    rtime = @belapsed Reactive.push!($A,Reactive.value($A))

    println("Reactive function call overhead = $(rtime*1e9/n)ns") == nothing
    @test ptime < rtime

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
    ptime = @belapsed begin;$A[] = $Z ;$G();end
    println("Signals function call time on pull (4x4 SArray multiply)= $(ptime*1e9/2)ns") == nothing
    ptime = @belapsed begin $A($Z);end
    println("Signals function call time on push (4x4 SArray multiply) = $(ptime*1e9/2)ns") == nothing

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
    rtime = @belapsed Reactive.push!($A,Reactive.value($A))
    println("Reactive function call time on push (4x4 SArray multiply) = $(rtime*1e9/2)ns") == nothing
    @test ptime < rtime

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
    ptime = @belapsed begin;$A[] = $Z ;$G();end
    println("Signals function call time on pull (4x4 Matrix)= $(ptime*1e9/2)ns") == nothing
    ptime = @belapsed begin $A($Z);end
    println("Signals function call time on push (4x4 Matrix) = $(ptime*1e9/2)ns") == nothing

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
    rtime = @belapsed Reactive.push!($A,Reactive.value($A))
    println("Reactive function call time on push (4x4 Matrix) = $(rtime*1e9/2)ns") == nothing
    @test ptime < rtime




end
