mutable struct SignalData
    x
    valid::Bool
    SignalData(x) = new(x,true)
    SignalData() = new(nothing,false)
end

struct SignalAction{F <: Function,ARGS <: Tuple} <: Function
    f::F
    args::ARGS
    sd::SignalData
end
@generated unrolled_pull_args(args...) = begin
    
(sa::SignalAction{F,ARGS})() where F where ARGS = begin
    _args = map(sa.args) do arg
        typeof(arg) != Signal ? arg : pull!(arg)
    end
    store!(sa,sa.f(_args...))
end

store!(sa::SignalAction,x) = store!(sa.sd,x)

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

@inline state(s::Signal) = value(s.state)

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
    update_signal = SignalAction(f,args,sd)

    s = Signal(sd,update_signal,Signal[],preserve_push,state)
    s()

    for arg in args
        isa(arg,Signal) && push!(arg.children,s)
    end
    s
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
