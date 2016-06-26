" Name:      prtdialog.vim - simplifies printing of text
" Type:      global vim plugin
" Credits:   original author: Christian Habermann
"                             <christian (at) habermann-net (point) de>
"            forker by:       David Nebauer
"                             <david (at) nebauer (point) org>
" Copyright: (c) 2016 by David Nebauer
" License:   GNU General Public License 2 (GPL 2) or later
" Purpose:   Provide a dialog to configure printer settings printing.
"            To invoke this dialog, press <Leader>pd.
"            For futher informations do |:help prtdialog|

" CONTROL BUFFER LOADING:                                              {{{1
if exists('g:loaded_prtdialog')
    finish
endif

let g:loaded_prtdialog = 1


" CONFIGURATION:                                                       {{{1

" mappings                                                             {{{2
if !hasmapto('<Plug>PRD_PrinterDialogVisual')
    vmap <silent> <unique> <Leader>pd <Plug>PRD_PrinterDialogVisual
endif
if !hasmapto('<Plug>PRD_PrinterDialogNormal')
    nmap <silent> <unique> <Leader>pd <Plug>PRD_PrinterDialogNormal
endif
vmap <silent> <unique> <script> <Plug>PRD_PrinterDialogVisual <ESC>:call <SID>PRD_StartPrinterDialog(0)<CR>
nmap <silent> <unique> <script> <Plug>PRD_PrinterDialogNormal      :call <SID>PRD_StartPrinterDialog(1)<CR>

" default properties                                                   {{{2

" - devices [default: standard]                                        {{{3
if !exists('g:prd_printDevices')
    let g:prd_printDevices   = ['standard']
endif
if !exists('g:prd_printDeviceIdx')
    let g:prd_printDeviceIdx = 0
endif

" - fonts [default: courier 8]                                         {{{3
if !exists('g:prd_fonts')
    let g:prd_fonts   = ['courier:h6',  'courier:h8', 'courier:h10',
                \        'courier:h12', 'courier:h14']
endif
if !exists('g:prd_fontIdx')
    let g:prd_fontIdx = 1
endif

" - paper size [default: A4]                                           {{{3
if !exists('g:prd_paperSizes')
    let g:prd_paperSizes   = ['A3', 'A4',    'A5',     'B4',
                \             'B5', 'legal', 'letter']
endif
if !exists('g:prd_paperSizeIdx')
    let g:prd_paperSizeIdx = 1
endif

" - orientation [default: portrait]                                    {{{3
if !exists('g:prd_portrait')
    let g:prd_portrait    = ['yes', 'no']
endif
if !exists('g:prd_portraitIdx')
    let g:prd_portraitIdx = 0
endif

" - header size [default: 2 lines]                                     {{{3
if !exists('g:prd_headerSizes')
    let g:prd_headerSizes   = [0, 1, 2, 3, 4, 5, 6]
endif
if !exists('g:prd_headerSizeIdx')
    let g:prd_headerSizeIdx = 2
endif

" - number lines [default: yes]                                        {{{3
if !exists('g:prd_numberLines')
    let g:prd_numberLines    = ['yes', 'no']
endif
if !exists('g:prd_numberLinesIdx')
    let g:prd_numberLinesIdx = 0
endif

" - syntax highlighting and colour scheme [default: vim default]       {{{3
if !exists('g:prd_syntaxSchemes')
    let g:prd_syntaxSchemes   = ['no', 'current', 'default']
    for l:scheme in ['print_bw', 'zellner', 'solarized']
        let l:path = 'colors/' . l:scheme . '.vim'
        if globpath(&runtimepath, l:path, 1, 1)
            call add(g:prd_syntaxSchemes, l:scheme)
        endif
    endfor
endif
if !exists('g:prd_syntaxSchemeIdx')
    let g:prd_syntaxSchemeIdx = 2
endif

" - wrap or truncate long lines [default: wrap]                        {{{3
if !exists('g:prd_wrapLines')
    let g:prd_wrapLines   = ['yes', 'no']
endif
if !exists('g:prd_wrapLineIdx')
    let g:prd_wrapLineIdx = 0
endif

" - duplex [default: on, bind on long edge]                            {{{3
if !exists('g:prd_duplex')
    let g:prd_duplex    = ['off', 'long', 'short']
endif
if !exists('g:prd_duplexIdx')
    let g:prd_duplexIdx = 1
endif

