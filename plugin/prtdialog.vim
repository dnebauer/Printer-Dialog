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

" - devices [default: default]                                         {{{3
if !exists('g:prd_prtDeviceList')
    let g:prd_prtDeviceList = 'standard'
endif
if !exists('g:prd_prtDeviceIdx')
    let g:prd_prtDeviceIdx  = 1
endif

" - fonts [default: courier 8]                                         {{{3
if !exists('g:prd_fontList')
    let g:prd_fontList = 'courier:h6,courier:h8,courier:h10,'
                \ . 'courier:h12,courier:h14'
endif
if !exists('g:prd_fontIdx')
    let g:prd_fontIdx  = 2
endif

" - paper size [default: A4]                                           {{{3
if !exists('g:prd_paperList')
    let g:prd_paperList = 'A3,A4,A5,B4,B5,legal,letter'
endif
if !exists('g:prd_paperIdx')
    let g:prd_paperIdx  = 2
endif

" - orientation [default: portrait]                                    {{{3
if !exists('g:prd_portraitList')
    let g:prd_portraitList = 'yes,no'
endif
if !exists('g:prd_portraitIdx')
    let g:prd_portraitIdx  = 1
endif

" - header size [default: 2 lines]                                     {{{3
if !exists('g:prd_headerList')
    let g:prd_headerList = '0,1,2,3,4,5,6'
endif
if !exists('g:prd_headerIdx')
    let g:prd_headerIdx  = 3
endif

" - number lines [default: yes]                                        {{{3
if !exists('g:prd_lineNrList')
    let g:prd_lineNrList = 'yes,no'
endif
if !exists('g:prd_lineNrIdx')
    let g:prd_lineNrIdx  = 1
endif

" - syntax highlighting and colour scheme [default: vim default]       {{{3
if !exists('g:prd_syntaxList')
    let g:prd_syntaxList = 'no,current,default,print_bw,zellner'
endif
if !exists('g:prd_syntaxIdx')
    let g:prd_syntaxIdx  = 3
endif

" - wrap or truncate long lines [default: truncate]                    {{{3
if !exists('g:prd_wrapList')
    let g:prd_wrapList = 'yes,no'
endif
if !exists('g:prd_wrapIdx')
    let g:prd_wrapIdx  = 1
endif

" - duplex [default: on, bind on long edge]                            {{{3
if !exists('g:prd_duplexList')
    let g:prd_duplexList = 'off,long,short'
endif
if !exists('g:prd_duplexIdx')
    let g:prd_duplexIdx  = 2
endif

" - collate [default: yes]                                             {{{3
if !exists('g:prd_collateList')
    let g:prd_collateList = 'yes,no'
endif
if !exists('g:prd_collateIdx')
    let g:prd_collateIdx  = 1
endif

" - split copies into separate print jobs [default: no]                {{{3
if !exists('g:prd_jobSplitList')
    let g:prd_jobSplitList = 'yes,no'
endif
if !exists('g:prd_jobSplitIdx')
    let g:prd_jobSplitIdx  = 2
endif

" - left margin [default: 15mm]                                        {{{3
if !exists('g:prd_leftList')
    let g:prd_leftList = '5mm,10mm,15mm,20mm,25mm'
endif
if !exists('g:prd_leftIdx')
    let g:prd_leftIdx  = 3
endif

" - right margin [default: 15mm]                                       {{{3
if !exists('g:prd_rightList')
    let g:prd_rightList = '5mm,10mm,15mm,20mm,25mm'
endif
if !exists('g:prd_rightIdx')
    let g:prd_rightIdx  = 3
endif

" - top margin [default: 10mm]                                         {{{3
if !exists('g:prd_topList')
    let g:prd_topList = '5mm,10mm,15mm,20mm,25mm'
endif
if !exists('g:prd_topIdx')
    let g:prd_topIdx  = 2
endif

" - bottom margin [default: 10mm]                                      {{{3
if !exists('g:prd_bottomList')
    let g:prd_bottomList = '5mm,10mm,15mm,20mm,25mm'
endif
if !exists('g:prd_bottomIdx')
    let g:prd_bottomIdx  = 2
endif

" - show Windows print dialog before printing [default: no]
if !exists('g:prd_dialogList')
    let g:prd_dialogList = 'yes,no'
endif
if !exists('g:prd_dialogIdx')
    let g:prd_dialogIdx  = 2
endif                                                                " }}}3

" allow user to set a script specific printheader                      {{{2
if !exists('g:prd_printheader')
    let g:prd_printheader = &printheader
endif                                                                " }}}2


" INITIALISATION:                                                      {{{1

" used to print/echo name of script                                    {{{2
let s:scriptName   = 'PrtDialog'

" delimiter for list-elements (g:prd_...List)                          {{{2
let s:chrDelimiter = ','

