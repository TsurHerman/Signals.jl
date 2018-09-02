
struct TypedSignal{T}
    s::Signal
end

add_child!(arg::TypedSignal,s::Signal) = add_child!(arg.s,s)

(s::TypedSignal)() = pull!(s)

(ts::TypedSignal{T})((@nospecialize val)) where T = push!(ts.s, isa(val,T) ?
    val : convert(T,val))


pull!(ts::TypedSignal{T}) where T = begin
    val = pull!(ts.s)
    (typeof(val) == T) ? val : convert(T,val)
end::T

TypedSignal(val) = TypedSignal{typeof(val)}(Signal(val))

TypedSignal(s::Signal) = TypedSignal{typeof(s())}(s)

TypedSignal(f::Function,args...;kwargs...) = begin
    s = Signal(f,args...;kwargs...)
    ts = TypedSignal(s)
end

TypedSignal{T}(f::Function,args...;kwargs...) where T = TypedSignal{T}(Signal(f,args...;kwargs...))

Base.show(io::IO, ::MIME"text/plain",@nospecialize ts::TypedSignal{T}) where T = begin
    state_str = try
        convert(T,ts[])
        ""
    catch err
        "(type mismatch: $(typeof(ts[])))"
    end
    valid_str = valid(ts.s) ? "" : "(invalidated)"
    printstyled(io, "$(typeof(ts))"; bold = true,color = 200)
    print(io, "$valid_str $state_str \nvalue: ", ts[])
end


export TypedSignal

function getindex(ts::TypedSignal)
    value(ts.s)
end

import Base.setindex!
function setindex!(ts::TypedSignal,val)
    set_value!(ts.s, val)
end
