
abstract type DropRepeats <: PullType end
"""
    droprepeats(input)

Drop updates to `input` whenever the new value is the same
as the previous value of the signal.
"""
droprepeats(s) = Signal(x->x,s;pull_type = DropRepeats)
export droprepeats

(pa::PullAction{DropRepeats,A})(s) where A = begin
    args = pull_args(pa)
    if !valid(s)
        old_val = value(s)
        res = pa.f(args...)
        if old_val == res
            validate(s)
        end
        store!(s,res)
    end
    value(s)
end

abstract type Filter <: PullType end
import Base.filter
"""
    filter(f, default, signal)

remove updates from the `signal` where `f` returns `false`. The filter will hold
the value default until f(value(signal)) returns true, when it will be updated
to value(signal).
"""
filter(f::Function,v0,s::Signal) = begin
    sd = SignalData(f(s[]) ? s[] : v0)
    action = PullAction(f,(s,),Filter)
    Signal(sd,action)
end

(pa::PullAction{Filter,Tuple{Signal}})(s) = begin
    source_val = pull!(pa.args[1])
    if !valid(s)
        if pa.f(source_val)
            store!(s,source_val)
        else
            validate(s)
        end
    end
    value(s)
end

abstract type When <: PullType end
"""
    when(f, condition::Signal, args... ; v0 = nothing)

creates a `Signal` that will update to `f(args...)` when any of its input `args`
updates *only if* `condition` has value `true`. if `condition != true` in
the time of creation the signal will be initialized to value `v0`
# Example

    julia> A = Signal(1)
    julia> condition = Signal(A) do a
               a<10
           end
    julia> B = when(condition,A) do a
           println("\$a is smaller than 10")
       end
    julia> A(1)
    1 is smaller than 10
    1

    julia> A(12)
    12
"""
when(f::Function,condition::Signal,args...; v0 = nothing) = begin
    action = PullAction(f,args,When)
    sd = SignalData(condition() ? action() : v0)
    s = Signal(sd,action,condition)
    push!(condition.children,s) #update signal graph if condition changes to true
    s
end
export when

(pa::PullAction{When,A})(s) where A = begin
    condition = s.state.x
    args = pull_args(pa)
    if !valid(s)
        if condition() == true
            store!(s,pa.f(args...))
        else
            validate(s)
        end
    end
    value(s)
end

"""
    sampleon(A, B)

Sample the value of `B` whenever `A` updates.
"""
function sampleon(A,B)
    Signal(x->B(),A)
end
export sampleon

"""
fold over past values

    foldp(op, v0 ,sig)

reduce the given signal `sig` with the given binary operator `op`.
 the value of the signal just after creation is `op(v0,sig[])`
"""
function foldp(op::Function,v0,sig::Signal)
    acc = SignalData(op(v0,sig()))
    action = PullAction((acc,sig)) do acc,s
        op(value(acc),s)
    end
    Signal(acc,action)
end
export foldp

abstract type Merge <: PullType end
import Base.merge
"""
    merge(s::Signal,rest...)

Merge many signals into one. Returns a signal which updates when
any of the inputs update. If many signals update at the same time,
the value of the *last* non-valid(updated) input signal in the argument list is taken.
"""
function merge(in1::Signal, rest::Signal...)
    args = (in1,rest...)
    proxy_args = map(args) do arg
        Signal(x->x,arg)
    end
    sd = SignalData(value(last(args)))
    action = PullAction(()->nothing,proxy_args,Merge)
    Signal(sd,action)
end

(pa::PullAction{Merge,A})(s) where A = begin
    res = s[]
    for arg in pa.args
        if !valid(arg)
            pull!(arg)
            if !valid(s)
                res = arg[]
            end
        end
    end
    store!(s,res)
end

"""
    echo(s::Signal,name = "")

echos the value of signal `s` on each update, you can specify a `name` to distinguish between different echos
"""
function echo(s::Signal,name = "")
    Signal(x->println("signal $name value : $x"),s)
end
export echo

abstract type RecursionFree <: PullType end
"""
    recursion_free(f::Function,args...)

creates a `Signal` whos action `f(args...)` is protected against infinite
loop recursion.

    julia> A = Signal(1)
    julia> B = recursion_free(A) do a
                A(a+1)
           end

    julia> A(10)
    10
    julia> A[]
    11
In the example above ,if `recursion_free` were to be subsituted
with regular `Signal` it would result in an infinite loop in the non-async mode
`recursion_free` protects against that

"""
function recursion_free(f::Function,args...)
    action = PullAction(f,args,RecursionFree)
    sd = SignalData(action())
    s = Signal(sd,action,false)
    for arg in args
        if typeof(arg) <: Signal
            #move to the top of the food chain
            unshift!(arg.children,pop!(arg.children))
        end
    end
end
export recursion_free

(pa::PullAction{RecursionFree,A})(s) where A = begin
    if s.state.x == true
        validate(s.data)
        validate(s)
    else
        s.state.x = true
        args = pull_args(pa)
        if !valid(s)
            store!(s,pa.f(args...))
        end
    end
    s.state.x = false
    value(s)
end

import Base.count
"""

    count_signal(s::Signal)
Create a `Signal` that counts updates to input `Signal` `s`
"""
function count(s::Signal)
    Signal(s;state = 0) do s,state
        state.x += 1
    end
end
export count

"""

    previous(s::Signal)
Create a `Signal` that holds previous input to `s`
"""
function previous(s::Signal)
    Signal(s;state = s()) do s,state
        ret = state.x
        state.x = s
        ret
    end
end
export previous
