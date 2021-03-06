#!/bin/sh

_on_init ()
{   # This function is called right before entering the main loop
    _info "START genlog"
    return 0
}
_on_stop ()
{   # This function is called right after exiting the main loop
    _info "END genlog"
    return 0
}

_on_log ()
{   # This function is called right before each raw log is fired
    return 0
}

_on_batch_full ()
{   # This function is called after n raw logs are fired
    _info "Send ${occur}/${max_occurs} raw log (last batch size was ${current_batch_size})."
}

_on_sigint()
{   # This function is called if process is killed
    return 0
}

