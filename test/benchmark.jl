using BenchmarkTools
using StaticArrays
using Statistics

@testset "benchmark" begin
    println("")
    Signals.async_mode(false)
    n = 200
    signals = Vector{Signal}()
    push!(signals, Signal(1))
    for i = 1:n
        A = Signal(signals[i]) do x
            x + 1
        end
        push!(signals, A)
    end
    A = signals[1]
    bench = @benchmark begin; $A[] = 0; $signals[end](); end;
    ptime = median(bench).time
    println("Signals function call overhead on pull = $(ptime/n)ns") == nothing

    bench = @benchmark begin $A(1); end;
    ptime = median(bench).time
    println("Signals function call overhead on push = $(ptime/n)ns") == nothing

    println("")

    typ = SMatrix{4, 4, Float64, 16}
    A = Signal(typ(rand(4, 4)))
    B = Signal(typ(rand(4, 4)))
    C = Signal(typ(rand(4, 4)))
    D = Signal(typ(rand(4, 4)))
    E = Signal(A, B) do a, b
        a*b
    end
    F = Signal(C, D) do a, b
        a*b
    end
    G = Signal(E, F) do e, f
        e*f
    end
    Z = typ(zeros(4, 4))
    bench = @benchmark begin; $A[] = $Z; $G(); end
    ptime = median(bench).time
    println("Signals function call time on pull (4x4 SArray multiply)= $(ptime/2)ns") == nothing
    bench = @benchmark begin $A($Z); end
    ptime = median(bench).time
    println("Signals function call time on push (4x4 SArray multiply) = $(ptime/2)ns") == nothing
    println("")

    typ = Matrix
    A = Signal(typ(rand(4, 4)))
    B = Signal(typ(rand(4, 4)))
    C = Signal(typ(rand(4, 4)))
    D = Signal(typ(rand(4, 4)))
    E = Signal(A, B) do a, b
        a*b
    end
    F = Signal(C, D) do a, b
        a*b
    end
    G = Signal(E, F) do e, f
        e*f
    end
    Z = typ(zeros(4, 4))
    bench = @benchmark begin; $A[] = $Z; $G(); end
    ptime = median(bench).time
    println("Signals function call time on pull (4x4 Matrix)= $(ptime/2)ns") == nothing
    bench = @benchmark begin $A($Z); end
    ptime = median(bench).time
    println("Signals function call time on push (4x4 Matrix) = $(ptime/2)ns") == nothing

    # @test ptime < rtime

end
