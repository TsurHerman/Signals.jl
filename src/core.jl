mutable struct SignalData
    x
    valid::Bool
    SignalData(x) = new(x,true)
    SignalData() = new(nothing,false)
end
import Base.convert
convert(::T,x) where T = SignalData(x)
invalidate!(sd::SignalData) = sd.valid = false
store!(sd::SignalData,val) = begin sd.x = val;sd.valid = true;val;end

struct Signal
    data::SignalData
    update_signal::Function
    children::Vector{Signal}
    preserve_push::Bool
    state::SignalData
end

@generated function call_on_pull!(f::Function,args...)
    exp = Vector{Expr}(length(args))
    for (i,arg) in  enumerate(args)
        if arg == Signal
            exp[i] = :(pull!(args[$i]))
        else
            exp[i] = :(args[$i])
        end
    end
    return Expr(:call,:f,exp...)
end

abstract type NoSelf end
Signal(f::Function,args...;self = NoSelf , preserve_push = false) = begin
    state = SignalData(nothing)
    if self != NoSelf
        _state = SignalData(self)
        _args = (args...,_state)
    else
        _state = state
        _args = args
    end
    Signal(preserve_push,_state,f,_args...)
end

Signal(preserve_push::Bool,state::SignalData,f::Function,args...) = begin
    sd = SignalData()
    update_signal() = store!(sd,call_on_pull!(f,args...))

    s = Signal(sd,update_signal,Signal[],preserve_push,state)
    s()

    for arg in args
        isa(arg,Signal) && push!(arg.children,s)
    end
    s
end

Signal(val;kwargs...) = begin
    Signal(()->val;kwargs...)
end

@inline value(s::Signal) = value(s.data)
@inline value(sd::SignalData) = sd.x
value(s) = s

valid(s) = true
valid(s::Signal) = valid(s.data)
valid(sd::SignalData) = sd.valid

import Base.getindex
function getindex(s::Signal)
    value(s)
end

import Base.setindex!
function setindex!(s::Signal,val)
    set_value!(s,val)
end

function set_value!(s::Signal,val)
    invalidate!(s)
    store!(s,val)
end
store!(s::Signal,val) = store!(s.data,val)

function invalidate!(s::Signal)
    if valid(s)
        invalidate!(s.data)
        foreach(invalidate!,s.children)
    end
end
