using Proactive: Signal,world_age
using Base.Test

# typ = Matrix
typ = SMatrix{4,4,Float64,16}
base_n = 4
n = 28
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
A = signals[1]
G = signals[end]

@benchmark $A($Z)

@benchmark G()




using Reactive
Reactive.async_mode.x = false

typ = SMatrix{4,4,Float64,16}
base_n = 4
n = 28
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

@benchmark push!(A,value(A))
value(G)

 2.87434e6  1.36207e6  2.15881e6  1.16726e6
 6.97007e5  3.30291e5  5.23494e5  2.83053e5
 1.68906e6  8.00396e5  1.26859e6  6.85924e5
 1.99949e6  9.475e5    1.50174e6  8.11988e5









nothing