" - collate [default: yes]                                             {{{3
if !exists('g:prd_collate')
    let g:prd_collate    = ['yes', 'no']
endif
if !exists('g:prd_collateIdx')
    let g:prd_collateIdx = 0
endif

" - split copies into separate print jobs [default: no]                {{{3
if !exists('g:prd_splitPrintJob')
    let g:prd_splitPrintJob    = ['yes', 'no']
endif
if !exists('g:prd_splitPrintJobIdx')
    let g:prd_splitPrintJobIdx = 1
endif

" - left margin [default: 15mm]                                        {{{3
if !exists('g:prd_leftMargin')
    let g:prd_leftMargin    = ['5mm', '10mm', '15mm', '20mm', '25mm']
endif
if !exists('g:prd_leftMarginIdx')
    let g:prd_leftMarginIdx = 2
endif

" - right margin [default: 15mm]                                       {{{3
if !exists('g:prd_rightMargin')
    let g:prd_rightMargin    = ['5mm', '10mm', '15mm', '20mm', '25mm']
endif
if !exists('g:prd_rightMarginIdx')
    let g:prd_rightMarginIdx = 2
endif

" - top margin [default: 10mm]                                         {{{3
if !exists('g:prd_topMargin')
    let g:prd_topMargin    = ['5mm', '10mm', '15mm', '20mm', '25mm']
endif
if !exists('g:prd_topMarginIdx')
    let g:prd_topMarginIdx = 1
endif

" - bottom margin [default: 10mm]                                      {{{3
if !exists('g:prd_bottomMargin')
    let g:prd_bottomMargin    = ['5mm', '10mm', '15mm', '20mm', '25mm']
endif
if !exists('g:prd_bottomMarginIdx')
    let g:prd_bottomMarginIdx = 1
endif

" - show Windows print dialog before printing [default: no]            {{{3
if !exists('g:prd_osPrintDialog')
    let g:prd_osPrintDialog    = ['yes', 'no']
endif
if !exists('g:prd_osPrintDialogIdx')
    let g:prd_osPrintDialogIdx = 1
endif

" allow user to set a script specific printheader                      {{{2
if !exists('g:prd_printheader')
    let g:prd_printheader = &printheader
endif


" INITIALISATION:                                                      {{{1

" used to print/echo name of script                                    {{{2
let s:scriptName = 'PrtDialog'

" colorscheme loaded for printing?                                     {{{2
let s:flagColorschemeDone = 0

" default 'printexpr' (obtained from |:help pexpr-option|)             {{{2
let s:default_printexpr = "system('lpr' . (&printdevice == '' ? '' "
            \ . ": ' -P' . &printdevice) . ' ' . v:fname_in) . "
            \ . 'delete(v:fname_in) + v:shell_error'

" buffer variable                                                      {{{2
let s:buffer = {}


" INTERFACE FUNCTIONS:                                                 {{{1

" PRD_StartPrinterDialog(whatToPrint)                                  {{{2
"  intent: get range to be printed and buffer, then start user interface
"  params: whatToPrint - 0 is selected range, else whole buffer
"  insert: nil
"  return: n/a
function <SID>PRD_StartPrinterDialog(whatToPrint)
    
    " check that vim is compiled with print option                     {{{3
    if !has('printer')  " is this vim compiled with printing enabled?
        echo s:scriptName 
                    \ . ': this version of VIM does not support printing'
        return
    endif
    let s:whatToPrint = a:whatToPrint

    " get range to be printed                                          {{{3
    if s:whatToPrint == 0
        let s:range = {'start': line("'<"), 'end': line("'>")}
    else
        let s:range = {'start': 1, 'end': line('$')}
    endif
    
    " so far no buffer created for ui; get buffer to be printed        {{{3
    let s:buffer.user = -1
    let s:buffer.src  = winbufnr(0)
    
    " set up user interface                                            {{{3
    if s:OpenNewBuffer()  " buffer for user-interface
        call s:UpdateDialog()         " show the dialog
        call s:SetLocalKeyMappings()  " set keys for user (local to buffer)
    endif                                                            " }}}3

endfunction


" CORE FUNCTIONS:                                                      {{{1

