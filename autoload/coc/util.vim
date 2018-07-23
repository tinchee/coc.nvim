let s:is_win = has("win32") || has('win64')

function! coc#util#echo_messages(hl, msgs)
  if empty(a:msgs) | return | endif
  execute 'echohl '.a:hl
  for msg in a:msgs
    echom msg
  endfor
  echohl None
endfunction

function! coc#util#get_fullpath(bufnr) abort
  let fname = bufname(a:bufnr)
  if empty(fname) | return '' | endif
  return resolve(fnamemodify(fname, ':p'))
endfunction

function! coc#util#get_bufinfo(bufnr) abort
  return {
        \ 'bufnr': a:bufnr,
        \ 'fullpath': coc#util#get_fullpath(a:bufnr),
        \ 'languageId': getbufvar(a:bufnr, '&filetype'),
        \ 'iskeyword': getbufvar(a:bufnr, '&iskeyword'),
        \ 'expandtab': getbufvar(a:bufnr, '&expandtab') == 1 ? v:true : v:false,
        \ 'tabstop': getbufvar(a:bufnr, '&tabstop'),
        \}
endfunction

function! coc#util#get_bufoptions(bufnr) abort
  return {
        \ 'fullpath': coc#util#get_fullpath(a:bufnr),
        \ 'buftype': getbufvar(a:bufnr, '&buftype'),
        \ 'filetype': getbufvar(a:bufnr, '&filetype'),
        \ 'iskeyword': getbufvar(a:bufnr, '&iskeyword'),
        \ 'changedtick': getbufvar(a:bufnr, 'changedtick'),
        \}
endfunction

function! coc#util#on_error(msg) abort
  echohl Error | echom '[coc.nvim] '.a:msg | echohl None
endfunction

" make function that only trigger once
function! coc#util#once(callback) abort
  function! Cb(...) dict
    if self.called == 1 | return | endif
    let self.called = 1
    call call(self.fn, a:000)
  endfunction

  let obj = {
        \'called': 0,
        \'fn': a:callback,
        \'callback': funcref('Cb'),
        \}
  return obj['callback']
endfunction

function! coc#util#get_listfile_command() abort
  if executable('rg')
    return 'rg --color never --files'
  endif
  if executable('ag')
    return 'ag --follow --nogroup --nocolor -g .'
  endif
  return ''
endfunction

function! coc#util#preview_info(info, ...) abort
  pclose
  keepalt new +setlocal\ previewwindow|setlocal\ buftype=nofile|setlocal\ noswapfile|setlocal\ wrap [Document]
  setl bufhidden=wipe
  setl nobuflisted
  setl nospell
  setl filetype=markdown
  let lines = split(a:info, "\n")
  call append(0, lines)
  exe "normal z" . len(lines) . "\<cr>"
  exe "normal gg"
  wincmd p
endfunction

function! coc#util#get_config_home()
  if exists('$VIMCONFIG')
    return resolve($VIMCONFIG)
  endif
  if has('nvim')
    if exists('$XDG_CONFIG_HOME')
      return resolve($XDG_CONFIG_HOME."/nvim")
    endif
    return resolve($HOME.'/.config/nvim')
  else
    if s:is_win
      return $VIM."/vimfiles"
    endif
    return $HOME.'/.vim'
  endif
endfunction

function! coc#util#get_input()
  let pos = getcurpos()
  let line = getline('.')
  let l:start = pos[2] - 1
  while l:start > 0 && line[l:start - 1] =~# '\k'
    let l:start -= 1
  endwhile
  return pos[2] == 1 ? '' : line[l:start : pos[2] - 2]
endfunction

function! coc#util#get_complete_option(...)
  let opt = get(a:, 1, {})
  let pos = getcurpos()
  let line = getline('.')
  let l:start = pos[2] - 1
  while l:start > 0 && line[l:start - 1] =~# '\k'
    let l:start -= 1
  endwhile
  let input = pos[2] == 1 ? '' : line[l:start : pos[2] - 2]
  return extend({
        \ 'id': localtime(),
        \ 'changedtick': b:changedtick,
        \ 'word': matchstr(line[l:start : ], '^\k\+'),
        \ 'input': input,
        \ 'line': line,
        \ 'buftype': &buftype,
        \ 'filetype': &filetype,
        \ 'filepath': expand('%:p'),
        \ 'bufnr': bufnr('%'),
        \ 'linenr': pos[1],
        \ 'colnr' : pos[2],
        \ 'col': l:start,
        \ 'iskeyword': &iskeyword,
        \}, opt)
endfunction

function! coc#util#prompt_change(count)
  echohl MoreMsg
  echom a:count.' files will be changed. Confirm? (y/n)'
  echohl None
  let confirm = nr2char(getchar()) | redraw!
  if !(confirm ==? "y" || confirm ==? "\r")
    echohl Moremsg | echo 'Cancelled.' | echohl None
    return 0
  end
  return 1
endfunction

function! coc#util#prompt_confirm(title)
  echohl MoreMsg
  echom a:title.' Confirm? (y/n)'
  echohl None
  let confirm = nr2char(getchar()) | redraw!
  if !(confirm ==? "y" || confirm ==? "\r")
    echohl Moremsg | echo 'Cancelled.' | echohl None
    return 0
  end
  return 1
endfunction

function! coc#util#get_syntax_name(lnum, col)
  return synIDattr(synIDtrans(synID(a:lnum,a:col,1)),"name")
endfunction

function! coc#util#get_search(col) abort
  let line = getline('.')
  let colnr = mode() ==# 'n' ? col('.') + 1 : col('.')
  if colnr <= a:col + 1 | return '' | endif
  return line[a:col : colnr - 2]
