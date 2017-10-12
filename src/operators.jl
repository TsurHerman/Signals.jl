
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
    when(f, condition::Signal, args...)

creates a conditional `Signal`\n
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
when(f::Function,condition::Signal,args...) = begin
    s = Signal(args...;pull_type = When , state = condition) do args,state
        f(args...)
    end
    push!(condition.children,s)
    s
end
export when

(pa::PullAction{When,A})(s) where A = begin
    condition = s.state.x
    args = pull_args(pa)
    if !valid(s)
        cond = condition()
        typeof(cond) != Bool && throw_condition_exception(pa)
        if cond
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
    Signal(A;state = B) do a,state
        local B = state.x
        B()
    end
end
export sampleon

"""
fold over past values

    foldp(op, v0 ,sig)

reduce the given signal `sig` with the given binary operator `op`.
 the value of the signal just after creation is `op(v0,sig[])`
"""
function foldp(op,v0,sig)
    acc = SignalData(op(v0,sig[]))
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