" s:OpenNewBuffer()                                                    {{{2
"  intent: open a new buffer for user interaction
"  params: nil
"  insert: nil
"  return: boolean (success)
function s:OpenNewBuffer()

    " open buffer                                                      {{{3
    " - fails if buffer contains unsaved changes
    try
        update
        execute 'enew'
    catch /^Vim\%((\a\+)\)\=:E32/
        " E32: No file name
        " tried to update buffer that has no file name
        echo "PrtDialog: can't print unnamed buffer - save to file"
        return
    catch /^Vim\%((\a\+)\)\=:E37/
        " E37: No write since last change (add ! to override)
        " tried to create new buffer when current one has unsaved changes
        echo "PrtDialog: can't print while buffer has unsaved changes"
        return
    catch /^Vim\%((\a\+)\)\=:E/
        " all other errors
        echo "PrtDialog: can't print due to unexpected error"
        return
    endtry
    let s:buffer.user = winbufnr(0)
    
    " abort if opened self                                             {{{3
    if s:buffer.user == s:buffer.src
        call <SID>PRD_Exit()
        echo s:scriptName . ': no buffer to be printed'
        return
    endif
    
    " set buffer-specific settings                                     {{{3
    "   - nomodifiable:     don't allow to edit this buffer
    "   - noswapfile:       we don't need a swapfile
    "   - buftype=nowrite:  buffer will not be written
    "   - bufhidden=delete: delete this buffer if it will be hidden
    "   - nowrap:           don't wrap around long lines
    "   - iabclear:         no abbreviations in insert mode
    setlocal nomodifiable
    setlocal noswapfile
    setlocal buftype=nowrite
    setlocal bufhidden=delete
    setlocal nowrap
    iabclear <buffer>
    return 1                                                         " }}}3

endfunction

" s:UpdateDialog()                                                     {{{2
"  intent: redraw print dialog
"  params: nil
"  insert: buffer content
"  return: n/a
function s:UpdateDialog()

    " get name of print dialog buffer                                  {{{3
    let l:filename = bufname(s:buffer.src)
    if l:filename ==# ''
        let l:filename = '[noname]'
    endif
    
    " get range of buffer to be printed                                {{{3
    if  s:whatToPrint == 0
        let l:range = 'lines ' . s:range.start . ' - ' . s:range.end
    else
        let l:range = 'whole file'
    endif
    
    " set up syntax highlighting                                       {{{3
    call s:SetupSyntax()
    setlocal modifiable

    " set column of parameter                                          {{{3
    let s:colPara = 14
    
    " delete existing content                                          {{{3
    %delete
    
    " create buffer content                                            {{{3
    let s:optLine = {}
    let l:c = []
    call add(l:c, '"   PRINTER DIALOG')
    call add(l:c, '"     <p>: start printing      <q>: cancel,')
    call add(l:c, '"   <Tab>: toggle to next  '
                \  . '<S-Tab>: toggle to previous,')
    call add(l:c, '"     <?>: help on option')
    call add(l:c, '"   **** |:help printer-dialog| '
                \      . 'for detailed help ****')
    call add(l:c, '')
    call add(l:c, '>File-Info:')
    call add(l:c, '   Name:      ' . l:filename)
    call add(l:c, '   Range:     ' . l:range)
    call add(l:c, '')
    call add(l:c, '>Printer:    <'
                \ . g:prd_printDevices[g:prd_printDeviceIdx]
                \ . '>')
    let s:optLine.printDevice = len(l:c)
    call add(l:c, '')
    call add(l:c, '>Options:')
    call add(l:c, '   Font:     <'
                \ . g:prd_fonts[g:prd_fontIdx]
                \ . '>')
    let s:optLine.font = len(l:c)
    call add(l:c, '   Paper:    <'
                \ . g:prd_paperSizes[g:prd_paperSizeIdx]
                \ . '>')
    let s:optLine.paper = len(l:c)
    call add(l:c, '   Portrait: <'
                \ . g:prd_portrait[g:prd_portraitIdx]
                \ . '>')
    let s:optLine.portrait = len(l:c)
    call add(l:c, '')
    call add(l:c, '   Header:   <'
                \ . g:prd_headerSizes[g:prd_headerSizeIdx]
                \ . '>')
    let s:optLine.header = len(l:c)
    call add(l:c, '   Line-Nr:  <' 
                \ . g:prd_numberLines[g:prd_numberLinesIdx]
                \ . '>')
    let s:optLine.number = len(l:c)
    call add(l:c, '   Syntax:   <' 
                \ . g:prd_syntaxSchemes[g:prd_syntaxSchemeIdx]
                \ . '>')
    let s:optLine.syntax = len(l:c)
    call add(l:c, '')
    call add(l:c, '   Wrap:     <' 
                \ . g:prd_wrapLines[g:prd_wrapLineIdx]
                \ . '>')
    let s:optLine.wrap = len(l:c)
    call add(l:c, '   Duplex:   <' 
                \ . g:prd_duplex[g:prd_duplexIdx]
                \ . '>')
    let s:optLine.duplex = len(l:c)
    call add(l:c, '   Collate:  <' 
                \ . g:prd_collate[g:prd_collateIdx]
                \ . '>')
    let s:optLine.collate = len(l:c)
    call add(l:c, '   JobSplit: <' 
                \ . g:prd_splitPrintJob[g:prd_splitPrintJobIdx]
                \ . '>')
    let s:optLine.splitJob = len(l:c)
    call add(l:c, '')
    call add(l:c, '   Left:     <' 
                \ . g:prd_leftMargin[g:prd_leftMarginIdx]
                \ . '>')
    let s:optLine.left = len(l:c)
    call add(l:c, '   Right:    <' 
                \ . g:prd_rightMargin[g:prd_rightMarginIdx]
                \ . '>')
    let s:optLine.right = len(l:c)
    call add(l:c, '   Top:      <' 
                \ . g:prd_topMargin[g:prd_topMarginIdx]
                \ . '>')
    let s:optLine.top = len(l:c)
    call add(l:c, '   Bottom:   <' 
                \ . g:prd_bottomMargin[g:prd_bottomMarginIdx]
                \ . '>')
    let s:optLine.bottom = len(l:c)
    call add(l:c, '')
    call add(l:c, '   Dialog:   <' 
                \ . g:prd_osPrintDialog[g:prd_osPrintDialogIdx]
                \ . '>')
    let s:optLine.osPrintDialog = len(l:c)
    
    " write content to buffer                                          {{{3
    let l:txt = join(l:c, "\n")
    put! = l:txt
    setlocal nomodifiable                                            " }}}3

