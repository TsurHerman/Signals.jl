mutable struct SignalData
    x
    valid::Bool
    SignalData(x) = new(x,true)
    SignalData() = new(nothing,false)
end

struct Signal
    data::SignalData
    update_signal::Function
    children::Vector{Signal}
    preserve_push::Bool
    state::SignalData
end

@inline store!(sd::SignalData,val) = begin sd.x = val;sd.valid = true;val;end
@inline store!(s::Signal,val) = store!(s.data,val)

@inline value(s::Signal) = value(s.data)
@inline value(sd::SignalData) = sd.x
@inline value(s) = s

@inline state(s::Signal) = value(s.state)

@inline valid(s) = true
@inline valid(s::Signal) = valid(s.data)
@inline valid(sd::SignalData) = sd.valid

Signal(val;kwargs...) = begin
    Signal(()->val;kwargs...)
end

abstract type Stateless end
Signal(f::Function,args...;state = Stateless , preserve_push = false) = begin
    _state = SignalData(nothing)
    if state != Stateless
        store!(_state,state)
        args = (args...,_state)
    end
    Signal(preserve_push,_state,f,args...)
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

function invalidate!(s::Signal)
    if valid(s)
        invalidate!(s.data)
        foreach(invalidate!,s.children)
    end
end

invalidate!(sd::SignalData) = sd.valid = false
