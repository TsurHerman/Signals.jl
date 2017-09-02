
mutable struct Signal
    data
    action::Function
    children::Vector{Signal}
    Signal(data,f::Function) = begin
        s = new(data,f,Signal[])
        # finalizer(s,(s) -> @async println("finialized Signal"))
        # s
    end
end

function value(s::Signal)
    s.data
end
function value(s::T) where T
    s
end

function call_on_value(f::Function,args::Tuple)

end
function set_value!(s::Signal,d)
     s.data = d
end

function update!(s::Signal)
    s.data = s.action()
    foreach(update!,s.children)
end

(s::Signal)(val)  = begin
    s.data = val
    foreach(update!,s.children)
end


Signal(val) = Signal(val,() -> nothing)
Signal(f::Function,arg1,arg2...) = begin
    args = (arg1,arg2...)
    g = () -> f(map(value,args)...)
    s = Signal(g(),g)
    for arg in args
        isa(arg,Signal) && push!(arg.children,s)
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
G = Signal(E,F) do e,f
    e*f
end
Z = 0