endfunction

" s:SetupSyntax()                                                      {{{2
"  intent: set syntax highlighting for user interface
"  params: nil
"  insert: nil
"  return: n/a
function s:SetupSyntax()

    " only work if vim supports syntax highlighting                    {{{3
    if !has('syntax')
        return
    endif
    
    " set syntax rules                                                 {{{3
    syntax match prdHeadline ">.*:"
    syntax match prdParameter "<.*>"
    syntax match prdComment   "^\".*"
    
    " set highlighting                                                 {{{3
    if !exists('g:prd_syntaxUIinit')
        let g:prd_syntaxUIinit = 0
        hi def link prdParameter Special
        hi def link prdHeadline  String
        hi def link prdComment   Comment
    endif                                                            " }}}3

endfunction

" s:SetLocalKeyMappings()                                              {{{2
"  intent: set local, temporary key-mappings for this buffer only          
"  params: nil
"  insert: nil
"  return: n/a
function s:SetLocalKeyMappings()
    
    nnoremap <buffer> <silent> q       :call <SID>PRD_Exit()<cr>
    nnoremap <buffer> <silent> p       :call <SID>PRD_StartPrinting()<cr>
    nnoremap <buffer> <silent> <Tab>   :call <SID>PRD_ToggleParameter(1)<cr>
    nnoremap <buffer> <silent> <S-Tab> :call <SID>PRD_ToggleParameter(-1)<cr>
    nnoremap <buffer> <silent> ?       :call <SID>PRD_ShowHelpOnParameter()<cr>

endfunction

" s:SetPrintdevice()                                                   {{{2
"  intent: set 'printdevice' according to user selection
"  params: nil
"  insert: nil
"  return: n/a
"  note:   if no user setting, set to 'standard'
function s:SetPrintdevice()

    let l:element = g:prd_printDevices[g:prd_printDeviceIdx]
    if tolower(l:element) ==# 'standard'
        let &printdevice = ''
    else
        let &printdevice = l:element
    endif

endfunction

