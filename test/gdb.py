#
# Copyright (c) 2024 Dmitry Arkhipov (grisumbras@yandex.ru)
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#

import gdb
import gdb.printing


collection = gdb.printing.RegexpCollectionPrettyPrinter(
    'BoostDebuggerUtilsTest')
def register(printer, ns=None, template=False):
    typename = getattr(printer, '__name__')
    ns = ns or 'testlib'
    collection.add_printer(
        typename,
        '^{ns}::{typename}{marker}'.format(
            ns=ns,
            typename=typename,
            marker='<'if template else '$'),
        printer)


class key_value_pair:
    def __init__(self, val):
        self.val = val

    def to_string(self):
        return 'key_value_pair[%s = %s]' % (
            self.val['key'], self.val['value'])
register(key_value_pair)


class memory_resource:
    def __init__(self, val):
        self.val = val

    def to_string(self):
        void_star = gdb.lookup_type('void').pointer()
        return 'memory_resource[buffer=%s, size=%s]' % (
            self.val['buffer'].cast(void_star), self.val['size'])
register(memory_resource)


obj_file = gdb.current_objfile()
mod = obj_file or gdb
should_run = True
for printer in getattr(mod, 'pretty_printers', []):
    if getattr(printer, 'name') == collection.name:
        should_run = False
if should_run:
    gdb.printing.register_pretty_printer(obj_file, collection)
