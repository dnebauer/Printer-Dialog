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
vmap <silent> <unique> <script> <Plug>PRD_PrinterDialogVisual <ESC>:call <SID>PRD_StartPrinterDialog(1)<CR>
nmap <silent> <unique> <script> <Plug>PRD_PrinterDialogNormal      :call <SID>PRD_StartPrinterDialog(0)<CR>


" INITIALISATION:                                                      {{{1

" used to print/echo name of script                                    {{{2
let s:scriptName = 'PrtDialog'

" colorscheme loaded for printing?                                     {{{2
let s:flagColorschemeDone = 0

" default 'printexpr' (obtained from |:help pexpr-option|)             {{{2
let s:defaultPrintexpr = "system('lpr' . (&printdevice == '' ? '' "
            \ . ": ' -P' . &printdevice) . ' ' . v:fname_in) . "
            \ . 'delete(v:fname_in) + v:shell_error'

" buffer variable                                                      {{{2
let s:buffer = {}


" INTERFACE FUNCTIONS:                                                 {{{1

" <SID>PRD_StartPrinterDialog(printRange)                              {{{2
"  intent: get range to be printed and buffer, then start user interface
"  params: printRange - whether to print visual selection only,
"                       or whole document [boolean]
"  insert: nil
"  return: n/a
function <SID>PRD_StartPrinterDialog(printRange)
    
    " check that vim is compiled with print option                     {{{3
    if !has('printer')  " is this vim compiled with printing enabled?
        echo s:scriptName 
                    \ . ': this version of VIM does not support printing'
        return
    endif
    let s:printRange = a:printRange

    " get range to be printed                                          {{{3
    if s:printRange
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
    if  s:printRange
        let l:range = 'lines ' . s:range.start . ' - ' . s:range.end
    else
        let l:range = 'whole file'
    endif
    
    " set up syntax highlighting                                       {{{3
    call s:SetupSyntax()

    " set print option choices                                         {{{3
    call s:SetPrintOptionChoices()

    " set column of parameter                                          {{{3
    let s:colPara = 14
    
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
                \ . s:prd_printDevices[s:prd_printDeviceIdx]
                \ . '>')
    let s:optLine.printDevice = len(l:c)
    call add(l:c, '')
    call add(l:c, '>Options:')
    call add(l:c, '   Font:     <'
                \ . s:prd_fonts[s:prd_fontIdx]
                \ . '>')
    let s:optLine.font = len(l:c)
    call add(l:c, '   Paper:    <'
                \ . s:prd_paperSizes[s:prd_paperSizeIdx]
                \ . '>')
    let s:optLine.paper = len(l:c)
    call add(l:c, '   Portrait: <'
                \ . s:prd_portrait[s:prd_portraitIdx]
                \ . '>')
    let s:optLine.portrait = len(l:c)
    call add(l:c, '')
    call add(l:c, '   Header:   <'
                \ . s:prd_headerSizes[s:prd_headerSizeIdx]
                \ . '>')
    let s:optLine.header = len(l:c)
    call add(l:c, '   Line-Nr:  <' 
                \ . s:prd_numberLines[s:prd_numberLinesIdx]
                \ . '>')
    let s:optLine.number = len(l:c)
    call add(l:c, '   Syntax:   <' 
                \ . s:prd_syntaxSchemes[s:prd_syntaxSchemeIdx]
                \ . '>')
    let s:optLine.syntax = len(l:c)
    call add(l:c, '')
    call add(l:c, '   Wrap:     <' 
                \ . s:prd_wrapLines[s:prd_wrapLinesIdx]
                \ . '>')
    let s:optLine.wrap = len(l:c)
    call add(l:c, '   Duplex:   <' 
                \ . s:prd_duplex[s:prd_duplexIdx]
                \ . '>')
    let s:optLine.duplex = len(l:c)
    call add(l:c, '   Collate:  <' 
                \ . s:prd_collate[s:prd_collateIdx]
                \ . '>')
    let s:optLine.collate = len(l:c)
    call add(l:c, '   JobSplit: <' 
                \ . s:prd_splitPrintJob[s:prd_splitPrintJobIdx]
                \ . '>')
    let s:optLine.splitJob = len(l:c)
    call add(l:c, '')
    call add(l:c, '   Left:     <' 
                \ . s:prd_leftMargin[s:prd_leftMarginIdx]
                \ . '>')
    let s:optLine.left = len(l:c)
    call add(l:c, '   Right:    <' 
                \ . s:prd_rightMargin[s:prd_rightMarginIdx]
                \ . '>')
    let s:optLine.right = len(l:c)
    call add(l:c, '   Top:      <' 
                \ . s:prd_topMargin[s:prd_topMarginIdx]
                \ . '>')
    let s:optLine.top = len(l:c)
    call add(l:c, '   Bottom:   <' 
                \ . s:prd_bottomMargin[s:prd_bottomMarginIdx]
                \ . '>')
    let s:optLine.bottom = len(l:c)
    call add(l:c, '')
    call add(l:c, '   Dialog:   <' 
                \ . s:prd_osPrintDialog[s:prd_osPrintDialogIdx]
                \ . '>')
    let s:optLine.osPrintDialog = len(l:c)
    
    " write content to buffer                                          {{{3
    let l:txt = join(l:c, "\n")
    setlocal modifiable
    %delete
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