" s:SetPrintoptions()                                                  {{{2
"  intent: set 'printoptions' according to user selection
"  params: nil
"  insert: nil
"  return: n/a
function s:SetPrintoptions()

    let l:opts = ''

    " margins                                                          {{{3
    let l:opts .= ',left:'   . g:prd_leftMargin[g:prd_leftMarginIdx]
    let l:opts .= ',right:'  . g:prd_rightMargin[g:prd_rightMarginIdx]
    let l:opts .= ',top:'    . g:prd_topMargin[g:prd_topMarginIdx]
    let l:opts .= ',bottom:' . g:prd_bottomMargin[g:prd_bottomMarginIdx]
    
    " header                                                           {{{3
    let l:opts .= ',header:' . g:prd_headerSizes[g:prd_headerSizeIdx]
    
    " duplex                                                           {{{3
    let l:opts .= ',duplex:' . g:prd_duplex[g:prd_duplexIdx]
    
    " paper size                                                       {{{3
    let l:opts .= ',paper:'  . g:prd_paperSizes[g:prd_paperSizeIdx]
    
    " line numbering                                                   {{{3
    let l:opts .= ',number:' . strpart(
                \ g:prd_numberLines[g:prd_numberLinesIdx], 0, 1)
    
    " line wrapping                                                    {{{3
    let l:opts .= ',wrap:'   . strpart(
                \ g:prd_wrapLines[g:prd_wrapLineIdx], 0, 1)
    
    " collate                                                          {{{3
    let l:opts .= ',collate:'  . strpart(
                \ g:prd_collate[g:prd_collateIdx], 0, 1)
    
    " split copies into individual print jobs                          {{{3
    let l:opts .= ',jobSplit:' . strpart(
                \ g:prd_splitPrintJob[g:prd_splitPrintJobIdx], 0, 1)
    
    " orientation                                                      {{{3
    let l:opts .= ',portrait:' . strpart(
                \ g:prd_portrait[g:prd_portraitIdx], 0, 1)
    
    " syntax highlighting                                              {{{3
    if has('syntax')
        if g:prd_syntaxSchemes[g:prd_syntaxSchemeIdx] ==? 'no'
            let l:opts .= ',syntax:n'
        else
            let l:opts .= ',syntax:y'
        endif
    endif
    
    " set &printoptions                                                {{{3
    let l:opts = strpart(l:opts, 1)  " remove leading comma
    let &printoptions = l:opts                                       " }}}3

endfunction

" s:SetPrintfont()                                                     {{{2
"  intent: set 'printfont' from user selection
"  params: nil
"  insert: nil
"  return: n/a
function s:SetPrintfont()

    let &printfont = g:prd_fonts[g:prd_fontIdx]

endfunction

" s:SetPrintheader()                                                   {{{2
"  intent: set 'printheader' from user selection
"  params: nil
"  insert: nil
"  return: n/a
function s:SetPrintheader()

    let &printheader = g:prd_printheader

endfunction

" s:SetColorschemeForPrinting()                                        {{{2
"  intent: set colorscheme from user selection
"  params: nil
"  insert: nil
"  return: n/a
"  note:   user choices can be 'no', 'current' or a colorscheme name:
"          'no'        - do not use syntax highlighting for printing
"          'current'   - use current syntax highlighting for printing
"          colorscheme - use named colorscheme syntax highlighting for
"                        printing
"                      - the actual colorscheme in use for document
"                        does not change
"  TODO:   check whether this logic is properly implemented in function
"          - options 'no' and 'current' do not appear to be implemented
function s:SetColorschemeForPrinting()

    let s:flagColorschemeDone = 0
    if !has('syntax') | return | endif
    let l:element = tolower(g:prd_syntaxSchemes[g:prd_syntaxSchemeIdx]) 
    if l:element !~# '^no$\|^current$'
        let s:flagColorschemeDone = 1
        execute 'colorscheme' l:element 
    endif

endfunction

" s:BackupSettings()                                                   {{{2
"  intent: backup printer and colorscheme settings
"  params: nil
"  insert: nil
"  return: n/a
function s:BackupSettings()

    let s:backup = {}
    let s:backup.printdevice  = &printdevice
    let s:backup.printoptions = &printoptions
    let s:backup.printfont    = &printfont
    let s:backup.printheader  = &printheader
    if has('syntax')
        if exists('g:colors_name')
            let s:backup.colorscheme = g:colors_name
        else
            let s:backup.colorscheme = 'default'
        endif
    endif

endfunction

" s:RestoreSettings()                                                  {{{2
"  intent: restore printer and colorscheme settings
"  params: nil
"  insert: nil
"  return: n/a
function s:RestoreSettings()

    let &printdevice  = s:backup.printdevice
    let &printoptions = s:backup.printoptions
    let &printfont    = s:backup.printfont
    let &printheader  = s:backup.printheader
    if has('syntax') && s:flagColorschemeDone == 1
        execute 'colorscheme' s:backup.colorscheme
    endif

endfunction

