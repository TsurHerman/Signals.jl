mutable struct SignalData
    x
    valid::Bool
end
SignalData(x) = SignalData(x,true)
SignalData() = SignalData(nothing,false)
SignalData(::Void) = SignalData()

struct Signal
    data::SignalData
    action::PullAction
    children::Vector{Signal}
    binders::Vector{Signal}
    strict_push::Bool
    state::Ref
end

store!(sd::SignalData,val) = begin sd.x = val;sd.valid = true;val;end
store!(s::Signal,val) = store!(s.data,val)

value(s::Signal) = value(s.data)
value(sd::SignalData) = sd.x

state(s::Signal) = s.state.x

valid(s::Signal) = valid(s.data)
valid(sd::SignalData) = sd.valid

Signal(val;kwargs...) = begin
    Signal(()->val;kwargs...)
end

abstract type Stateless end
Signal(f::Function,args...;state = Stateless ,strict_push = false ,pull_type = StandardPull, v0 = nothing) = begin
    _state = Ref(state)
    if state != Stateless
        args = (args...,_state)
    end
    sd = SignalData(v0)
    action = PullAction(f,args,pull_type)
    Signal(sd,action,_state,strict_push)
end

Signal(sd::SignalData,action::PullAction,state = Stateless, strict_push = false) = begin
    debug_mode() && finalizer(sd,x-> @schedule println("signal deleted"))

    s = Signal(sd,action,Signal[],Signal[],strict_push,Ref(state))
    for arg in action.args
        isa(arg,Signal) && push!(arg.children,s)
    end
    s()
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

validate(s::Signal) = begin
    valid(s) && return
    if valid(s.action)
        validate(s.data)
        foreach(validate,s.children)
    end
end

validate(sd::SignalData) = sd.valid = true
