using Proactive: Signal,pull!
using Base.Test

# typ = Matrix
typ = SMatrix{4,4,Float64,16}
base_n = 4
n = 8
RNG = srand(1234567)
signals = Signal[Signal(typ(rand(RNG,4,4))) for i=1:base_n]
for i=1:n
    A = rand(RNG,signals)
    B = rand(RNG,signals)
    E = Signal(A,B) do a,b
        a*b
    end
    push!(signals,E)
end

Z = typ(zeros(4,4))
A = signals[2]
G = signals[end]

@benchmark $A($Z)

@benchmark G()




using Reactive
Reactive.async_mode.x = false

typ = SMatrix{4,4,Float64,16}
base_n = 4
n = 24
RNG = srand(1234567)
signals = Signal[Signal(typ(rand(RNG,4,4))) for i=1:base_n]
for i=1:n
    A = rand(RNG,signals)
    B = rand(RNG,signals)
    E = map(A,B) do a,b
        a*b
    end
    push!(signals,E)
end

Z = typ(zeros(4,4))
A = signals[1]
G = signals[end]

@benchmark push!($A,$Z)











nothing