" s:SetPrintOptionChoices()                                            {{{2
"  intent: (re)set print options
"  params: nil
"  prints: nil
"  return: n/a
function! s:SetPrintOptionChoices()

    " devices [default: standard]                                      {{{3
    "   . always rescan in absence of user setting because new
    "     print devices may have been enabled since last print
    if exists('g:prd_printDevices')
        let s:prd_printDevices = copy(g:prd_printDevices)
    else
        call s:SetPrintDeviceOptionChoices()
    endif
    if !exists('s:prd_printDeviceIdx')
        if exists('g:prd_printDeviceIdx')
            let s:prd_printDeviceIdx = g:prd_printDeviceIdx
        else
            let s:prd_printDeviceIdx = 0
        endif
    endif

    " fonts [default: courier 8]                                       {{{3
    if !exists('s:prd_fonts')
        if exists('g:prd_fonts')
            let s:prd_fonts = copy(g:prd_fonts)
        else
            let s:prd_fonts = ['courier:h6',  'courier:h8',
                        \      'courier:h10', 'courier:h12',
                        \      'courier:h14']
        endif
    endif
    if !exists('s:prd_fontIdx')
        if exists('g:prd_fontIdx')
            let s:prd_fontIdx = g:prd_fontIdx
        else
            let s:prd_fontIdx = 1
        endif
    endif

    " paper size [default: A4]                                         {{{3
    if !exists('s:prd_paperSizes')
        if exists('g:prd_paperSizes')
            let s:prd_paperSizes = copy(g:prd_paperSizes)
        else
            let s:prd_paperSizes = ['A3', 'A4',    'A5',     'B4',
                        \           'B5', 'legal', 'letter']
        endif
    endif
    if !exists('s:prd_paperSizeIdx')
        if exists('g:prd_paperSizeIdx')
            let s:prd_paperSizeIdx = g:prd_paperSizeIdx
        else
            let s:prd_paperSizeIdx = 1
        endif
    endif

    " orientation [default: portrait]                                  {{{3
    if !exists('s:prd_portrait')
        if exists('g:prd_portrait')
            let s:prd_portrait = g:prd_portrait
        else
            let s:prd_portrait = ['yes', 'no']
        endif
    endif
    if !exists('s:prd_portraitIdx')
        if exists('g:prd_portraitIdx')
            let s:prd_portraitIdx = g:prd_portraitIdx
        else
            let s:prd_portraitIdx = 0
        endif
    endif

    " header size [default: 2 lines]                                   {{{3
    if !exists('s:prd_headerSizes')
        if exists('g:prd_headerSizes')
            let s:prd_headerSizes = copy(g:prd_headerSizes)
        else
            let s:prd_headerSizes = [0, 1, 2, 3, 4, 5, 6]
        endif
    endif
    if !exists('s:prd_headerSizeIdx')
        if exists('g:prd_headerSizeIdx')
            let s:prd_headerSizeIdx = g:prd_headerSizeIdx
        else
            let s:prd_headerSizeIdx = 2
        endif
    endif

    " number lines [default: yes]                                      {{{3
    if !exists('s:prd_numberLines')
        if exists('g:prd_numberLines')
            let s:prd_numberLines = copy(g:prd_numberLines)
        else
            let s:prd_numberLines = ['yes', 'no']
        endif
    endif
    if !exists('s:prd_numberLinesIdx')
        if exists('g:prd_numberLinesIdx')
            let s:prd_numberLinesIdx = g:prd_numberLinesIdx
        else
            let s:prd_numberLinesIdx = 0
        endif
    endif

    " syntax highlighting and colour scheme [default: vim default]     {{{3
    if !exists('s:prd_syntaxSchemes')
        if exists('g:prd_syntaxSchemes')
            let s:prd_syntaxSchemes = copy(g:prd_syntaxSchemes)
        else
            let s:prd_syntaxSchemes = ['no', 'current', 'default']
            for l:scheme in ['print_bw', 'zellner', 'solarized']
                let l:path = 'colors/' . l:scheme . '.vim'
                if !empty(globpath(&runtimepath, l:path, 1, 1))
                    call add(s:prd_syntaxSchemes, l:scheme)
                endif
            endfor
        endif
    endif
    if !exists('s:prd_syntaxSchemeIdx')
        if exists('g:prd_syntaxSchemeIdx')
            let s:prd_syntaxSchemeIdx = g:prd_syntaxSchemeIdx
        else
            let s:prd_syntaxSchemeIdx = 2
        endif
    endif

    " wrap or truncate long lines [default: wrap]                      {{{3
    if !exists('s:prd_wrapLines')
        if exists('g:prd_wrapLines')
            let s:prd_wrapLines = copy(g:prd_wrapLines)
        else
            let s:prd_wrapLines = ['yes', 'no']
        endif
    endif
    if !exists('s:prd_wrapLinesIdx')
        if exists('g:prd_wrapLinesIdx')
            let s:prd_wrapLinesIdx = g:prd_wrapLinesIdx
        else
            let s:prd_wrapLinesIdx = 0
        endif
    endif

    " duplex [default: on, bind on long edge]                          {{{3
    if !exists('s:prd_duplex')
        if exists('g:prd_duplex')
            let s:prd_duplex = copy(g:prd_duplex)
        else
            let s:prd_duplex = ['off', 'long', 'short']
        endif
    endif
    if !exists('s:prd_duplexIdx')
        if exists('g:prd_duplexIdx')
            let s:prd_duplexIdx = g:prd_duplexIdx
        else
            let s:prd_duplexIdx = 1
        endif
    endif

    " collate [default: yes]                                           {{{3
    if !exists('s:prd_collate')
        if exists('g:prd_collate')
            let s:prd_collate = copy(g:prd_collate)
        else
            let s:prd_collate = ['yes', 'no']
        endif
    endif
    if !exists('s:prd_collateIdx')
        if exists('g:prd_collateIdx')
            let s:prd_collateIdx = g:prd_collateIdx
        else
            let s:prd_collateIdx = 0
        endif
    endif

    " split copies into separate print jobs [default: no]              {{{3
    if !exists('s:prd_splitPrintJob')
        if exists('g:prd_splitPrintJob')
            let s:prd_splitPrintJob = copy(g:prd_splitPrintJob)
        else
            let s:prd_splitPrintJob = ['yes', 'no']
        endif
    endif
    if !exists('s:prd_splitPrintJobIdx')
        if exists('g:prd_splitPrintJobIdx')
            let s:prd_splitPrintJobIdx = g:prd_splitPrintJobIdx
        else
            let s:prd_splitPrintJobIdx = 1
        endif
    endif

    " left margin [default: 15mm]                                      {{{3
    if !exists('s:prd_leftMargin')
        if exists('g:prd_leftMargin')
            let s:prd_leftMargin = copy(g:prd_leftMargin)
        else
            let s:prd_leftMargin = ['5mm',  '10mm', '15mm',
                        \           '20mm', '25mm']
        endif
    endif
    if !exists('s:prd_leftMarginIdx')
        if exists('g:prd_leftMarginIdx')
            let s:prd_leftMarginIdx = g:prd_leftMarginIdx
        else
            let s:prd_leftMarginIdx = 2
        endif
    endif

    " right margin [default: 15mm]                                     {{{3
    if !exists('s:prd_rightMargin')
        if exists('g:prd_rightMargin')
            let s:prd_rightMargin = copy(g:prd_rightMargin)
        else
            let s:prd_rightMargin = ['5mm',  '10mm', '15mm',
                        \            '20mm', '25mm']
        endif
    endif
    if !exists('s:prd_rightMarginIdx')
        if exists('g:prd_rightMarginIdx')
            let s:prd_rightMarginIdx = g:prd_rightMarginIdx
        else
            let s:prd_rightMarginIdx = 2
        endif
    endif

    " top margin [default: 10mm]                                       {{{3
    if !exists('s:prd_topMargin')
        if exists('g:prd_topMargin')
            let s:prd_topMargin = copy(g:prd_topMargin)
        else
            let s:prd_topMargin = ['5mm',  '10mm', '15mm',
                        \          '20mm', '25mm']
        endif
    endif
    if !exists('s:prd_topMarginIdx')
        if exists('g:prd_topMarginIdx')
            let s:prd_topMarginIdx = g:prd_topMarginIdx
        else
            let s:prd_topMarginIdx = 1
        endif
    endif

    " bottom margin [default: 10mm]                                    {{{3
    if !exists('s:prd_bottomMargin')
        if exists('g:prd_bottomMargin')
            let s:prd_bottomMargin = copy(g:prd_bottomMargin)
        else
            let s:prd_bottomMargin = ['5mm',  '10mm', '15mm',
                        \             '20mm', '25mm']
        endif
    endif
    if !exists('s:prd_bottomMarginIdx')
        if exists('g:prd_bottomMarginIdx')
            let s:prd_bottomMarginIdx = g:prd_bottomMarginIdx
        else
            let s:prd_bottomMarginIdx = 1
        endif
    endif

    " show Windows print dialog before printing [default: no]          {{{3
    if !exists('s:prd_osPrintDialog')
        if exists('g:prd_osPrintDialog')
            let s:prd_osPrintDialog = copy(g:prd_osPrintDialog)
        else
            let s:prd_osPrintDialog = ['yes', 'no']
        endif
    endif
    if !exists('s:prd_osPrintDialogIdx')
        if exists('g:prd_osPrintDialogIdx')
            let s:prd_osPrintDialogIdx = g:prd_osPrintDialogIdx
        else
            let s:prd_osPrintDialogIdx = 1
        endif
    endif

    " printheader                                                      {{{3
    if !exists('s:prd_printheader')
        if exists('g:prd_printheader')
            let s:prd_printheader = g:prd_printheader
        else
            let s:prd_printheader = &printheader
        endif
    endif                                                            " }}}3