endfunction

function! coc#util#echo_signature(activeParameter, activeSignature, signatures) abort
  let arr = []
  let signatures = a:signatures[0: &cmdheight - 1]
  let i = 0
  let activeParameter = get(a:, 'activeParameter', 0)
  for item in a:signatures
    let texts = []
    if type(a:activeSignature) == 0 && a:activeSignature == i
      call add(texts, {'text': item['label'], 'hl': 'Label'})
      call add(texts, {'text': '('})
      let params = get(item, 'parameters', [])
      let j = 0
      for param in params
        call add(texts, {
              \'text': param['label'],
              \'hl': j == activeParameter ? 'MoreMsg' : ''
              \})
        if j != len(params) - 1
          call add(texts, {'text': ', '})
        endif
        let j = j + 1
      endfor
      call add(texts, {'text': ')'})
    else
      call add(texts, {'text': item['label'], 'hl': 'Label'})
      call add(texts, {'text': '('})
      let params = get(item, 'parameters', [])
      let text = join(map(params, 'v:val["label"]'), ',')
      call add(texts, {'text': text})
      call add(texts, {'text': ')'})
    endif
    call add(arr, texts)
    let i = i + 1
  endfor
  let g:a = arr
  for idx in range(len(arr))
    call s:echo_signatureItem(arr[idx])
    if idx != len(arr) - 1
      echon "\n"
    endif
  endfor
endfunction

function! s:echo_signatureItem(list)
  for item in a:list
    let text = substitute(get(item, 'text', ''), "'", "''", 'g')
    let hl = get(item, 'hl', '')
    if empty(hl)
      execute "echon '".text."'"
    else
      execute 'echohl '.hl
      execute "echon '".text."'"
      echohl None
    endif
  endfor
endfunction

function! coc#util#unplace_signs(bufnr, sign_ids)
  for id in a:sign_ids
    execute 'sign unplace '.id.' buffer='.a:bufnr
  endfor
endfunction

function! s:codelens_jump() abort
  let lnum = matchstr(getline('.'), '^\d\+')
  if !empty(lnum)
    let wnr = bufwinnr(get(b:, 'bufnr', 0))
    if wnr != -1
      execute wnr.'wincmd w'
      execute 'normal! '.lnum.'G'
    endif
  endif
endfunction

function! coc#util#open_codelens()
  pclose
  execute &previewheight.'new +setlocal\ buftype=nofile [CodeLens]'
  setl noswapfile
  setl nowrap
  setl nonumber
  setl norelativenumber
  setl cursorline
  setl bufhidden=wipe
  setl nobuflisted
  setl nospell
  execute 'nnoremap <silent> <buffer> '.get(g:, 'coc_codelen_jump_key', '<CR>').' :call <SID>codelens_jump()<CR>'
  execute 'nnoremap <silent> <buffer> '.get(g:, 'coc_codelen_action_key', 'd').' :call CocAction("codeLensAction")<CR>'
  syntax clear
  syntax case match
  syntax match codelinesLine        /^.*$/
  syntax match codelinesLineNumbder /^\d\+/       contained nextgroup=codelinesAction containedin=codelinesLine
  syntax match codelinesAction      /\%x0c.*\%x0c/ contained containedin=codelinesLine contains=codelinesSepChar
  syntax match codelinesSepChar     /\%x0c/        conceal cchar=:
  hi def link codelinesLineNumbder Comment
  hi def link codelinesAction      MoreMsg
endfunction

" change content of current buffer
function! coc#util#buf_setlines(lines)
  let l:winview = winsaveview()
  let count = line('$')
  keepjumps call setline(1, a:lines)
  if count > len(a:lines)
    let lnum = len(a:lines) + 1
    execute 'keepjumps normal '.lnum.'G'
    keepjumps normal! dG
  endif
  call winrestview(l:winview)
endfunction

function! coc#util#setline(lnum, line)
  keepjumps call setline(a:lnum, a:line)
endfunction

function! coc#util#open_terminal(cmd, cwd)
  execute 'belowright 5new'
  setl winfixheight
  setl norelativenumber
  if has('nvim')
    call termopen(a:cmd, {
          \ 'cwd': a:cwd,
          \ 'on_exit': function('s:OnExit'),
          \ 'buffer_nr': bufnr('%'),
          \})
    startinsert
  else
    execute 'lcd '.a:cwd
    call term_start(a:cmd, {
          \ 'term_finish': 'close',
          \ 'curwin': 1,
          \})
  endif
endfunction

function! s:OnExit(job_id, status, event) dict
  if a:status == 0
    execute 'silent! bd! '.self.buffer_nr
  endif
endfunction

function! coc#util#vim_info()
  return {
        \ 'completeOpt': &completeopt,
        \ 'isVim': has('nvim') ? v:false : v:true,
        \}
endfunction

function! coc#util#get_content(bufnr)
  if !bufexists(a:bufnr) | return '' | endif
  return {
        \ 'content': join(getbufline(a:bufnr, 1, '$'), "\n"),
        \ 'changedtick': getbufvar(a:bufnr, 'changedtick')
        \ }
endfunction

" used for TextChangedI with InsertCharPre
function! coc#util#get_changeinfo()
  return {
        \ 'lnum': line('.'),
        \ 'line': getline('.'),
        \ 'changedtick': b:changedtick,
        \}
endfunction

" show diff of current buffer
function! coc#util#diff_content(lines) abort
  let tmpfile = tempname()
  setl foldenable
  call writefile(a:lines, tmpfile)
  let ft = &filetype
  diffthis
  execute 'vs '.tmpfile
  execute 'setf ' . ft
  diffthis
  setl foldenable
endfunction
