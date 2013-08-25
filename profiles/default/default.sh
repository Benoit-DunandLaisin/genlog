#!/bin/sh

_on_init ()
{   # This function is called right before entering the main loop
    total=0
    _info "START genlog"
    MESSAGE="[`timestamp`] [EVENT] START"
    _log
}
_on_stop ()
{   # This function is called right after exiting the main loop
    _info "END genlog"
    MESSAGE="[`timestamp`] [EVENT] END"
    _log
}

_on_log ()
{   # This function is called right after each raw log is fired
    VALUE=`_randomize 20`
    total=`expr ${total} + ${VALUE}`
}

_on_batch_full ()
{   # This function is called after n raw logs are fired (and after _on_log)
    mean=`awk "BEGIN{print ${total} / ${batch_elt}}"`
    _info "Fire AGGREG event after ${occur}/${max_occurs} raw log"
    MESSAGE="[`timestamp`] [EVENT] AGGREG moy=${mean} nb=${batch_elt} total=${total}"
    _log
    total=0
}

_on_sigint()
{   # This function is called if process is killed
    MESSAGE="[`timestamp`] [EVENT] SIGINT"
    _log
}

