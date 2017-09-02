mutable struct foo
    A
end


mutable struct Signal
    data
    action::Function
    children::Vector{WeakRef}
    Signal(data,f::Function) = new(data,f,WeakRef[])
end

function value(s::Signal)
    s.data
end
function value(s::T) where T
    s
end
function action(s::Signal)
    s.action
end
function _call(f::Function)
    f()
end
function call_on_value(f::Function,args::Tuple)
    f(map(value,args)...)
end
function set_value!(s::Signal,d)
     s.data = d
end

function update!(s::Signal)
    s.data = s.action()
    foreach(update!,s.children)
end

function update!(wrs::WeakRef)
    if wrs.value != nothing
        s = wrs.value
        update!(s)
    end
end

(s::Signal)(val)  = begin
    s.data = val
    foreach(update!,s.children)
end

Signal(val) = Signal(val,() -> nothing)
Signal(f::Function,arg1,arg2...) = begin
    args = (arg1,arg2...)
    g = () -> call_on_value(f,args)
    s = Signal(g(),g)
    for arg in args
        isa(arg,Signal) && push!(arg.children,WeakRef(s))
    end
    s
end

A = Signal(@SMatrix rand(4,4))

B = Signal(@SMatrix rand(4,4))

C = Signal(@SMatrix rand(4,4))
D = Signal(@SMatrix rand(4,4))

E = Signal(A,B) do a,b
    a*b
end
F = Signal(C,D) do a,b
    a*b
end
Signal(E,F) do e,f
    print(e*f)
end
Z = @SMatrix zeros(4,4)
