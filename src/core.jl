mutable struct SignalData
    x
    valid::Bool
end
SignalData(x) = SignalData(x,true)
SignalData() = SignalData(nothing,false)

struct SignalAction{ARGS} <: Function
    f::Function
    args::ARGS
    sd::SignalData
end

pull_args(args) = map(args) do arg
    typeof(arg) != Signal ? arg : pull!(arg)
end
value_args(args) = map(args) do arg
    typeof(arg) != Signal ? arg : value(arg)
end
valid_args(args) = all(args) do arg
    typeof(arg) != Signal ? true : valid(arg)
end


struct Signal
    data::SignalData
    action::SignalAction
    children::Vector{Signal}
    strict_push::Bool
    drop_repeats::Bool
    state::Ref
end

pull_args(s::Signal) = pull_args(s.action)
pull_args(sa::SignalAction) = pull_args(sa.args)


@inline store!(sd::SignalData,val) = begin sd.x = val;sd.valid = true;val;end
@inline store!(s::Signal,val) = store!(s.data,val)
@inline store!(sa::SignalAction,x) = store!(sa.sd,x)


@inline value(s::Signal) = value(s.data)
@inline value(sd::SignalData) = sd.x

@inline state(s::Signal) = s.state.x

@inline valid(s::Signal) = valid(s.data)
@inline valid(sd::SignalData) = sd.valid
@inline valid(sa::SignalAction) = valid_args(sa.args)

Signal(val;kwargs...) = begin
    Signal(()->val;kwargs...)
end

abstract type Stateless end
Signal(f::Function,args...;state = Stateless , strict_push = false , drop_repeats = false) = begin
    _state = Ref(state)
    if state != Stateless
        args = (args...,_state)
    end
    Signal(strict_push,drop_repeats,_state,f,args...)
end

Signal(strict_push::Bool,drop_repeats::Bool,state::Ref,f::Function,args...) = begin
    sd = SignalData(f(pull_args(args)...))
    action = SignalAction(f,args,sd)

    s = Signal(sd,action,Signal[],strict_push,drop_repeats,state)

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