" <SID>PRD_Exit()                                                      {{{2
"  intent: exit script and close user interface buffer if present
"  params: nil
"  insert: nil
"  return: n/a
function <SID>PRD_Exit()

    execute 'buffer' s:buffer.src

endfunction

" <SID>PRD_ToggleParameter(step)                                       {{{2
"  intent: toggle parameter under cursor to next or previous value
"  params: step - direction to increment (1=next, -1=previous)
"  insert: new option value
"  return: n/a
function <SID>PRD_ToggleParameter(step)

    let l:lineNr  = line('.')
    let l:element = ''

    " adjust index of appropriate option, handling wrap around
    " then extract new option value:
    " - print device                                                   {{{3
    if     l:lineNr == s:optLine.printDevice
        let g:prd_printDeviceIdx = g:prd_printDeviceIdx + a:step 
        if g:prd_printDeviceIdx == len(g:prd_printDevices)
            let g:prd_printDeviceIdx = 0
        elseif g:prd_printDeviceIdx < 0
            let g:prd_printDeviceIdx = len(g:prd_printDevices) - 1
        endif
        let l:element = g:prd_printDevices[g:prd_printDeviceIdx]

    " - font                                                           {{{3
    elseif l:lineNr == s:optLine.font
        let g:prd_fontIdx = g:prd_fontIdx + a:step 
        if g:prd_fontIdx == len(g:prd_fonts)
            let g:prd_fontIdx = 0
        elseif g:prd_fontIdx < 0
            let g:prd_fontIdx = len(g:prd_fonts) - 1
        endif
        let l:element = g:prd_fonts[g:prd_fontIdx]

    " - paper size                                                     {{{3
    elseif l:lineNr == s:optLine.paper
        let g:prd_paperSizeIdx = g:prd_paperSizeIdx + a:step 
        if g:prd_paperSizeIdx == len(g:prd_paperSizes)
            let g:prd_paperSizeIdx = 0
        elseif g:prd_paperSizeIdx < 0
            let g:prd_paperSizeIdx = len(g:prd_paperSizes) - 1
        endif
        let l:element = g:prd_paperSizes[g:prd_paperSizeIdx]
    
    " - orientation                                                    {{{3
    elseif l:lineNr == s:optLine.portrait
        let g:prd_portraitIdx = g:prd_portraitIdx + a:step 
        if g:prd_portraitIdx == len(g:prd_portrait)
            let g:prd_portraitIdx = 0
        elseif g:prd_portraitIdx < 0
            let g:prd_portraitIdx = len(g:prd_portrait) - 1
        endif
        let l:element = g:prd_portrait[g:prd_portraitIdx]
    
    " - header size                                                    {{{3
    elseif l:lineNr == s:optLine.header
        let g:prd_headerSizeIdx = g:prd_headerSizeIdx + a:step 
        if g:prd_headerSizeIdx == len(g:prd_headerSizes)
            let g:prd_headerSizeIdx = 0
        elseif g:prd_headerSizeIdx < 0
            let g:prd_headerSizeIdx = len(g:prd_headerSizes) - 1
        endif
        let l:element = g:prd_headerSizes[g:prd_headerSizeIdx]
    
    " - line numbering                                                 {{{3
    elseif l:lineNr == s:optLine.number
        let g:prd_numberLinesIdx = g:prd_numberLinesIdx + a:step 
        if g:prd_numberLinesIdx == len(g:prd_numberLines)
            let g:prd_numberLinesIdx = 0
        elseif g:prd_numberLinesIdx < 0
            let g:prd_numberLinesIdx = len(g:prd_numberLines) - 1
        endif
        let l:element = g:prd_numberLines[g:prd_numberLinesIdx]
    
    " - syntax highlighting                                            {{{3
    elseif l:lineNr == s:optLine.syntax
        let g:prd_syntaxSchemeIdx = g:prd_syntaxSchemeIdx + a:step 
        if g:prd_syntaxSchemeIdx == len(g:prd_syntaxSchemes)
            let g:prd_syntaxSchemeIdx = 0
        elseif g:prd_syntaxSchemeIdx < 0
            let g:prd_syntaxSchemeIdx = len(g:prd_syntaxSchemes) - 1
        endif
        let l:element = g:prd_syntaxSchemes[g:prd_syntaxSchemeIdx]
    
    " - line wrapping                                                  {{{3
    elseif l:lineNr == s:optLine.wrap
        let g:prd_wrapLineIdx = g:prd_wrapLineIdx + a:step 
        if g:prd_wrapLineIdx == len(g:prd_wrapLines)
            let g:prd_wrapLineIdx = 0
        elseif g:prd_wrapLineIdx < 0
            let g:prd_wrapLineIdx = len(g:prd_wrapLines) - 1
        endif
        let l:element = g:prd_wrapLines[g:prd_wrapLineIdx]
    
    " - duplex                                                         {{{3
    elseif l:lineNr == s:optLine.duplex
        let g:prd_duplexIdx = g:prd_duplexIdx + a:step 
        if g:prd_duplexIdx == len(g:prd_duplex)
            let g:prd_duplexIdx = 0
        elseif g:prd_duplexIdx < 0
            let g:prd_duplexIdx = len(g:prd_duplex) - 1
        endif
        let l:element = g:prd_duplex[g:prd_duplexIdx]
    
    " - collate                                                        {{{3
    elseif l:lineNr == s:optLine.collate
        let g:prd_collateIdx = g:prd_collateIdx + a:step 
        if g:prd_collateIdx == len(g:prd_collate)
            let g:prd_collateIdx = 0
        elseif g:prd_collateIdx < 0
            let g:prd_collateIdx = len(g:prd_collate) - 1
        endif
        let l:element = g:prd_collate[g:prd_collateIdx]
    
    " - split copies into separate print jobs                          {{{3
    elseif l:lineNr == s:optLine.splitJob
        let g:prd_splitPrintJobIdx = g:prd_splitPrintJobIdx + a:step 
        if g:prd_splitPrintJobIdx == len(g:prd_splitPrintJob)
            let g:prd_splitPrintJobIdx = 0
        elseif g:prd_splitPrintJobIdx < 0
            let g:prd_splitPrintJobIdx = len(g:prd_splitPrintJob) - 1
        endif
        let l:element = g:prd_splitPrintJob[g:prd_splitPrintJobIdx]
    
    " - margins                                                        {{{3
    elseif l:lineNr == s:optLine.left
        let g:prd_leftMarginIdx = g:prd_leftMarginIdx + a:step 
        if g:prd_leftMarginIdx == len(g:prd_leftMargin)
            let g:prd_leftMarginIdx = 0
        elseif g:prd_leftMarginIdx < 0
            let g:prd_leftMarginIdx = len(g:prd_leftMargin) - 1
        endif
        let l:element = g:prd_leftMargin[g:prd_leftMarginIdx]
    elseif l:lineNr == s:optLine.right
        let g:prd_rightMarginIdx = g:prd_rightMarginIdx + a:step 
        if g:prd_rightMarginIdx == len(g:prd_rightMargin)
            let g:prd_rightMarginIdx = 0
        elseif g:prd_rightMarginIdx < 0
            let g:prd_rightMarginIdx = len(g:prd_rightMargin) - 1
        endif
        let l:element = g:prd_rightMargin[g:prd_rightMarginIdx]
    elseif l:lineNr == s:optLine.top
        let g:prd_topMarginIdx = g:prd_topMarginIdx + a:step 
        if g:prd_topMarginIdx == len(g:prd_topMargin)
            let g:prd_topMarginIdx = 0
        elseif g:prd_topMarginIdx < 0
            let g:prd_topMarginIdx = len(g:prd_topMargin) - 1
        endif
        let l:element = g:prd_topMargin[g:prd_topMarginIdx]
    elseif l:lineNr == s:optLine.bottom
        let g:prd_bottomMarginIdx = g:prd_bottomMarginIdx + a:step 
        if g:prd_bottomMarginIdx == len(g:prd_bottomMargin)
            let g:prd_bottomMarginIdx = 0
        elseif g:prd_bottomMarginIdx < 0
            let g:prd_bottomMarginIdx = len(g:prd_bottomMargin) - 1
        endif
        let l:element = g:prd_bottomMargin[g:prd_bottomMarginIdx]
    
    " - display windows print dialog                                   {{{3
    elseif l:lineNr == s:optLine.osPrintDialog
        let g:prd_osPrintDialogIdx = g:prd_osPrintDialogIdx + a:step 
        if g:prd_osPrintDialogIdx == len(g:prd_osPrintDialog)
            let g:prd_osPrintDialogIdx = 0
        elseif g:prd_osPrintDialogIdx < 0
            let g:prd_osPrintDialogIdx = len(g:prd_osPrintDialog) - 1
        endif
        let l:element = g:prd_osPrintDialog[g:prd_osPrintDialogIdx]
    
    " - handle case where cursor not on parameter                      {{{3
    else
        echo 'no parameter under cursor...'
        return
    endif                                                            " }}}3
    
    " display newly selected option value
    " - move to start of option field, delete to end of line
    "   and write new option value
    setlocal modifiable
    let l:colNr  = col('.')  " remember current position
    call cursor(l:lineNr, s:colPara)  " move to option field
    execute 'normal d$a' . '<' . l:element . '>'
    call cursor(l:lineNr, l:colNr)  " return to previous position
    setlocal nomodifiable

