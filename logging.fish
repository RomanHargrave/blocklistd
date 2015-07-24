set -g __log_level 1

function __logger_format
    echo -- (date +'[%H:%M:%S %Y-%m-%d]') $argv
end

function log -a color -a message
    isatty 2; and set_color $color 1>&2
	begin
		__logger_format $message 
	end | tee -a $__log_file 1>&2
	isatty 2; and set_color normal 1>&2
end

function info
    log green "$argv"
end

function warn 
    log yellow "$argv"
end

function error
    log red "$argv"
end

function debug
    log cyan "$argv"
end
