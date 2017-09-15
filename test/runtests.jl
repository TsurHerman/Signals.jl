using Proactive: Signal
using Base.Test

typ = Matrix
# typ = SMatrix{4,4,Float64,16}
base_n = 2
n = 1000
RNG = srand(1234567)
signals = Signal[Signal(typ(rand(RNG,4,4))) for i=1:base_n]
id = 0
for i=1:n
    A = rand(RNG,signals)
    B = rand(RNG,signals)
    id = id + 1
    E = Signal(A,B,id) do a,b,id
        # print("$id->")
        a+b
    end
    push!(signals,E)
end

Z = typ(zeros(4,4))
A = signals[1]
G = signals[end]

@benchmark A(Z)

@benchmark begin A[] = A[];G(); end

A = Signal(1)
B = Signal(x->x+1,A)
C = Signal(x->x+1,B)
D = Signal(x->x+1,C)
E = Signal(x->x+1,D)
F = Signal(x->x+1,E)




using Reactive
Reactive.async_mode.x = false

typ = SMatrix{4,4,Float64,16}
base_n = 2
n = 5000
RNG = srand(1234567)
signals = Signal[Signal(typ(rand(RNG,4,4))) for i=1:base_n]
counter = 0
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








nothing
