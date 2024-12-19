#!/usr/bin/env python
#
# Copyright (c) 2024 Dmitry Arkhipov (grisumbras@yandex.ru)
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
# Official repository: https://github.com/cppalliance/debugger_utils
#


import argparse
import re
import sys


_top = '''\
import gdb
import re
import sys
import traceback

class Test:
    def __init__(self, bp, func):
        self.breakpoint = bp
        self.func = func
        self.occured = False

    def __call__(self):
        self.occured = True
        return self.func(self.breakpoint)

def gdb_print(expr):
    output = gdb.execute('print %s' % expr, to_string=True)
    parts = output[:-1].split(' = ', 1)
    if len(parts) > 1:
        output = parts[1]
    else:
        output = parts[0]
    return output

def TEST_EXPR(expr, pattern, *args, **kwargs):
    def test(bp):
        if args or kwargs:
            actual_args = [gdb_print(arg) for arg in args]
            actual_kwargs = dict([
                (k, gdb_print(v)) for (k,v) in kwargs.items() ])
            actual_pattern = pattern.format(*actual_args, **actual_kwargs)
        else:
            actual_pattern = pattern
        output = gdb_print(expr)
        try:
            if actual_pattern != output:
                print((
                    '{0}: error: expression "{1}" evaluates to\\n'
                    '{2}\\n'
                    'expected\\n'
                    '{3}\\n').format(
                        bp.location, expr, output, actual_pattern),
                    file=sys.stderr)
                gdb.execute('quit 1')
        except:
            raise
    return test

_return_code = 0
_tests = dict()
_done = False
try:
    assert gdb.objfiles()

'''

_breakpoint = '''\
    bp = gdb.Breakpoint('{input}:{line}', internal=True)
    _tests[bp] = Test(bp, {text})
'''

_bottom = '''\
    if not _tests:
        print('error: nothing to test', file=sys.stderr)
        gdb.execute('quit 1')

    gdb.execute('start', to_string=True)
    program = gdb.selected_inferior()

    def on_exit(ev):
        if not ev.inferior == program:
            return
        if hasattr(ev, 'exit_code'):
            _return_code = ev.exit_code

        global _done
        _done = True
    gdb.events.exited.connect(on_exit)

    def on_stop(ev):
        if not isinstance(ev, gdb.BreakpointEvent):
            return
        _tests.get(ev.breakpoint)()
    gdb.events.stop.connect(on_stop)

    while True:
        gdb.execute('continue')
        if _done:
            break

except BaseException:
    traceback.print_exc()
    gdb.execute('disable breakpoints')
    try:
        gdb.execute('continue')
    except:
        pass
    _return_code = 1

for test in _tests.values():
    if not test.occured:
        print(
            '{0}: error: condition was never tested'.format(
                test.breakpoint.location),
            file=sys.stderr)
        _return_code = 1

gdb.execute('quit %s' % _return_code)
'''


class Nullcontext():
    def __init__(self):
        pass

    def __enter__(self):
        pass

    def __exit__(self, exc_type, exc_value, traceback):
        pass


def parse_args(args):
    parser = argparse.ArgumentParser(
        prog=args[0],
        description=(
            'Creates a Python script from C++ source files to control a GDB '
            'test of those source files.'))
    parser.add_argument(
        'input',
        nargs='+',
        help='Input files')
    parser.add_argument(
        '-o',
        '--output',
        help='Output file; STDOUT by default')
    return parser.parse_args(args[1:])

def main(args, stdin, stdout):
    args = parse_args(args)

    if args.output:
        output = open(args.output, 'w', encoding='utf-8')
        output_ctx = output
    else:
        output = stdout
        output_ctx = Nullcontext()

    test_line = re.compile(r'^\s*//\s*TEST_', re.U)

    with output_ctx:
        output.write(_top)
        for src in args.input:
            with open(src, 'r', encoding='utf-8') as input:
                for n, line in enumerate(input, start=1):
                    match = test_line.search(line)
                    if not match:
                        continue
                    line = line.strip()[2:].lstrip()
                    output.write(
                        _breakpoint.format(input=src, line=n, text=line))
        output.write(_bottom)


if __name__ == '__main__':
    main(sys.argv, sys.stdin, sys.stdout)
