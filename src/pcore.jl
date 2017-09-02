
mutable struct Signal{T}
    data::T
    action::Function
    children::Vector{Signal}
end

@inline value(s::Signal) = s.data
@inline value(s::T) where T = s
@inline action(s) = s.action()

@inline (s::Signal{T})(val) where T = begin
    s.data = convert(T,val)
    for child in s.children
        child.data = child.action()
    end
end


Signal(val) = Signal(val,() -> nothing,Vector{Signal}())
Signal(f,arg1,arg2...) = begin
    args = (arg1,arg2...)
    s = Signal(f(value.(args)...),() -> f(value.(args)...),Vector{Signal}())
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



function maps(f,input,inputs...)
    vargs = (input,inputs...)
    const args = data.(vargs)
    const ref = Ref(f(data.(args)...))
    return () -> ref.x = convert(typeof(ref.x),f(data.(args)...))
end

C = maps(A,B) do a,b
    a+b
end
