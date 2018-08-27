
struct SignalException <: Exception
    e
    st
end

Base.showerror(io::IO, ex::SignalException, bt; backtrace=true) = begin
    st = ex.st
    !debug_mode() && (st = clean_stacktrace(st))
    fmt_st = [(st[i],i) for i=1:length(st)]
    showerror(io, ex.e, fmt_st; backtrace=true)
end

Base.show(io::IO,ex::SignalException) = begin
    Base.showerror(io::IO,ex,nothing; backtrace = true)
end

function handle_err(e, st)
    throw(SignalException(e,st))
end


function clean_stacktrace(st)
    idx = findfirst([sf.func === :pull! for sf in st])
    idx = idx === 0 ? length(st) : idx
    idx = idx === 1 ? 2 : idx
    st = st[1:(idx-1)]
end
