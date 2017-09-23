using Proactive: Signal,state
# write your own tests here
# @test 1
typ = Matrix
typ = SMatrix{4,4,Float64,16}

A = Signal(typ(rand(4,4)))
B = Signal(typ(rand(4,4)))

C = Signal(typ(rand(4,4)))
D = Signal(typ(rand(4,4)))

E = Signal(A,B;state = 0,drop_repeats = true) do a,b,state
    state.x += 1;
    a*b
end
F = Signal(C,D) do a,b
    a*b
end
G = Signal(E,F;state = 0) do e,f,state
    state.x += 1;
    e*f
end
Z = typ(zeros(4,4))
A(Z)

@benchmark $A($Z)

@benchmark begin begin $A[] = $A[];end; $G(); end


using Proactive: SignalData
sd = SignalData(5)

fn(f,args...;self = SignalData) = f(args...,self)

fn(1,2;self = 5) do a,b,self
    a+b+self
end
# using Reactive
# Reactive.async_mode.x = false
#
# typ = Matrix
#
# A = Signal(typ(rand(4,4)))
# B = Signal(typ(rand(4,4)))
#
# C = Signal(typ(rand(4,4)))
# D = Signal(typ(rand(4,4)))
#
# E = map(A,B) do a,b
#     a*b
# end
# F = map(C,D) do a,b
#     a*b
# end
# G = map(E,F) do e,f
#     e*f
# end
# Z = typ(zeros(4,4))
# push!(A,Z)
#
# @benchmark push!(A,Z)
#
#
#
# nothing
