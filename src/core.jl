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

using Unrolled
pull_args(args) = unrolled_map(args) do arg
    typeof(arg) != Signal ? arg : pull!(arg)
end
value_args(args) = unrolled_map(args) do arg
    typeof(arg) != Signal ? arg : value(arg)
end
valid_args(args) = unrolled_map(args) do arg
    typeof(arg) != Signal ? true : valid(arg)
end

(sa::SignalAction{F,ARGS})(args::ARGS) where F where ARGS = begin
    _args = pull_args(sa.args)
    res = sa.f(_args...)
    store!(sa,res)
end

(sa::SignalAction{F,ARGS})() where F where ARGS = begin
    sa(sa.args)
end

(sa::SignalAction{F,Tuple{}})() where F = begin
    store!(sa,sa.f())
end
store!(sa::SignalAction,x) = store!(sa.sd,x)

struct Signal
    data::SignalData
    update_signal::Function
    children::Vector{Signal}
    preserve_push::Bool
    state::SignalData
end
pull_args(s::Signal) = pull_args(s.update_signal)
pull_args(sa::SignalAction{F,ARGS}) where F where ARGS = pull_args(sa.args)


@inline store!(sd::SignalData,val) = begin sd.x = val;sd.valid = true;val;end
@inline store!(s::Signal,val) = store!(s.data,val)

@inline value(s::Signal) = value(s.data)
@inline value(sd::SignalData) = sd.x

@inline state(s::Signal) = value(s.state)

@inline valid(s::Signal) = valid(s.data)
@inline valid(sd::SignalData) = sd.valid
@inline valid(sa::SignalAction) = valid(sa.sd)

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
@inline function setindex!(s::Signal,val::T) where T
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