endfunction
" s:SetPrintDeviceOptionChoices()                                      {{{2
"  intent: scan for print devices and add them to standard options
"  params: nil
"  prints: nil
"  return: n/a
function! s:SetPrintDeviceOptionChoices()

    " get previously selected printer                                  {{{3
    if exists('s:prd_printDevices') && !empty(s:prd_printDevices)
                \ && exists('s:prd_printDeviceIdx')
                \ && s:prd_printDeviceIdx !=? ''
        let s:previousPrintDevice =
                    \ s:prd_printDevices[s:prd_printDeviceIdx]
    endif

    " add default print device                                         {{{3
    let s:prd_printDevices = ['standard']

    " check for utils needed to extract print devices                  {{{3
    let l:missing_exes = []
    for l:exe in ['lpstat', 'grep', 'awk']
        if !executable(l:exe)
            call add(l:missing_exes, l:exe)
        endif
    endfor

    " exit if missing required utils                                   {{{3
    " - display error message once only per session
    if !empty(l:missing_exes)
        if !exists('s:displayedMissingExeMessage')
            let s:displayedMissingExeMessage = 1
            echo "Can't retrieve print device listing -"
            echo '  missing ' .join(l:missing_exes, ', ')
        endif
        return
    endif

    " get print devices                                                {{{3
    let l:cmd = "lpstat -p | grep '^printer' | grep 'enabled' "
                \ . "| awk '{print $2}'"
    let l:print_devices = systemlist(l:cmd)
    if v:shell_error
        echoerr 'Unable to obtain print device listing'
        if len(l:print_devices)
            echoerr 'Shell feedback:'
            for l:line in l:print_devices
                echoerr '  ' . l:line
            endfor
        endif
    endif

    " add new print devices                                            {{{3
    call extend(s:prd_printDevices, l:print_devices)

    " get default device                                               {{{3
    let l:cmd = "lpstat -d | awk '{print $NF}'"
    let l:default_device = systemlist(l:cmd)
    if v:shell_error || len(l:default_device)    != 1
                \    || len(l:default_device[0]) == 0
        echoerr 'Unable to obtain default print device'
        if len(l:default_device)
            echoerr 'Shell feedback:'
            for l:line in l:default_device
                echoerr '  ' . l:line
            endfor
        endif
        return
    endif
    
    " set default device                                               {{{3
    " - use previously selected printer if available,
    "   otherwise use the default system printer
    let l:default_position = index(s:prd_printDevices,
                \                  l:default_device[0])
    if l:default_position != -1
        let s:prd_printDeviceIdx = l:default_position
    endif
    if exists('s:previousPrintDevice')
        let l:default_position = index(s:prd_printDevices,
                    \                  s:previousPrintDevice)
        if l:default_position != -1
            let s:prd_printDeviceIdx = l:default_position
        endif
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

    let l:element = s:prd_printDevices[s:prd_printDeviceIdx]
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
    let l:opts .= ',left:'   . s:prd_leftMargin[s:prd_leftMarginIdx]
    let l:opts .= ',right:'  . s:prd_rightMargin[s:prd_rightMarginIdx]
    let l:opts .= ',top:'    . s:prd_topMargin[s:prd_topMarginIdx]
    let l:opts .= ',bottom:' . s:prd_bottomMargin[s:prd_bottomMarginIdx]
    
    " header                                                           {{{3
    let l:opts .= ',header:' . s:prd_headerSizes[s:prd_headerSizeIdx]
    
    " duplex                                                           {{{3
    let l:opts .= ',duplex:' . s:prd_duplex[s:prd_duplexIdx]
    
    " paper size                                                       {{{3
    let l:opts .= ',paper:'  . s:prd_paperSizes[s:prd_paperSizeIdx]
    
    " line numbering                                                   {{{3
    let l:opts .= ',number:' . strpart(
                \ s:prd_numberLines[s:prd_numberLinesIdx], 0, 1)
    
    " line wrapping                                                    {{{3
    let l:opts .= ',wrap:'   . strpart(
                \ s:prd_wrapLines[s:prd_wrapLinesIdx], 0, 1)
    
    " collate                                                          {{{3
    let l:opts .= ',collate:'  . strpart(
                \ s:prd_collate[s:prd_collateIdx], 0, 1)
    
    " split copies into individual print jobs                          {{{3
    let l:opts .= ',jobSplit:' . strpart(
                \ s:prd_splitPrintJob[s:prd_splitPrintJobIdx], 0, 1)
    
    " orientation                                                      {{{3
    let l:opts .= ',portrait:' . strpart(
                \ s:prd_portrait[s:prd_portraitIdx], 0, 1)
    
    " syntax highlighting                                              {{{3
    if has('syntax')
        if s:prd_syntaxSchemes[s:prd_syntaxSchemeIdx] ==? 'no'
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

    let &printfont = s:prd_fonts[s:prd_fontIdx]

