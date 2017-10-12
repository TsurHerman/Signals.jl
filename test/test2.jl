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


using Proactive
Proactive.async_mode(true)
Proactive.debug_mode(true)

A = Signal(1)
B = Signal(1)

derA = Signal(A;state = 0) do a,state
    state.x += 1
    println("derived from A $a")
end

derB = Signal(B;state = 0) do b,state
    state.x += 1
    println("derived from B $b")
end

bind!(A,B,true)
