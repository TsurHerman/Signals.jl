using Proactive
Proactive.async_mode(false)
# write your own tests here
# @test 1

typ = Matrix
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
A(Z)

@benchmark $A($Z)

@benchmark begin begin $A[] = $A[];end; $G(); end
