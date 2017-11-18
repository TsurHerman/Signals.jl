using Signals
Signals.async_mode(false)
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

addprocs(1)
@everywhere using Signals
Signals.async_mode(true)

A = Signal(1)
B = remote_signal(x->x+1,A)

A(10)
A("ff")

@noinline f(a,b) = a+b
a5() = try
    f("ff",1)
catch
    st = catch_stacktrace()
    println(st)
end
b = Task(a5)
A = schedule(b)





using Signals
Signals.async_mode(true)
A_strict = Signal(1; strict_push = true)
B_strict = Signal(A_strict;state = 0) do a,state
    state.x += a
    a + 1
end

A_soft = Signal(1)
B_soft = Signal(A_soft;state = 0) do a,state
    state.x += a
    a + 1
end

A_soft(0);sleep(1) #restart the eventlopp


B_strict.state.x == 1
A_strict(10);A_strict(100);
yield();
B_strict.state.x == 111
