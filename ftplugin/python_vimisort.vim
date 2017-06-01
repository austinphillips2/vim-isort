if exists('g:vim_isort_python_version')
    if g:vim_isort_python_version ==? 'python2'
        command! -nargs=1 AvailablePython python <args>
        let s:available_short_python = ':py'
    elseif g:vim_isort_python_version ==? 'python3'
        command! -nargs=1 AvailablePython python3 <args>
        let s:available_short_python = ':py3'
    endif
else
    if has('python')
        command! -nargs=1 AvailablePython python <args>
        let s:available_short_python = ':py'
    elseif has('python3')
        command! -nargs=1 AvailablePython python3 <args>
        let s:available_short_python = ':py3'
    else
        throw 'No python support present, vim-isort will be disabled'
    endif
endif

command! Isort exec("AvailablePython isort_file()")

if !exists('g:vim_isort_map')
    let g:vim_isort_map = '<C-i>'
endif

if g:vim_isort_map != ''
    execute "vnoremap <buffer>" g:vim_isort_map s:available_short_python "isort_visual()<CR>"
endif

AvailablePython <<EOF
from __future__ import print_function
import vim
from sys import version_info
import os
from tempfile import NamedTemporaryFile
import subprocess as sp
import shlex


# in python2, the vim module uses utf-8 encoded strings
# in python3, it uses unicodes
# so we have to do different things in each case
using_bytes = version_info[0] == 2


def isort_file():
    isort(vim.current.buffer)


def isort_visual():
    isort(vim.current.range)


def isort_installed():
    return run_cmd("isort --version") == 0


def run_cmd(cmd):
    return sp.call(shlex.split(cmd))


def count_blank_lines_at_end(lines):
    blank_lines = 0
    for line in reversed(lines):
        if line.strip():
            break
        else:
            blank_lines += 1
    return blank_lines


def isort(text_range):
    if not isort_installed():
        print("No isort python module detected, you should install it. More info at https://github.com/fisadev/vim-isort")
        return

    blank_lines_at_end = count_blank_lines_at_end(text_range)

    old_text = '\n'.join(text_range)
    if using_bytes:
        old_text = old_text.decode('utf-8')

    with NamedTemporaryFile(suffix='isort_vim', delete=False) as code_file:
        code_file.write(old_text)
        tmp_filename = code_file.name

    new_text = old_text
    return_value = run_cmd('isort {}'.format(tmp_filename))
    if return_value == 0:
        with open(tmp_filename) as code_file:
            new_text = code_file.read()

    os.unlink(tmp_filename)

    if using_bytes:
        new_text = new_text.encode('utf-8')

    new_lines = new_text.split('\n')

    # remove empty lines wrongfully added
    while new_lines and not new_lines[-1].strip() and blank_lines_at_end < count_blank_lines_at_end(new_lines):
        del new_lines[-1]

    text_range[:] = new_lines

EOF