endfunction

" <SID>PRD_ShowHelpOnParameter()                                       {{{2
"  intent: how help on parameter under cursor
"  params: nil
"  insert: nil
"  return: n/a
function <SID>PRD_ShowHelpOnParameter()

    let l:lineNr = line('.')
    if     l:lineNr == s:optLine.printDevice
        echo 'printer device to be used for printing'
    elseif l:lineNr == s:optLine.font
        echo "font and it's size used for printing"
    elseif l:lineNr == s:optLine.paper
        echo 'format of paper'
    elseif l:lineNr == s:optLine.portrait
        echo 'orientation of paper: <yes> portrait, <no> landscape'
    elseif l:lineNr == s:optLine.header
        echo 'number of lines for header: <0> no header'
    elseif l:lineNr == s:optLine.number
        echo 'print line-numbers'
    elseif l:lineNr == s:optLine.syntax
        echo 'use syntax-highlighting: <no> off, else use colorscheme'
    elseif l:lineNr == s:optLine.wrap
        echo '<yes> wrap long lines, <no> truncate long lines'
    elseif l:lineNr == s:optLine.duplex
        echo '<off> print on one side, <long>/<short> print on both sides'
    elseif l:lineNr == s:optLine.collate
        echo '<yes> collating 123, 123, 123, '
                    \ . '<no> no collating 111, 222, 333'
    elseif l:lineNr == s:optLine.splitJob
        echo '<yes> each copy separate job, <no> all copies one job'
    elseif l:lineNr == s:optLine.left
        echo 'left margin'
    elseif l:lineNr == s:optLine.right
        echo 'right margin'
    elseif l:lineNr == s:optLine.top
        echo 'top margin'
    elseif l:lineNr == s:optLine.bottom
        echo 'bottom margin'
    elseif l:lineNr == s:optLine.osPrintDialog
        echo 'MS-Windows only: show printer dialog'
    else
        echo 'to get help move cursor on parameter'
    endif

