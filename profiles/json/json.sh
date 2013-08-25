#!/bin/sh

_on_init ()
{   # This function is called right before entering the main loop
    _info "START genlog"
    total=0
}
_on_stop ()
{   # This function is called right after exiting the main loop
    _info "END genlog"
}

_on_log ()
{   # This function is called right after each raw log is fired
    VALUE=`_randomize 20`
    total=`expr ${total} + ${VALUE}`
}

_on_batch_full ()
{   # This function is called after n raw logs are fired (and after _on_log)
    _info "Info: Send ${occur}/${max_occurs} raw log (last batch size was ${current_batch_size})."
}

_on_sigint()
{   # This function is called if process is killed
    return 0
}

