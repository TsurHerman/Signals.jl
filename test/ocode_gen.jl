using Proactive: Signal,store!

A = Signal(1)
B = Signal(x->x+1,A)
C = Signal(x->x+1,B)
D = Signal(x->x+1,C)
E = Signal(x->x+1,D)
F = Signal(x->x+1,E)

g(val) = () -> val
f(s::Signal) = s.update_signal.f
f(f::Function) = f.f
data(A) = A.data

fn = f(A)




@code_native fn()
