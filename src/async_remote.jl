using Distributed
@noinline call_no_inline(f,args) = f(args...)
"""
    s = async_signal(f, args...; init = nothing)

Create a signal initialized to `init` whos action `f(args...)` will run asynchronously in a
different task whenever its arguments update.async signals only work in a push based paradigm.
"""
function async_signal(f, args...; init = nothing)
    res = Signal(init)
    Signal(args...) do args...
        @async begin
            try
                res(call_no_inline(f, args))
            catch e
                st = catch_stacktrace()
                return handle_err(e, st)
            end
        end
    end
    res
end
export async_signal

"""
    s = remote_signal(f, args...; init = nothing, procid = first(workers()))

Create a signal initialized to `init` whos action `f(args...)` will run remotely in
a process with id `procid`, whenever its arguments update.remote signals only work
in a push based paradigm.
"""
function remote_signal(f, args...; init = nothing, procid = first(workers()))
    res = Signal(init)
    Signal(args...) do args...
        @async begin
             try
                 x = @fetchfrom procid call_no_inline(f, args)
                 res(x)
             catch e
                 st = [st_tuple[1] for st_tuple in e.captured.processed_bt]
                 err = e.captured.ex
                 return handle_err(err, st)
             end
        end
    end
    res
end
export remote_signal
