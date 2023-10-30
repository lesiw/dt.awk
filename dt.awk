#!/usr/bin/env -S busybox awk -f

BEGIN {
    if (ARGC < 2) {
        print "this is where the repl goes"
        exit 0
    }

    prog=ARGV[1]
    delete ARGV
}

/.+/ { push($0) }

END {
    eval(prog)

    for (i=0; i<ctxsz; i++)
        print ctx[i]
}

function die(msg) {
    print msg
    exit 1
}

function push(val) {
    ctx[ctxsz++] = val
}

function pop() {
    if (ctxsz < 1)
        die("stack underflow")
    return ctx[--ctxsz]
}

function eval(str,    tok) {
    split(str, chrs, "")

    for (i in chrs) {
        chr = chrs[i]
        if (chr == "[") {
            if (tok != "") {
                add_or_call(tok)
                tok = ""
            }
            depth++
        } else if (chr == "]") {
            if (tok != "") {
                add_or_call(tok)
                tok = ""
            }
            depth--
            if (depth < 0)
                die("stack underflow")
        } else if (chr == "\"") {
            if (in_quote) {
                push(tok)
                in_quote = 0
            } else {
                if (tok != "") {
                    add_or_call(tok)
                    tok = ""
                }
                in_quote = 1
            }
        } else if (chr == " " && !in_quote) {
            if (tok != "") {
                add_or_call(tok)
                tok = ""
            }
        } else {
            tok = tok chr
        }
    }

    if (tok != "")
        add_or_call(tok)
}

function add_or_call(tok) {
    if (match(tok, "^[0-9]+\\.[0-9]+$"))
        push(tok)
    else if (match(tok, "^[0-9]+$"))
        push(tok)
    else
        call(tok)
}

function call(name) {
    if (name == "true") {
        push(1)
    } else if (name == "false") {
        push(0)
    } else if (name == "+") {
        push(add(pop(), pop()))
    } else if (name == "-") {
        push(subtract(pop(), pop()))
    } else if (name == "*") {
        push(multiply(pop(), pop()))
    } else if (name == "/") {
        push(divide(pop(), pop()))
    } else if (name == "upcase") {
        push(upcase(pop()))
    } else if (name == "downcase") {
        push(downcase(pop()))
    } else {
        die("unknown function: " name)
    }
}

function add(x, y) {
    return x + y
}

function subtract(x, y) {
    return x - y
}

function multiply(x, y) {
    return x * y
}

function divide(x, y) {
    return x / y
}

function upcase(x) {
    return toupper(x)
}

function downcase(x) {
    return tolower(x)
}