endfunction

" s:SetPrintheader()                                                   {{{2
"  intent: set 'printheader' from user selection
"  params: nil
"  insert: nil
"  return: n/a
function s:SetPrintheader()

    let &printheader = s:prd_printheader

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
    let l:element = tolower(s:prd_syntaxSchemes[s:prd_syntaxSchemeIdx]) 
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
"  params: step - direction to increment
"                 [integer, 1 = next, -1 = previous]
"  insert: new option value
"  return: n/a
function <SID>PRD_ToggleParameter(step)

    let l:lineNr  = line('.')
    let l:element = ''

    " adjust index of appropriate option, handling wrap around
    " then extract new option value:
    " - print device                                                   {{{3
    if     l:lineNr == s:optLine.printDevice
        let s:prd_printDeviceIdx = s:prd_printDeviceIdx + a:step 
        if s:prd_printDeviceIdx == len(s:prd_printDevices)
            let s:prd_printDeviceIdx = 0
        elseif s:prd_printDeviceIdx < 0
            let s:prd_printDeviceIdx = len(s:prd_printDevices) - 1
        endif
        let l:element = s:prd_printDevices[s:prd_printDeviceIdx]

    " - font                                                           {{{3
    elseif l:lineNr == s:optLine.font
        let s:prd_fontIdx = s:prd_fontIdx + a:step 
        if s:prd_fontIdx == len(s:prd_fonts)
            let s:prd_fontIdx = 0
        elseif s:prd_fontIdx < 0
            let s:prd_fontIdx = len(s:prd_fonts) - 1
        endif
        let l:element = s:prd_fonts[s:prd_fontIdx]

    " - paper size                                                     {{{3
    elseif l:lineNr == s:optLine.paper
        let s:prd_paperSizeIdx = s:prd_paperSizeIdx + a:step 
        if s:prd_paperSizeIdx == len(s:prd_paperSizes)
            let s:prd_paperSizeIdx = 0
        elseif s:prd_paperSizeIdx < 0
            let s:prd_paperSizeIdx = len(s:prd_paperSizes) - 1
        endif
        let l:element = s:prd_paperSizes[s:prd_paperSizeIdx]
    
    " - orientation                                                    {{{3
    elseif l:lineNr == s:optLine.portrait
        let s:prd_portraitIdx = s:prd_portraitIdx + a:step 
        if s:prd_portraitIdx == len(s:prd_portrait)
            let s:prd_portraitIdx = 0
        elseif s:prd_portraitIdx < 0
            let s:prd_portraitIdx = len(s:prd_portrait) - 1
        endif
        let l:element = s:prd_portrait[s:prd_portraitIdx]
    
    " - header size                                                    {{{3
    elseif l:lineNr == s:optLine.header
        let s:prd_headerSizeIdx = s:prd_headerSizeIdx + a:step 
        if s:prd_headerSizeIdx == len(s:prd_headerSizes)
            let s:prd_headerSizeIdx = 0
        elseif s:prd_headerSizeIdx < 0
            let s:prd_headerSizeIdx = len(s:prd_headerSizes) - 1
        endif
        let l:element = s:prd_headerSizes[s:prd_headerSizeIdx]
    
    " - line numbering                                                 {{{3
    elseif l:lineNr == s:optLine.number
        let s:prd_numberLinesIdx = s:prd_numberLinesIdx + a:step 
        if s:prd_numberLinesIdx == len(s:prd_numberLines)
            let s:prd_numberLinesIdx = 0
        elseif s:prd_numberLinesIdx < 0
            let s:prd_numberLinesIdx = len(s:prd_numberLines) - 1
        endif
        let l:element = s:prd_numberLines[s:prd_numberLinesIdx]
    
    " - syntax highlighting                                            {{{3
    elseif l:lineNr == s:optLine.syntax
        let s:prd_syntaxSchemeIdx = s:prd_syntaxSchemeIdx + a:step 
        if s:prd_syntaxSchemeIdx == len(s:prd_syntaxSchemes)
            let s:prd_syntaxSchemeIdx = 0
        elseif s:prd_syntaxSchemeIdx < 0
            let s:prd_syntaxSchemeIdx = len(s:prd_syntaxSchemes) - 1
        endif
        let l:element = s:prd_syntaxSchemes[s:prd_syntaxSchemeIdx]
    
    " - line wrapping                                                  {{{3
    elseif l:lineNr == s:optLine.wrap
        let s:prd_wrapLinesIdx = s:prd_wrapLinesIdx + a:step 
        if s:prd_wrapLinesIdx == len(s:prd_wrapLines)
            let s:prd_wrapLinesIdx = 0
        elseif s:prd_wrapLinesIdx < 0
            let s:prd_wrapLinesIdx = len(s:prd_wrapLines) - 1
        endif
        let l:element = s:prd_wrapLines[s:prd_wrapLinesIdx]
    
    " - duplex                                                         {{{3
    elseif l:lineNr == s:optLine.duplex
        let s:prd_duplexIdx = s:prd_duplexIdx + a:step 
        if s:prd_duplexIdx == len(s:prd_duplex)
            let s:prd_duplexIdx = 0
        elseif s:prd_duplexIdx < 0
            let s:prd_duplexIdx = len(s:prd_duplex) - 1
        endif
        let l:element = s:prd_duplex[s:prd_duplexIdx]
    
    " - collate                                                        {{{3
    elseif l:lineNr == s:optLine.collate
        let s:prd_collateIdx = s:prd_collateIdx + a:step 
        if s:prd_collateIdx == len(s:prd_collate)
            let s:prd_collateIdx = 0
        elseif s:prd_collateIdx < 0
            let s:prd_collateIdx = len(s:prd_collate) - 1
        endif
        let l:element = s:prd_collate[s:prd_collateIdx]
    
    " - split copies into separate print jobs                          {{{3
    elseif l:lineNr == s:optLine.splitJob
        let s:prd_splitPrintJobIdx = s:prd_splitPrintJobIdx + a:step 
        if s:prd_splitPrintJobIdx == len(s:prd_splitPrintJob)
            let s:prd_splitPrintJobIdx = 0
        elseif s:prd_splitPrintJobIdx < 0
            let s:prd_splitPrintJobIdx = len(s:prd_splitPrintJob) - 1
        endif
        let l:element = s:prd_splitPrintJob[s:prd_splitPrintJobIdx]
    
    " - margins                                                        {{{3
    elseif l:lineNr == s:optLine.left
        let s:prd_leftMarginIdx = s:prd_leftMarginIdx + a:step 
        if s:prd_leftMarginIdx == len(s:prd_leftMargin)
            let s:prd_leftMarginIdx = 0
        elseif s:prd_leftMarginIdx < 0
            let s:prd_leftMarginIdx = len(s:prd_leftMargin) - 1
        endif
        let l:element = s:prd_leftMargin[s:prd_leftMarginIdx]
    elseif l:lineNr == s:optLine.right
        let s:prd_rightMarginIdx = s:prd_rightMarginIdx + a:step 
        if s:prd_rightMarginIdx == len(s:prd_rightMargin)
            let s:prd_rightMarginIdx = 0
        elseif s:prd_rightMarginIdx < 0
            let s:prd_rightMarginIdx = len(s:prd_rightMargin) - 1
        endif
        let l:element = s:prd_rightMargin[s:prd_rightMarginIdx]
    elseif l:lineNr == s:optLine.top
        let s:prd_topMarginIdx = s:prd_topMarginIdx + a:step 
        if s:prd_topMarginIdx == len(s:prd_topMargin)
            let s:prd_topMarginIdx = 0
        elseif s:prd_topMarginIdx < 0
            let s:prd_topMarginIdx = len(s:prd_topMargin) - 1
        endif
        let l:element = s:prd_topMargin[s:prd_topMarginIdx]
    elseif l:lineNr == s:optLine.bottom
        let s:prd_bottomMarginIdx = s:prd_bottomMarginIdx + a:step 
        if s:prd_bottomMarginIdx == len(s:prd_bottomMargin)
            let s:prd_bottomMarginIdx = 0
        elseif s:prd_bottomMarginIdx < 0
            let s:prd_bottomMarginIdx = len(s:prd_bottomMargin) - 1
        endif
        let l:element = s:prd_bottomMargin[s:prd_bottomMarginIdx]
    
    " - display windows print dialog                                   {{{3
    elseif l:lineNr == s:optLine.osPrintDialog
        let s:prd_osPrintDialogIdx = s:prd_osPrintDialogIdx + a:step 
        if s:prd_osPrintDialogIdx == len(s:prd_osPrintDialog)
            let s:prd_osPrintDialogIdx = 0
        elseif s:prd_osPrintDialogIdx < 0
            let s:prd_osPrintDialogIdx = len(s:prd_osPrintDialog) - 1
        endif
        let l:element = s:prd_osPrintDialog[s:prd_osPrintDialogIdx]
    
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
                \ s:prd_osPrintDialog[s:prd_osPrintDialogIdx])
    if l:show_win_dialog ==# 'no'
        let l:cmd .= '!'  
    endif

    " work with plugins that alter 'printexpr'
    let l:printexpr_backup = &printexpr
    let &printexpr = s:defaultPrintexpr

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