" colorscheme loaded for printing?                                     {{{2
let s:flagColorschemeDone = 0


" INTERFACE FUNCTIONS:                                                 {{{1

" PRD_StartPrinterDialog(whatToPrint)                                  {{{2
" intent: get range to be printed and buffer, then start user interface
" params: whatToPrint - 0 is selected range, else whole buffer
" prints: nil
" return: n/a
" vars:   sets script variables:
"         - s:whatToPrint, s:startLine, s:endLine, s:bufferUser,
"           s:bufferSrc
function <SID>PRD_StartPrinterDialog(whatToPrint)
    
    " check that vim is compiled with print option                     {{{3
    if (!has('printer'))  " is this vim compiled with printing enabled?
        echo s:scriptName.': this version of VIM does not support printing'
        return
    endif
    let s:whatToPrint = a:whatToPrint

    " get range to be printed                                          {{{3
    if (s:whatToPrint == 0)
        let s:startLine = line("'<")
        let s:endLine   = line("'>")
    else
        let s:startLine = 1
        let s:endLine   = line('$')
    endif
    
    " so far no buffer created for ui; get buffer to be printed        {{{3
    let s:bufferUser = -1
    let s:bufferSrc  = winbufnr(0)
    
    " calculate number of choices for each print option                {{{3
    call s:GetNumberOfListElements()
    
    " set up user interface                                            {{{3
    if s:OpenNewBuffer()  " buffer for user-interface
        call s:UpdateDialog()         " show the dialog
        call s:SetLocalKeyMappings()  " set keys for user (local to buffer)
    endif                                                            " }}}3

endfunction                                                          " }}}2


" CORE FUNCTIONS:                                                      {{{1

" s:OpenNewBuffer()                                                    {{{2
" intent: open a new buffer for user interaction
" params: nil
" prints: new buffer
" return: boolean (success)
function s:OpenNewBuffer()

    " open buffer                                                      {{{3
    execute 'enew'
    let s:bufferUser = winbufnr(0)
    
    " abort if opened self                                             {{{3
    if (s:bufferUser == s:bufferSrc)
        call <SID>PRD_Exit()
        echo s:scriptName.': no buffer to be printed'
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

endfunction                                                          " }}}2

