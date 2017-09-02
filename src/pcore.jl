
mutable struct Signal
    data
    action::Function
    children::Vector{Signal}
    Signal(data,f::Function) = new(data,f,Signal[])
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
function set_value!(s::Signal,d)
     s.data = d
end

(s::Signal)(val)  = begin
    set_value!(s,val)
    for child in s.children
        set_value!(child,_call(action(child)))
    end
end


Signal(val) = Signal(val,() -> nothing)
Signal(f::Function,arg1,arg2...) = begin
    args = (arg1,arg2...)
    s = Signal(f(value.(args)...),() -> f(value.(args)...))
    for arg in args
        isa(arg,Signal) && push!(arg.children,s)
    end
    s
end

A = Signal(@SMatrix rand(4,4))
B = Signal(@SMatrix rand(4,4))
C = Signal(A,B) do a,b
    a*b
end
Z = @SMatrix zeros(4,4)
