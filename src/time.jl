"""
    s = buffer(input; buf_size = Inf, timespan = 1, type_stable = false)
creates a signal who buffers updates to signal `input` until maximum size of `buf_size`
or until `timespan` seconds have passed. The signal value is the last
full buffer emitted or an empty vector if the buffer have never
been filled before.

buffer type will be `Any` unless `type_stable` is set to `true`, then it will be set
to the value of the first encountered item
"""

function buffer(input; buf_size = Inf, timespan = 1, type_stable = false)
    _buf = type_stable ? Vector{typeof(f(pull!.(args)...))} : Vector{Any}[]
    sbuf = foldp(push!,_buf,input)
    cond = Signal(sbuf;state = time()) do in,state
        last_update = state.x
        (time() - last_update > timespan) || (length(in) >= buf_size)
    end
    when(cond,sbuf) do buf
        cond.state.x = time()
        frame = copy(buf)
        empty!(_buf)
        frame
    end
end
export buffer

"""
    debounce(f,dt,args...)
Creates a `Signal` whos action `f(args...)` will be called only after `dt` seconds have passed since the last time
its `args` were updated. only works in push based paradigm
"""
function debounce(f,dt,args...)
    ref_timer = Ref(Timer(identity,0))
    f_args = SignalAction(f,args)
    initial_value = f_args()
    debounced_signal = Signal(initial_value)
    Signal(f,args...) do args
        finilize(ref_timer.x)
        ref_timer.x = Timer(t->debounced_signal(f_args()),dt)
    end
    debounced_signal
end
export debounce

abstract type Throttle <: PullType end
"""
    throttle(f,dt,args...)
Creates a throttled `Signal` whos action `f(args...)` will be called only
if dt time has passed since the last time it updated. The resulting `Signal`
will be updated maximum of 1/dt times per second
"""
function throttle(f,dt,args...)
    Signal(f,args...;state = (dt,time()), pull_action = Throttle) do args,state
        f(args...)
    end
end
export throttle

(pa::PullAction{Throttle,A})(s) where A = begin
    (dt,last_update) = s.state.x
    args = pull_args(pa)
    if !valid(s)
        if time() - last_update < dt
            validate(s)
        else
            s.state.x = (dt,time())
            store!(s,pa.f(args...))
        end
    end
    value(s)
end


"""
    s,switch = every(dt)

A signal that updates every `dt` seconds to the current timestamp. to turn off updates
push `false` into switch `switch(false)` to turn it back on push `true` `switch(true)`
.Consider using `fps` if you want specify the timing signal by frequency, rather than delay.
"""
function every(dt)
    res = Signal(dt) do state
        time()
    end
    timer =
    push_to_ref(ref,children) = if ref.value != nothing
        # invalidate!(res)
        store!(ref.value,time())
        foreach(invalidate!,children.value)
        foreach(propogate!,children.value)
    end
    res.state.x = Timer(t->push_to_ref(ref,children),0,dt)
    finalizer(res.data,x->close(res.state.x))
    res
end
export every






nothing
