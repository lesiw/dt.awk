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
    ctx[ctxsz++] = quote(val, depth)
}

function pop() {
    if (ctxsz < 1)
        die("stack underflow")
    return ctx[--ctxsz]
}

function quote(val, depth,    i, n, chr, chrs, ret) {
    if (!depth)
        return val

    n = split(val, chrs, "")
    for (i = 1; i <= n; i++) {
        chr = chrs[i]
        if (chr == "\"")
            ret = ret "\\"
        else if (chr == "\\")
            ret = ret "\\"
        ret = ret chr
    }

    return quote(ret, depth-1)
}

function unquote(val,    i, n, chr, chrs, ret) {
    n = split(val, chrs, "")
    for (i = 1; i <= n; i++) {
        chr = chrs[i]
        if (chr != "\\") {
            ret = ret chr
        }
    }

    return ret
}

function eval(str,    i, n, chr, chrs, tok) {
    n = split(str, chrs, "")

    for (i = 1; i <= n; i++) {
        chr = chrs[i]
        if (chr == "[") {
            if (tok != "") {
                add_or_call(tok)
                tok = ""
            }
            depth++
        } else if (chr == "]") {
            if (tok != "") {
                push(tok)
                tok = ""
            }
            depth--
            if (depth < 0)
                die("stack underflow")
        } else if (chr == "\"" && !depth) {
            if (in_str) {
                push(tok)
                tok = ""
                in_str = 0
            } else {
                if (tok != "") {
                    add_or_call(tok)
                    tok = ""
                }
                in_str = 1
            }
        } else if (chr == " " && !in_str && !depth) {
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
    if (depth)
        push(tok)
    else if (match(tok, "^[0-9]+\\.[0-9]+$"))
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
    } else if (name == "do") {
        exec(pop())
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

function exec(x) {
    return eval(unquote(x))
}