" s:UpdateDialog()                                                     {{{2
" intent: redraw print dialog
" params: nil
" prints: print buffer content
" return: n/a
" vars:   sets script variables:
"         - s:colPara,   s:lnPrtDev,   s:lnFont,   s:lnPaper, s:lnPortrait,
"           s:lnHeader,  s:lnLineNr,   s:lnSyntax, s:lnWrap,  s:lnDuplex,
"           s:lnCollate, s:lnJobSplit, s:lnLeft,   s:lnRight, s:lnTop,
"           s:lnBottom,  s:lnDialog
"         uses script variables:
"         - s:whatToPrint, s:startLine, s:endLine
function s:UpdateDialog()

    " get name of print dialog buffer                                  {{{3
    let l:strFilename = bufname(s:bufferSrc)
    if (l:strFilename ==# '')
        let l:strFilename = '[noname]'
    endif
    
    " get range of buffer to be printed                                {{{3
    if  (s:whatToPrint == 0)
        let l:strRange = 'lines ' . s:startLine . ' - ' . s:endLine
    else
        let l:strRange = 'whole file'
    endif
    
    " set up syntax highlighting                                       {{{3
    call s:SetupSyntax()
    setlocal modifiable

    " set column of parameter                                          {{{3
    let s:colPara = 14
    
    " delete existing content                                          {{{3
    %delete
    
    " create buffer content                                            {{{3
    let l:lnNr = 0
    let l:txt  = ''
    let l:txt  .= "\"   PRINTER DIALOG\n"
    let l:lnNr += 1
    let l:txt  .= "\"   p: start printing, q: cancel,\n"
    let l:lnNr += 1
    let l:txt  .= "\"   Tab/S-Tab: toggle to next/previous,\n"
    let l:lnNr += 1
    let l:txt  .= "\"   ?: help on parameter,\n"
    let l:lnNr += 1
    let l:txt  .= "\"   :help printer-dialog for detailed help\n"
    let l:lnNr += 1
    let l:txt  .= "\n"
    let l:lnNr += 1
    let l:txt  .= ">File-Info:\n"
    let l:lnNr += 1
    let l:txt  .= '   Name:      ' . l:strFilename . "\n"
    let l:lnNr += 1
    let l:txt  .= '   Range:     ' . l:strRange    . "\n"
    let l:lnNr += 1
    let l:txt  .= "\n"
    let l:lnNr += 1
    let l:txt  .= '>Printer:    <' 
                \ . s:GetElementOutOfList(g:prd_prtDeviceList,
                \ g:prd_prtDeviceIdx) . '>\n'
    let l:lnNr += 1
    let s:lnPrtDev = l:lnNr
    let l:txt  .= "\n"
    let l:lnNr += 1
    let l:txt  .= ">Options:\n"
    let l:lnNr += 1
    let l:txt  .= '   Font:     <' 
                \ . s:GetElementOutOfList(g:prd_fontList, g:prd_fontIdx)
                \ . ">\n"
    let l:lnNr += 1
    let s:lnFont = l:lnNr
    let l:txt  .= '   Paper:    <'
                \ . s:GetElementOutOfList(g:prd_paperList, g:prd_paperIdx)
                \ . ">\n"
    let l:lnNr += 1
    let s:lnPaper = l:lnNr
    let l:txt  .= '   Portrait: <' 
                \ . s:GetElementOutOfList(g:prd_portraitList,
                \ g:prd_portraitIdx) . ">\n"
    let l:lnNr += 1
    let s:lnPortrait = l:lnNr
    let l:txt  .= "\n"
    let l:lnNr += 1
    let l:txt  .= '   Header:   <' 
                \ . s:GetElementOutOfList(g:prd_headerList, 
                \ g:prd_headerIdx) . ">\n"
    let l:lnNr += 1
    let s:lnHeader = l:lnNr
    let l:txt  .= '   Line-Nr:  <' 
                \ . s:GetElementOutOfList(g:prd_lineNrList,
                \ g:prd_lineNrIdx) . ">\n"
    let l:lnNr += 1
    let s:lnLineNr = l:lnNr
    let l:txt  .= '   Syntax:   <' 
                \ . s:GetElementOutOfList(g:prd_syntaxList, 
                \ g:prd_syntaxIdx) . ">\n"
    let l:lnNr += 1
    let s:lnSyntax = l:lnNr
    let l:txt  .= "\n"
    let l:lnNr += 1
    let l:txt  .= '   Wrap:     <' 
                \ . s:GetElementOutOfList(g:prd_wrapList, g:prd_wrapIdx) 
                \ . ">\n"
    let l:lnNr += 1
    let s:lnWrap = l:lnNr
    let l:txt  .= '   Duplex:   <' 
                \ . s:GetElementOutOfList(g:prd_duplexList, 
                \ g:prd_duplexIdx) . ">\n"
    let l:lnNr += 1
    let s:lnDuplex = l:lnNr
    let l:txt  .= '   Collate:  <' 
                \ . s:GetElementOutOfList(g:prd_collateList, 
                \ g:prd_collateIdx) . ">\n"
    let l:lnNr += 1
    let s:lnCollate = l:lnNr
    let l:txt  .= '   JobSplit: <' 
                \ . s:GetElementOutOfList(g:prd_jobSplitList, 
                \ g:prd_jobSplitIdx) . ">\n"
    let l:lnNr += 1
    let s:lnJobSplit = l:lnNr
    let l:txt  .= "\n"
    let l:lnNr += 1
    let l:txt  .= '   Left:     <' 
                \ . s:GetElementOutOfList(g:prd_leftList, g:prd_leftIdx) 
                \ . ">\n"
    let l:lnNr += 1
    let s:lnLeft = l:lnNr
    let l:txt  .= '   Right:    <' 
                \ . s:GetElementOutOfList(g:prd_rightList, g:prd_rightIdx) 
                \ . ">\n"
    let l:lnNr += 1
    let s:lnRight = l:lnNr
    let l:txt  .= '   Top:      <' 
                \ . s:GetElementOutOfList(g:prd_topList, g:prd_topIdx) 
                \ . ">\n"
    let l:lnNr += 1
    let s:lnTop = l:lnNr
    let l:txt  .= '   Bottom:   <' 
                \ . s:GetElementOutOfList(g:prd_bottomList, 
                \ g:prd_bottomIdx) . ">\n"
    let l:lnNr += 1
    let s:lnBottom = l:lnNr
    let l:txt  .= "\n"
    let l:lnNr += 1
    let l:txt  .= '   Dialog:   <' 
                \ . s:GetElementOutOfList(g:prd_dialogList, 
                \ g:prd_dialogIdx) . ">\n"
    let l:lnNr += 1
    let s:lnDialog = l:lnNr
    
    " write content to buffer                                          {{{3
    put! = l:txt
    setlocal nomodifiable                                            " }}}3

endfunction                                                          " }}}2

" s:SetupSyntax()                                                      {{{2
" intent: set syntax highlighting for user interface
" params: nil
" prints: nil
" return: n/a
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

endfunction                                                          " }}}2

" s:SetLocalKeyMappings()                                              {{{2
" intent: set local, temporary key-mappings for this buffer only          
" params: nil
" prints: nil
" return: n/a
function s:SetLocalKeyMappings()
    
    nnoremap <buffer> <silent> q       :call <SID>PRD_Exit()<cr>
    nnoremap <buffer> <silent> p       :call <SID>PRD_StartPrinting()<cr>
    nnoremap <buffer> <silent> <Tab>   :call <SID>PRD_ToggleParameter(1)<cr>
    nnoremap <buffer> <silent> <S-Tab> :call <SID>PRD_ToggleParameter(-1)<cr>
    nnoremap <buffer> <silent> ?       :call <SID>PRD_ShowHelpOnParameter()<cr>

endfunction                                                          " }}}2

" s:GetElementOutOfList(strList, nIdx)                                 {{{2
" intent: return n-th element of string list
" params: strList - element list (delimiter = s:chrDelimiter)
"         nIdx    - list element to extract
" prints: nil
" return: string (element), '' if empty list or non-existent index
" vars:   uses script variable:
"         - s:chrDelimiter
function s:GetElementOutOfList(strList, nIdx)

    " set variables                                                    {{{3
    let l:idx      = 1  " loop variable
    let l:posStart = 0  " position where target element starts
    let l:posEnd   = 0  " position where target element ends
    
    " find start of target element                                     {{{3
    while (l:idx < a:nIdx)
        let l:posMatch = match(a:strList, s:chrDelimiter, l:posStart)
        if (l:posMatch < 0)  " if no delimiter found then only one element
            break
        endif
        let l:posStart = l:posMatch + 1
        let l:idx += 1
    endwhile
    
    " find end of element                                              {{{3
    let l:posEnd = match(a:strList, s:chrDelimiter, l:posStart)
    if (l:posEnd >= 0)  " are there further elements in list?
       " if so, then end of element is position of delimiter - 1
        let l:posEnd = l:posEnd - 1
    else
        " if not, then ends at end of list
        let l:posEnd = strlen(a:strList) - 1
    endif

    " extract target element and return it                             {{{3
    let l:element = strpart(a:strList, l:posStart, 
                \ l:posEnd - l:posStart + 1)  
    return l:element                                                 " }}}3

endfunction                                                          " }}}2

" s:GetNumberOfListElements()                                          {{{2
" intent: get number of choices for each print options
" params: nil
" prints: nil
" return: n/a
" vars:   sets script variables:
"         - s:prtDeviceMaxIdx, s:fontMaxIdx,     s:paperMaxIdx,
"           s:portraitMaxIdx,  s:headerMaxIdx,   s:lineNrMaxIdx,
"           s:syntaxMaxIdx,    s:wrapMaxIdx,     s:duplexMaxIdx,
"           s:collateMaxIdx,   s:jobSplitMaxIdx, s:leftMaxIdx,
"           s:rightMaxIdx,     s:topMaxIdx,      s:bottomMaxIdx,
"           s:dialogMaxIdx
function s:GetNumberOfListElements()
    
    let s:prtDeviceMaxIdx = s:GetMaxIdxOfList(g:prd_prtDeviceList)
    let s:fontMaxIdx      = s:GetMaxIdxOfList(g:prd_fontList)
    let s:paperMaxIdx     = s:GetMaxIdxOfList(g:prd_paperList)
    let s:portraitMaxIdx  = s:GetMaxIdxOfList(g:prd_portraitList)
    let s:headerMaxIdx    = s:GetMaxIdxOfList(g:prd_headerList)
    let s:lineNrMaxIdx    = s:GetMaxIdxOfList(g:prd_lineNrList)
    let s:syntaxMaxIdx    = s:GetMaxIdxOfList(g:prd_syntaxList)
    let s:wrapMaxIdx      = s:GetMaxIdxOfList(g:prd_wrapList)
    let s:duplexMaxIdx    = s:GetMaxIdxOfList(g:prd_duplexList)
    let s:collateMaxIdx   = s:GetMaxIdxOfList(g:prd_collateList)
    let s:jobSplitMaxIdx  = s:GetMaxIdxOfList(g:prd_jobSplitList)
    let s:leftMaxIdx      = s:GetMaxIdxOfList(g:prd_leftList)
    let s:rightMaxIdx     = s:GetMaxIdxOfList(g:prd_rightList)
    let s:topMaxIdx       = s:GetMaxIdxOfList(g:prd_topList)
    let s:bottomMaxIdx    = s:GetMaxIdxOfList(g:prd_bottomList)
    let s:dialogMaxIdx    = s:GetMaxIdxOfList(g:prd_dialogList)

endfunction                                                          " }}}2

" s:GetMaxIdxOfList(strList)                                           {{{2
" intent: get number of elements in string list
" params: strList - list of choices [string]
" prints: nil
" return: integer (element count), minimum value = 1
" vars:   uses script variable:
"         - s:chrDelimiter
function s:GetMaxIdxOfList(strList)

    " set variables                                                    {{{3
    let l:numOfElements = 1  " always have at least one element
    let l:pos = 0
    
    " loop through string searching for delimiters                     {{{3
    while 1
        let l:pos = match(a:strList, s:chrDelimiter, l:pos)
        if (l:pos >= 0)  " if delimiter found, then have new element
            let l:numOfElements += 1
        else
            break  " if no further delimiters, then finished
        endif
        let l:pos += 1  " start searching again from char after delimiter
    endwhile
    
    " return result                                                    {{{3
    return l:numOfElements                                           " }}}3

endfunction                                                          " }}}2

" s:SetPrintdevice()                                                   {{{2
" intent: set 'printdevice' according to user selection
" params: nil
" prints: nil
" return: n/a
" note:   if no uset setting, set to 'standard'
function s:SetPrintdevice()

    let l:element = s:GetElementOutOfList(g:prd_prtDeviceList,
                \ g:prd_prtDeviceIdx)
    if (tolower(l:element) ==# 'standard')
        let &printdevice = ''
    else
        let &printdevice = l:element
    endif

endfunction                                                          " }}}2

" s:SetPrintoptions()                                                  {{{2
" intent: set 'printoptions' according to user selection
" params: nil
" prints: nil
" return: n/a
function s:SetPrintoptions()

    let l:opts = ''

    " margins                                                          {{{3
    let l:opts .= ',left:' 
                \ . s:GetElementOutOfList(g:prd_leftList,
                \                         g:prd_leftIdx)
    let l:opts .= ',right:'
                \ . s:GetElementOutOfList(g:prd_rightList,
                \                         g:prd_rightIdx)
    let l:opts .= ',top:'
                \ . s:GetElementOutOfList(g:prd_topList,
                \                         g:prd_topIdx)
    let l:opts .= ',bottom:'
                \ . s:GetElementOutOfList(g:prd_bottomList,
                \                         g:prd_bottomIdx)           " }}}3
    
    " header                                                           {{{3
    let l:opts .= ',header:' 
                \ . s:GetElementOutOfList(g:prd_headerList,
                \                         g:prd_headerIdx)           " }}}3
    
    " duplex                                                           {{{3
    let l:opts .= ',duplex:'
                \ . s:GetElementOutOfList(g:prd_duplexList,
                \                         g:prd_duplexIdx)           " }}}3
    
    " paper size                                                       {{{3
    let l:opts .= ',paper:'
                \ . s:GetElementOutOfList(g:prd_paperList,
                \                         g:prd_paperIdx)            " }}}3
    
    " line numbering                                                   {{{3
    let l:opts .= ',number:'
                \ . strpart(
                \   s:GetElementOutOfList(g:prd_lineNrList,
                \                         g:prd_lineNrIdx),
                \   0, 1)                                            " }}}3
    
    " line wrapping                                                    {{{3
    let l:opts .= ',wrap:'
                \ . strpart(
                \   s:GetElementOutOfList(g:prd_wrapList,
                \                         g:prd_wrapIdx),
                \   0, 1)                                            " }}}3
    
    " collate                                                          {{{3
    let l:opts .= ',collate:'
                \ . strpart(
                \   s:GetElementOutOfList(g:prd_collateList,
                \                         g:prd_collateIdx),
                \   0, 1)                                            " }}}3
    
    " split copies into individual print jobs                          {{{3
    let l:opts .= ',jobSplit:'
                \ . strpart(
                \   s:GetElementOutOfList(g:prd_jobSplitList,
                \                         g:prd_jobSplitIdx),
                \   0, 1)                                            " }}}3
    
    " orientation                                                      {{{3
    let l:opts .= ',portrait:'
                \ . strpart(
                \   s:GetElementOutOfList(g:prd_portraitList,
                \                         g:prd_portraitIdx),
                \   0, 1)                                            " }}}3
    
    " syntax highlighting                                              {{{3
    if has('syntax')
        if (s:GetElementOutOfList(g:prd_syntaxList,
                    \             g:prd_syntaxIdx)
                    \ ==? 'no')
            let l:opts .= ',syntax:n'
        else
            let l:opts .= ',syntax:y'
        endif
    endif                                                            " }}}3
    
    " set &printoptions                                                {{{3
    let l:opts = strpart(l:opts, 1)
    let &printoptions = l:opts                                       " }}}3

endfunction                                                          " }}}2

" s:SetPrintfont()                                                     {{{2
" intent: set 'printfont' from user selection
" params: nil
" prints: nil
" return: n/a
function s:SetPrintfont()

    let &printfont = s:GetElementOutOfList(g:prd_fontList, g:prd_fontIdx)

endfunction                                                          " }}}2

" s:SetPrintheader()                                                   {{{2
" intent: set 'printheader' from user selection
" params: nil
" prints: nil
" return: n/a
function s:SetPrintheader()

    let &printheader = g:prd_printheader

endfunction                                                          " }}}2

" s:SetColorschemeForPrinting()                                        {{{2
" intent: set colorscheme from user selection
" params: nil
" prints: nil
" return: n/a
" vars:   sets script variable:
"         - s:flagColorschemeDone
" note:   user choices can be 'no', 'current' or a colorscheme name:
"         'no'        - do not use syntax highlighting for printing
"         'current'   - use current syntax highlighting for printing
"         colorscheme - use named colorscheme syntax highlighting for
"                       printing
"                     - the actual colorscheme in use for document
"                       does not change
" TODO:   check whether this logic is properly implemented in function
"         - options 'no' and 'current' do not appear to be implemented
function s:SetColorschemeForPrinting()

    let s:flagColorschemeDone = 0
    if !has('syntax') | return | endif
    let l:element = tolower(s:GetElementOutOfList(g:prd_syntaxList,
                \                                 g:prd_syntaxIdx)) 
    if l:element !~# '^no$\|^current$'
        let s:flagColorschemeDone = 1
        execute 'colorscheme' l:element 
    endif

endfunction                                                          " }}}2

" s:BackupSettings()                                                   {{{2
" intent: backup printer and colorscheme settings
" params: nil
" prints: nil
" return: n/a
" vars:   set script variables:
"         - s:backupPrintdevice, s:backupPrintoptions, s:backupPrintfont
"           s:backupPrintheader, s:backupColorscheme
function s:BackupSettings()

    let s:backupPrintdevice  = &printdevice
    let s:backupPrintoptions = &printoptions
    let s:backupPrintfont    = &printfont
    let s:backupPrintheader  = &printheader
    if has('syntax')
        if exists('g:colors_name')
            let s:backupColorscheme = g:colors_name
        else
            let s:backupColorscheme = 'default'
        endif
    endif

endfunction                                                          " }}}2

" s:RestoreSettings()                                                  {{{2
" intent: restore printer and colorscheme settings
" params: nil
" prints: nil
" return: n/a
" vars:   uses script variables:
"         - s:backupPrintdevice, s:backupPrintoptions, s:backupPrintfont
"           s:backupPrintheader, s:backupColorscheme,
"           s:flagColorschemeDone
function s:RestoreSettings()

    let &printdevice  = s:backupPrintdevice
    let &printoptions = s:backupPrintoptions
    let &printfont    = s:backupPrintfont
    let &printheader  = s:backupPrintheader
    if has('syntax') && s:flagColorschemeDone == 1
        execute 'colorscheme' s:backupColorscheme
    endif

endfunction                                                          " }}}2

" <SID>PRD_Exit()                                                      {{{2
" intent: exit script and close user interface buffer if present
" params: nil
" prints: nil
" return: n/a
" vars:   uses script variable:
"         - s:bufferSrc
function <SID>PRD_Exit()

    execute 'buffer' s:bufferSrc

endfunction                                                          " }}}2

" <SID>PRD_ToggleParameter(step)                                       {{{2
" intent: toggle parameter under cursor to next or previous value
" params: step - direction to increment (1=next, -1=previous)
" prints: nil
" return: n/a
" vars:   uses script variable:
"         - s:colPara
function <SID>PRD_ToggleParameter(step)

    let l:lineNr  = line('.')
    let l:element = ''

    " adjust index of appropriate option, handling wrap around
    " then extract new option value:
    " - print device                                                   {{{3
    if     (l:lineNr == s:lnPrtDev)
        let g:prd_prtDeviceIdx = g:prd_prtDeviceIdx + a:step 
        if (g:prd_prtDeviceIdx > s:prtDeviceMaxIdx)
            let g:prd_prtDeviceIdx = 1
        elseif (g:prd_prtDeviceIdx < 1)
            let g:prd_prtDeviceIdx = s:prtDeviceMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_prtDeviceList,
                    \                         g:prd_prtDeviceIdx)

    " - font                                                           {{{3
    elseif (l:lineNr == s:lnFont)
        let g:prd_fontIdx = g:prd_fontIdx + a:step 
        if (g:prd_fontIdx > s:fontMaxIdx)
            let g:prd_fontIdx = 1
        elseif (g:prd_fontIdx < 1)
            let g:prd_fontIdx = s:fontMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_fontList,
                    \                         g:prd_fontIdx)

    " - paper size                                                     {{{3
    elseif (l:lineNr == s:lnPaper)
        let g:prd_paperIdx = g:prd_paperIdx + a:step 
        if (g:prd_paperIdx > s:paperMaxIdx)
            let g:prd_paperIdx = 1
        elseif (g:prd_paperIdx < 1)
            let g:prd_paperIdx = s:paperMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_paperList,
                    \                         g:prd_paperIdx)
    
    " - orientation                                                    {{{3
    elseif (l:lineNr == s:lnPortrait)
        let g:prd_portraitIdx = g:prd_portraitIdx + a:step 
        if (g:prd_portraitIdx > s:portraitMaxIdx)
            let g:prd_portraitIdx = 1
        elseif (g:prd_portraitIdx < 1)
            let g:prd_portraitIdx = s:portraitMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_portraitList,
                    \                         g:prd_portraitIdx)
    
    " - header size                                                    {{{3
    elseif (l:lineNr == s:lnHeader)
        let g:prd_headerIdx = g:prd_headerIdx + a:step 
        if (g:prd_headerIdx > s:headerMaxIdx)
            let g:prd_headerIdx = 1
        elseif (g:prd_headerIdx < 1)
            let g:prd_headerIdx = s:headerMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_headerList,
                    \                         g:prd_headerIdx)
    
    " - line numbering                                                 {{{3
    elseif (l:lineNr == s:lnLineNr)
        let g:prd_lineNrIdx = g:prd_lineNrIdx + a:step 
        if (g:prd_lineNrIdx > s:lineNrMaxIdx)
            let g:prd_lineNrIdx = 1
        elseif (g:prd_lineNrIdx < 1)
            let g:prd_lineNrIdx = s:lineNrMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_lineNrList,
                    \                         g:prd_lineNrIdx)
    
    " - syntax highlighting                                            {{{3
    elseif (l:lineNr == s:lnSyntax)
        let g:prd_syntaxIdx = g:prd_syntaxIdx + a:step 
        if (g:prd_syntaxIdx > s:syntaxMaxIdx)
            let g:prd_syntaxIdx = 1
        elseif (g:prd_syntaxIdx < 1)
            let g:prd_syntaxIdx = s:syntaxMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_syntaxList,
                    \                         g:prd_syntaxIdx)
    
    " - line wrapping                                                  {{{3
    elseif (l:lineNr == s:lnWrap)
        let g:prd_wrapIdx = g:prd_wrapIdx + a:step 
        if (g:prd_wrapIdx > s:wrapMaxIdx)
            let g:prd_wrapIdx = 1
        elseif (g:prd_wrapIdx < 1)
            let g:prd_wrapIdx = s:wrapMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_wrapList,
                    \                         g:prd_wrapIdx)
    
    " - duplex                                                         {{{3
    elseif (l:lineNr == s:lnDuplex)
        let g:prd_duplexIdx = g:prd_duplexIdx + a:step 
        if (g:prd_duplexIdx > s:duplexMaxIdx)
            let g:prd_duplexIdx = 1
        elseif (g:prd_duplexIdx < 1)
            let g:prd_duplexIdx = s:duplexMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_duplexList,
                    \                         g:prd_duplexIdx)
    
    " - collate                                                        {{{3
    elseif (l:lineNr == s:lnCollate)
        let g:prd_collateIdx = g:prd_collateIdx + a:step 
        if (g:prd_collateIdx > s:collateMaxIdx)
            let g:prd_collateIdx = 1
        elseif (g:prd_collateIdx < 1)
            let g:prd_collateIdx = s:collateMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_collateList,
                    \                         g:prd_collateIdx)
    
    " - split copies into separate print jobs                          {{{3
    elseif (l:lineNr == s:lnJobSplit)
        let g:prd_jobSplitIdx = g:prd_jobSplitIdx + a:step 
        if (g:prd_jobSplitIdx > s:jobSplitMaxIdx)
            let g:prd_jobSplitIdx = 1
        elseif (g:prd_jobSplitIdx < 1)
            let g:prd_jobSplitIdx = s:jobSplitMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_jobSplitList,
                    \                         g:prd_jobSplitIdx)
    
    " - margins                                                        {{{3
    elseif (l:lineNr == s:lnLeft)
        let g:prd_leftIdx = g:prd_leftIdx + a:step 
        if (g:prd_leftIdx > s:leftMaxIdx)
            let g:prd_leftIdx = 1
        elseif (g:prd_leftIdx < 1)
            let g:prd_leftIdx = s:leftMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_leftList,
                    \                         g:prd_leftIdx)
    elseif (l:lineNr == s:lnRight)
        let g:prd_rightIdx = g:prd_rightIdx + a:step 
        if (g:prd_rightIdx > s:rightMaxIdx)
            let g:prd_rightIdx = 1
        elseif (g:prd_rightIdx < 1)
            let g:prd_rightIdx = s:rightMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_rightList,
                    \                         g:prd_rightIdx)
    elseif (l:lineNr == s:lnTop)
        let g:prd_topIdx = g:prd_topIdx + a:step 
        if (g:prd_topIdx > s:topMaxIdx)
            let g:prd_topIdx = 1
        elseif (g:prd_topIdx < 1)
            let g:prd_topIdx = s:topMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_topList,
                    \                         g:prd_topIdx)
    elseif (l:lineNr == s:lnBottom)
        let g:prd_bottomIdx = g:prd_bottomIdx + a:step 
        if (g:prd_bottomIdx > s:bottomMaxIdx)
            let g:prd_bottomIdx = 1
        elseif (g:prd_bottomIdx < 1)
            let g:prd_bottomIdx = s:bottomMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_bottomList,
                    \                         g:prd_bottomIdx)       " }}}3
    
    " - display windows print dialog                                   {{{3
    elseif (l:lineNr == s:lnDialog)
        let g:prd_dialogIdx = g:prd_dialogIdx + a:step 
        if (g:prd_dialogIdx > s:dialogMaxIdx)
            let g:prd_dialogIdx = 1
        elseif (g:prd_dialogIdx < 1)
            let g:prd_dialogIdx = s:dialogMaxIdx
        endif
        let l:element = s:GetElementOutOfList(g:prd_dialogList,
                    \                         g:prd_dialogIdx)
    
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
    execute 'normal d$i' . '<' . l:element . '>'
    call cursor(l:lineNr, l:colNr)  " return to previous position
    setlocal nomodifiable