endfunction

" <SID>PRD_StartPrinting()                                             {{{2
"  intent: start printing
"  params: nil
"  insert: nil
"  return: boolean (success)
function <SID>PRD_StartPrinting()

    " ensure buffer to be printed still exists                         {{{3
    if !bufexists(s:buffer.src)
        execute 'dbuffer' s:buffer.user
        echo s:scriptName . ': buffer to be printed does not exist'
        return
    endif
    
    " switch to buffer to be printed                                   {{{3
    " - this automatically deleted the current dialog buffer
    execute 'buffer' s:buffer.src

    " backup vim print and colorscheme settings
    call s:BackupSettings()
    
    " set arguments for ':hardcopy'                                    {{{3
    call s:SetPrintdevice()             " printdevice
    call s:SetPrintoptions()            " printoptions 
    call s:SetPrintfont()               " printfont
    call s:SetPrintheader()             " printheader
    call s:SetColorschemeForPrinting()  " syntax colorscheme
    
    " construct print command                                          {{{3
    let l:cmd = s:range.start . ',' . s:range.end . 'hardcopy'
    let l:show_win_dialog = tolower(
                \ g:prd_osPrintDialog[g:prd_osPrintDialogIdx])
    if l:show_win_dialog ==# 'no'
        let l:cmd .= '!'  
    endif

    " work with plugins that alter 'printexpr'
    let l:printexpr_backup = &printexpr
    let &printexpr = s:default_printexpr

    " execute print command                                            {{{3
    execute l:cmd
    
    " work with plugins that alter 'printexpr'
    let &printexpr = l:printexpr_backup

    " restore vim print and colorscheme settings                       {{{3
    call s:RestoreSettings()
    
    " signal success                                                   {{{3
    return 1                                                         " }}}3

endfunction
                                                                     " }}}1

" vim: fdm=marker :
