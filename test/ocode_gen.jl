using Proactive

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

store(s::Signal) = x -> store(data(s),x)
store(s::Signal,val) = s.data.x = val
store(sd::Proactive.SignalData,val) = sd.x = val


@code_native Proactive.store!(A,10)