endfunction                                                          " }}}2

" <SID>PRD_ShowHelpOnParameter()                                       {{{2
" intent: how help on parameter under cursor
" params: nil
" prints: nil
" return: n/a
function <SID>PRD_ShowHelpOnParameter()

    let l:lineNr = line('.')
    if     (l:lineNr == s:lnPrtDev)
        echo 'printer device to be used for printing'
    elseif (l:lineNr == s:lnFont)
        echo "font and it's size used for printing"
    elseif (l:lineNr == s:lnPaper)
        echo 'format of paper'
    elseif (l:lineNr == s:lnPortrait)
        echo 'orientation of paper; <yes> portrait, <no> landscape'
    elseif (l:lineNr == s:lnHeader)
        echo 'number of lines for header; <0> no header'
    elseif (l:lineNr == s:lnLineNr)
        echo 'print line-numbers'
    elseif (l:lineNr == s:lnSyntax)
        echo 'use syntax-highlighting; <no> off, else use colorscheme'
    elseif (l:lineNr == s:lnWrap)
        echo '<yes> wrap long lines, <no> truncate long lines'
    elseif (l:lineNr == s:lnDuplex)
        echo '<off> print on one side, <long>/<short> print on both sides'
    elseif (l:lineNr == s:lnCollate)
        echo '<yes> collating 123, 123, 123, '
                    \ . '<no> no collating 111, 222, 333'
    elseif (l:lineNr == s:lnJobSplit)
        echo '<yes> each copy separate job, <no> all copies one job'
    elseif (l:lineNr == s:lnLeft)
        echo 'left margin'
    elseif (l:lineNr == s:lnRight)
        echo 'right margin'
    elseif (l:lineNr == s:lnTop)
        echo 'top margin'
    elseif (l:lineNr == s:lnBottom)
        echo 'bottom margin'
    elseif (l:lineNr == s:lnDialog)
        echo 'MS-Windows only: show printer dialog'
    else
        echo 'to get help move cursor on parameter'
    endif

