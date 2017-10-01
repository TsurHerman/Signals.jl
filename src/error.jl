
function isatom()
    isdefined(Main,:Atom) &&
        isdefined(Main,:Juno) &&
        Main.Juno._active == true
end

handle_err(e,st) = begin
    if isatom() && debug_mode() == false
        st = clean_stacktrace(st)
        ee = Main.Atom.EvalError(e,st)
        display(ee)
        rethrow("Signal Exception")
    else
        #TODO find out a way to do the same stacktrace prunning in normal Repl
        rethrow(e)
    end
end

clean_stacktrace(st) = begin
    idx = findfirst([sf.func == :pull! for sf in st])
    idx = idx == 0 ? length(st) : idx
    idx = idx == 1 ? 2 : idx
    st = st[1:(idx-1)]
end
