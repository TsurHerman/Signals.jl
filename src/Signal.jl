mutable struct SignalData
    x
    valid::Bool
    propagated::Bool
end
SignalData(x) = SignalData(x,true,false)
SignalData() = SignalData(nothing,false,false)
SignalData(::Void) = SignalData()

struct Signal
    data::SignalData
    action::PullAction
    children::Vector{Signal}
    binders::Vector{Signal}
    strict_push::Bool
    state::Ref
end

store!(sd::SignalData,val) = begin
     sd.propagated = false
     sd.valid = true;
     sd.x = val
 end
store!(s::Signal,val) = store!(s.data,val)

value(s::Signal) = value(s.data)
value(sd::SignalData) = sd.x

"""Retrieve the internal state of a `Signal`"""
state(s::Signal) = state(s.state)
state(ref::Ref) = ref.x
state(s::Signal,val) = state(s.state,val)
state(ref::Ref,val) = ref.x = val

propagated(s::Signal) = propagated(s.data)
propagated(sd::SignalData) = sd.propagated
propagated(s::Signal,val::Bool) = propagated(s.data,val)
propagated(sd::SignalData,val::Bool) = sd.propagated = val


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
    s=Signal(sd,action,_state,strict_push)
    v0 == nothing && s()
    s
end

Signal(sd::SignalData,action::PullAction,state = Stateless, strict_push = false) = begin
    debug_mode() && finalizer(sd,x-> @schedule println("signal deleted"))

    s = Signal(sd,action,Signal[],Signal[],strict_push,Ref(state))
    for arg in action.args
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

invalidate!(sd::SignalData) = begin
    sd.valid = false
    sd.propagated = false
end

validate(s::Signal) = begin
    valid(s) && return
    if valid(s.action)
        validate(s.data)
        foreach(validate,s.children)
    end
end

validate(sd::SignalData) = begin
    sd.propagated = false
    sd.valid = true
end

import Base.show
show(io::IO, s::Signal) = show(io,MIME"text/plain"(),s)

show(io::IO, ::MIME"text/plain", s::Signal) = begin
    state_str = "\nstate{$(typeof(s.state.x))}: $(s.state.x)"
    state_str = state(s) == Signals.Stateless ? "" : state_str
    valid_str = valid(s) ? "" : "(invalidated)"
    print_with_color(200,io,"Signal";bold = true)
    print(io, "$valid_str $state_str \nvalue: ",s[])
end
