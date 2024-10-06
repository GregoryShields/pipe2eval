" This script is actually really simple.

" See NOTE 1
com! -nargs=+ Pipe2 call Pipe2eval(<f-args>)

" See NOTE 2
function! Get_path_to_script_file()
	let s:ss = &shellslash
	let &shellslash = 1

	try
		" The important bit...
		return expand('<sfile>:p:h') . '/pipe2eval.sh'
	finally
		let &shellslash = s:ss
	endtry
endfunction

let s:map_key_default = '<Space>'

" This variable doesn't really need to be global, but it's convenient to make it
" global for debugging purposes.
let g:pipe2eval_script = Get_path_to_script_file()

function! Pipe2eval(lang)
	" See NOTE 3
	let l:map_key = exists('g:pipe2eval_map_key') ? g:pipe2eval_map_key : s:map_key_default

	" See NOTE 4
	execute "vmap <buffer> " . l:map_key . " :!" . g:pipe2eval_script . " " . a:lang . " " . expand('%:p') . "<CR><CR>gv<Esc>"
endfunction

" See NOTE 5
au FileType * call Pipe2eval(&filetype)

" SUMMARY:
" There are two ways for the plugin to be set up for a particular buffer:
" 1. Simply open any file. Pipe2eval(&filetype) will always run, passing in
"    the type of file it is and mapping <Space> in Visual Mode.
" 2. Run the Pipe2 command.
"
" Note that there is only one way for the user to invoke the plugin:
" Go into Visual Mode, select lines of code, and press <Space>.
"
" NOTE 1:
" Define a command named Pipe2 which calls our Pipe2eval() function.
"
" NOTE 2: Get_path_to_script_file()
" Added this function to preserve current value of &shellslash,
" but to make sure it's set while setting g:pipe2eval_script variable.
"
" NOTE 3: l:map_key
" If the user set g:pipe2eval_map_key in vimrc, then use that as our map key.
" Otherwise, set our map key to the default, which we defined above this
" function as "<Space>".
" Since I haven't set g:pipe2eval_map_key, then we can assume here that...
" l:map_key = "<Space>"
"
" NOTE 4:
" For Visual Mode and Select Mode in the current buffer only, map <Space>
" to do two things:
" 1. Run this plugin's pipe2eval.sh script, passing it the value of
" a:lang ("bash") as the first argument and the full path to the current
" buffer's underlying file as the second argument.
" In the script the two arguments become the values of two variables,
" namely INPUT_LANG and INPUT_FILE respectively.
" 2. Press gv to reselect the previously selected text and then press <Esc>
" to go back to Normal Mode.
"
" Running the script presumably causes the Visual Mode selection to be lost,
" perhaps by actually writing the result of running the selected code into
" the buffer?
" Therefore, the Vim gv command is run to start Visual Mode again, re-selecting
" the previously selected lines, and afterwards <Esc> is pressed to return to
" Normal Mode.
" See the answer here...
" https://vi.stackexchange.com/questions/9054/using-visual-mode-without-changing-gv
" ...for how to save and restore the marks that the gv command relies upon.
" 


" The repo README says...
" By default, pipe2eval maps <Space> in Visual mode with:
" "   vmap <buffer> <Space> ':![pipe2eval dir]/plugin/pipe2eval.sh text<CR><CR>'   "
" This mapping can be customized by setting g:pipe2eval_map_key. For example:
" "   let g:pipe2eval_map_key = '<Leader>p2e'   "
"
" Note that this pipe2eval.vim file is the only Vim script file for the plugin.
" So we can see that they've changed the above-mentioned vmap mapping, which calls
" the Bash script file directly as an external command, to an :execute statement
" which calls the same Bash script in a different (better?) way.
"
" You can get a good idea of what it's doing by running this...
" echo "vmap <buffer> ". "<Space>" ." :!". g:pipe2eval_script ." ". &filetype . " " . expand('%:p') . "<CR><CR>gv<Esc>"
" ...which outputs this...
" vmap <buffer> <Space> :!C:/gVim/Hm/vimfiles/pack/zweifisch/start/pipe2eval/plugin/pipe2eval.sh bash C:/gVim/Hm/vimfiles/pack/zweifisch/start/pipe2eval/plugin/pipe2eval.vim<CR><CR>gv<esc>
" Or run it like...
" :!C:/gVim/Hm/vimfiles/pack/zweifisch/start/pipe2eval/plugin/pipe2eval.sh &filetype expand('%:p')
" 
"
" NOTE 5: FileType
" When a file is opened for editing, Vim will try to recognize its type and
" then set its 'filetype' option, which in turn will trigger its FileType
" autocommand event. This event is typically used to set syntax highlighting
" and options for this type of file.
"
" All autocommands defined 
"
" File types will be detected if the command...
" :filetype on
" ...has been run. We can see if that's the case by running...
" :verbose filetype
" You also want to make sure 'compatible' is turned off...
" :set nocompatible
" I have these set in...
" $VF/gVim/vimxx/defaults.vim
" ...like...
" if &compatible
"   set nocompatible
" endif
" ...and...
" filetype plugin indent on
"