endfunction                                                          " }}}2

" <SID>PRD_StartPrinting()                                             {{{2
" intent: start printing
" params: nil
" prints: nil
" return: boolean (success)
" vars:   uses script variables:
"         - s:bufferSrc
"         - s:bufferUser
"         - s:startLine
"         - s:endLine
function <SID>PRD_StartPrinting()

    " ensure buffer to be printed still exists                         {{{3
    if !bufexists(s:bufferSrc)
        execute 'dbuffer' s:bufferUser
        echo s:scriptName.': buffer to be printed does not exist'
        return
    endif
    
    " switch to buffer to be printed                                   {{{3
    " - this automatically deleted the current dialog buffer
    execute 'buffer' s:bufferSrc
                                                                     " }}}3
    " backup vim print and colorscheme settings
    call s:BackupSettings()
    
    " set arguments for ':hardcopy'                                    {{{3
    call s:SetPrintdevice()             " printdevice
    call s:SetPrintoptions()            " printoptions 
    call s:SetPrintfont()               " printfont
    call s:SetPrintheader()             " printheader
    call s:SetColorschemeForPrinting()  " syntax colorscheme
    
    " construct print command                                          {{{3
    let l:cmdStr = s:startLine . ',' . s:endLine . 'hardcopy'
    let l:show_win_dialog = tolower(s:GetElementOutOfList(g:prd_dialogList,
                \                                         g:prd_dialogIdx))
    if l:show_win_dialog ==# 'no'
        let l:cmdStr .= '!'  
    endif

    " execute print command                                            {{{3
    execute l:cmdStr
    
    " restore vim print and colorscheme settings                       {{{3
    call s:RestoreSettings()
    
    " signal success                                                   {{{3
    return 1                                                         " }}}3

endfunction                                                          " }}}2
                                                                     " }}}1

" vim: fdm=marker :
