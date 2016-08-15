" Name:      prtdialog.vim - simplifies printing of text
" Type:      global vim plugin
" Credits:   original author: Christian Habermann
"                             <christian (at) habermann-net (point) de>
"            forked by:       David Nebauer
"                             <david (at) nebauer (point) org>
" Copyright: (c) 2016 by David Nebauer
" Purpose:   Provide a dialog to configure printer settings printing.
"            To invoke this dialog, use command :PrintDialog.
"            For futher informations do |:help prtdialog|

" TODO: use autoload

" SETTINGS:                                                            {{{1

" load once                                                            {{{2
if exists('g:loaded_prtdialog') | finish | endif
let g:loaded_prtdialog = 1

" save 'cpoptions'                                                     {{{2
let s:save_cpoptions = &cpoptions
set cpoptions&vim


" INTERFACE:                                                           {{{1

" command (:PrintDialog)                                               {{{2
command -range=% PrintDialog
            \ call s:StartPrinterDialog(<line1>, <line2>)


" INITIALISATION:                                                      {{{1

" used to print/echo name of script                                    {{{2
let s:scriptName = 'PrtDialog'

" default 'printexpr' (obtained from |:help pexpr-option|)             {{{2
let s:defaultPrintexpr = "system('lpr' . (&printdevice == '' ? '' "
            \ . ": ' -P' . &printdevice) . ' ' . v:fname_in) . "
            \ . 'delete(v:fname_in) + v:shell_error'

" default fonts                                                        {{{2
" - 'list of lists': the first font found in each sublist is used
    let s:default_fonts = [
                \ ['6x13'],
                \ ['Andale Mono'],
                \ ['Anonymice Powerline',
                \  'AnonymicePowerline Nerd Font',
                \  'Anonymous Pro for Powerline', 'Anonymous Pro'],
                \ ['BitStreamVeraSansMono Nerd Font',
                \  'Bitstream Vera Sans Mono'],
                \ ['Powerline Consolas', 'Consolas'],
                \ ['Courier'],
                \ ['Courier New'],
                \ ['DeJaVu Sans Mono for Powerline',
                \  'DejaVuSansMonoForPowerline Nerd Font',
                \  'DejaVu Sans Mono'],
                \ ['Droid Sans Mono for Powerline',
                \  'DroidSansMonoForPowerline Nerd Font',
                \  'Droid Sans Mono'],
                \ ['Fira Mono for Powerline',
                \  'Fira Mono Medium for Powerline',
                \  'Fira Mono'],
                \ ['Fixed', 'Fixedsys'],
                \ ['Hack'],
                \ ['Inconsolata for Powerline',
                \  'InconsolataForPowerline Nerd Font',
                \  'Inconsolata'],
                \ ['Inconsolata-g for Powerline',
                \  'Inconsolata g'],
                \ ['Letter Gothic Std'],
                \ ['Literation Mono Powerline',
                \  'Liberation Mono for Powerline',
                \  'LiterationMonoPowerline Nerd Font',
                \  'Liberation Mono'],
                \ ['Lucida Console'],
                \ ['Lucida Sans Typewriter'],
                \ ['Monaco'],
                \ ['Mplus Nerd Font', 'M+ 1m Medium', 'M+ 1m'],
                \ ['Menlo for Powerline',
                \  'Menlo'],
                \ ['Meslo LG M for Powerline',
                \  'MesloLGM Nerd Font',
                \  'Meslo LG'],
                \ ['monofur for Powerline',
                \  'MonofurForPowerline Nerd Font', 'Monofur'],
                \ ['Monoid for Powerline',
                \  'Monoid Nerd Font',
                \  'Monoid'],
                \ ['Monospace',
                \  'GWMonospace'],
                \ ['OCR A Extended', 'OCR A Std'],
                \ ['Orator Std'],
                \ ['Prestige Elite Pro'],
                \ ['Oxygen Mono'],
                \ ['ProFontWindows Nerd Font'],
                \ ['Roboto Mono for Powerline',
                \  'Roboto Mono Medium for Powerline',
                \  'Robotomono Nerd Font', 'RobotoRegular',
                \  'Roboto Mono'],
                \ ['Sans'],
                \ ['Sauce Code Powerline',
                \  'SauceCodePro Nerd Font',
                \  'Source Code Pro Medium', 'Source Code Pro'],
                \ ['Terminus'],
                \ ['Ubuntu Mono derivative Powerline',
                \  'UbuntuMonoDerivativePowerline Nerd Font',
                \  'UbuntuMono Nerd Font',
                \  'Ubuntu Mono'],
                \ ]

" print settings                                                       {{{2
" - device, font, syntax and margins are
"   loaded dynamically on invocation
" TODO: reimplement fontsize
let s:settings = {
            \ 'device': {
            \   'options': [],
            \   'current': 'default',
            \   'help'   : 'printer device to be used for printing',
            \   },
            \ 'font': {
            \   'options': [],
            \   'current': 'courier',
            \   'help'   : 'font used for printing',
            \   },
            \ 'paper': {
            \   'options': ['10x14', 'A3', 'A4', 'A5', 'B4', 'B5',
            \               'executive', 'folio', 'ledger', 'legal',
            \               'letter', 'quarto', 'statement', 'tabloid'],
            \   'current': 'A4',
            \   'help'   : 'format of paper',
            \   },
            \ 'orientation': {
            \   'options': ['portrait', 'landscape'],
            \   'current': 'portrait',
            \   'help'   : 'orientation of paper: '
            \            . '<portrait>, <landscape>',
            \   },
            \ 'header': {
            \   'options': [0, 1, 2, 3, 4, 5, 6],
            \   'current': 2,
            \   'help'   : 'number of lines for header: <0> no header',
            \   },
            \ 'number': {
            \   'options': ['yes', 'no'],
            \   'current': 'no',
            \   'help'   : 'print line numbers',
            \   },
            \ 'syntax': {
            \   'options': [],
            \   'current': 'default',
            \   'help'   : 'use syntax-highlighting: <no> off, '
            \            . 'else use colorscheme',
            \   },
            \ 'wrap': {
            \   'options': ['yes', 'no'],
            \   'current': 'yes',
            \   'help'   : '<yes> wrap long lines, '
            \            . '<no> truncate long lines',
            \   },
            \ 'duplex': {
            \   'options': ['off', 'long', 'short'],
            \   'current': 'long',
            \   'help'   : '<off> print on one side, '
            \            . '<long>/<short> print on both sides',
            \   },
            \ 'collate': {
            \   'options': ['yes', 'no'],
            \   'current': 'yes',
            \   'help'   : '<yes> collating 123, 123, 123, '
            \            . '<no> no collating 111, 222, 333',
            \   },
            \ 'jobsplit': {
            \   'options': ['yes', 'no'],
            \   'current': 'no',
            \   'help'   : '<yes> each copy separate job, '
            \            . '<no> all copies one job',
            \   },
            \ 'left': {
            \   'options': [],
            \   'current': '15mm',
            \   'help'   : 'left margin, <xu> x is number, '
            \            . 'u is units (in, pt, mm, pc)',
            \   },
            \ 'right': {
            \   'options': [],
            \   'current': '15mm',
            \   'help'   : 'right margin, <xu> x is number, '
            \            . 'u is units (in, pt, mm, pc)',
            \   },
            \ 'top': {
            \   'options': [],
            \   'current': '10mm',
            \   'help'   : 'top margin, <xu> x is number, '
            \            . 'u is units (in, pt, mm, pc)',
            \   },
            \ 'bottom': {
            \   'options': [],
            \   'current': '10mm',
            \   'help'   : 'bottom margin, <xu> x is number, '
            \            . 'u is units (in, pt, mm, pc)',
            \   },
            \ 'dialog': {
            \   'options': ['yes', 'no'],
            \   'current': 'no',
            \   'help'   : 'MS-Windows only: show printer dialog',
            \   },
            \ }
" - apply user defaults
"   . except device, font and margins, which are set each time
"     the print dialog is invoked
for s:setting in keys(s:settings)
    if s:setting =~# '^device$\|^font$'
        continue
    endif
    if s:setting =~# '^left$\|^right$\|^top$\|^bottom$'
        continue
    endif
    let s:var = 'g:prd_' . s:setting . '_default'
    if !exists(s:var) | continue | endif
    if count(s:settings[s:setting].options, g:prd_{s:setting}_default)
        let s:settings[s:setting].current = g:prd_{s:setting}_default
    else
        echoerr 'Invalid ' . s:var . " value '"
                    \ . g:prd_{s:setting}_default . "'"
        echoerr '-- must be one of: '
                    \ . join(s:settings[s:setting].options, ', ')
    endif
endfor
unlet s:setting s:var


" FUNCTIONS:                                                           {{{1

" s:StartPrinterDialog(start, end)                                     {{{2
"  intent: get range to be printed and buffer, then start user interface
"  params: start - beginning of range to print [integer]
"          end   - end of range to print [integer]
"  insert: nil
"  return: n/a
function s:StartPrinterDialog(start, end)

    " check that vim is compiled with print option                     {{{3
    if !has('printer')  " is this vim compiled with printing enabled?
        echo s:scriptName
                    \ . ': this version of vim does not support printing'
        return
    endif

    " get range to be printed                                          {{{3
    let s:range = {'start': a:start, 'end': a:end}

    " remember line count                                              {{{3
    let s:end = line('.')

    " create buffer to be printed                                      {{{3
    let s:buffer = {}
    let s:buffer.user = -1
    let s:buffer.src  = winbufnr(0)

    " set up user interface                                            {{{3
    if s:OpenNewBuffer()  " buffer for user-interface
        call s:PrepareDialog()        " show the dialog
        call s:SetLocalKeyMappings()  " set keys for user (local to buffer)
    endif                                                            " }}}3

endfunction

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

" s:PrepareDialog()                                                    {{{2
"  intent: redraw print dialog
"  params: nil
"  insert: buffer content
"  return: n/a
function s:PrepareDialog()

    " get name of print dialog buffer                                  {{{3
    let l:filename = bufname(s:buffer.src)
    if l:filename ==# ''
        let l:filename = '[noname]'
    endif

    " get range of buffer to be printed                                {{{3
    let l:range = (s:range.start == 1 && s:range.end == s:end)
                \ ? 'whole file'
                \ : 'lines ' . s:range.start . ' - ' . s:range.end

    " set up syntax highlighting                                       {{{3
    call s:SetupSyntax()

    " update settings that may have changed since last print           {{{3
    call s:UpdateEnvironmentalSettings()
    call s:UpdatePrintSettingOptionsDevice()
    call s:UpdatePrintSettingOptionsFont()
    call s:UpdatePrintSettingOptionsSyntax()
    call s:UpdatePrintSettingOptionsMargins()

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
    if s:method ==# 'vim'
        call add(l:c, 'Printing using default vim print mechanism')
    else
        call add(l:c, 'Printing via html2vim and wkhtmltopdf')
    endif
    call add(l:c, '')
    call add(l:c, '>File-Info:')
    call add(l:c, '   Name:      ' . l:filename)
    call add(l:c, '   Range:     ' . l:range)
    call add(l:c, '')
    call add(l:c, '>Printer:    <'
                \ . s:settings.device.current
                \ . '>')
    let s:optLine[len(l:c)] = 'device'
    let s:settings.device.bufline = len(l:c)
    call add(l:c, '')
    call add(l:c, '>Options:')
    call add(l:c, '   Font:     <'
                \ . s:settings.font.current
                \ . '>')
    let s:optLine[len(l:c)] = 'font'
    call add(l:c, '')
    call add(l:c, '   Paper:    <'
                \ . s:settings.paper.current
                \ . '>')
    let s:optLine[len(l:c)] = 'paper'
    call add(l:c, '   Layout:   <'
                \ . s:settings.orientation.current
                \ . '>')
    let s:optLine[len(l:c)] = 'orientation'
    call add(l:c, '')
    call add(l:c, '   Header:   <'
                \ . s:settings.header.current
                \ . '>')
    let s:optLine[len(l:c)] = 'header'
    call add(l:c, '   Line-Nr:  <'
                \ . s:settings.number.current
                \ . '>')
    let s:optLine[len(l:c)] = 'number'
    call add(l:c, '   Syntax:   <'
                \ . s:settings.syntax.current
                \ . '>')
    let s:optLine[len(l:c)] = 'syntax'
    call add(l:c, '')
    call add(l:c, '   Wrap:     <'
                \ . s:settings.wrap.current
                \ . '>')
    let s:optLine[len(l:c)] = 'wrap'
    call add(l:c, '   Duplex:   <'
                \ . s:settings.duplex.current
                \ . '>')
    let s:optLine[len(l:c)] = 'duplex'
    call add(l:c, '   Collate:  <'
                \ . s:settings.collate.current
                \ . '>')
    let s:optLine[len(l:c)] = 'collate'
    call add(l:c, '   JobSplit: <'
                \ . s:settings.jobsplit.current
                \ . '>')
    let s:optLine[len(l:c)] = 'jobsplit'
    call add(l:c, '')
    call add(l:c, '   Left:     <'
                \ . s:settings.left.current
                \ . '>')
    let s:optLine[len(l:c)] = 'left'
    call add(l:c, '   Right:    <'
                \ . s:settings.right.current
                \ . '>')
    let s:optLine[len(l:c)] = 'right'
    call add(l:c, '   Top:      <'
                \ . s:settings.top.current
                \ . '>')
    let s:optLine[len(l:c)] = 'top'
    call add(l:c, '   Bottom:   <'
                \ . s:settings.bottom.current
                \ . '>')
    let s:optLine[len(l:c)] = 'bottom'
    call add(l:c, '')
    call add(l:c, '   Dialog:   <'
                \ . s:settings.dialog.current
                \ . '>')
    let s:optLine[len(l:c)] = 'dialog'

    " write content to buffer                                          {{{3
    let l:txt = join(l:c, "\n")
    setlocal modifiable
    %delete
    put! = l:txt
    setlocal nomodifiable

    " move cursor to first parameter                                   {{{3
    call setpos('.', [0, 1, 1, 0])
    call setpos('.', [0, s:settings.device.bufline, 14, 0])          " }}}3

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
    if !exists('s:defined_interface_syntax')
        let s:defined_interface_syntax = 1
        hi def link prdParameter Special
        hi def link prdHeadline  String
        hi def link prdComment   Comment
    endif                                                            " }}}3

endfunction

" s:UpdateEnvironmentalSettings()                                      {{{2
"  intent: update print method
"  params: nil
"  prints: nil
"  return: n/a
function! s:UpdateEnvironmentalSettings()

    " decide on print method (s:method = ['win'|'fc'|'mac'|'vim'])     {{{3
    let s:method = 'vim'
    if     has('win32') || has('win64')
        if executable('reg') | let s:method = 'win' | endif
    elseif has('macunix')
        if has('python') | let s:method = 'mac' | endif
    elseif has('unix')
        if executable('fc-list') | let s:method = 'fc' | endif
    endif                                                            " }}}3

endfunction

" s:UpdatePrintSettingOptionsDevice()                                  {{{2
"  intent: scan for print devices and add them to standard options
"  params: nil
"  prints: nil
"  return: n/a
"  note:   the 'default' key is not used for the 'device' setting
function! s:UpdatePrintSettingOptionsDevice()

    " reset device list as devices may have been added or removed      {{{3
    let s:settings.device.options = []

    " add default print device                                         {{{3
    call add(s:settings.device.options, 'default')

    " check for utils needed to find print devices                     {{{3
    let l:missing_exes = []
    for l:exe in ['lpstat', 'grep', 'awk']
        if !executable(l:exe)
            call add(l:missing_exes, l:exe)
        endif
    endfor

    " find and add printer devices if utils available                  {{{3
    if empty(l:missing_exes)
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
        call extend(s:settings.device.options, l:print_devices)
    else
        echo "Can't retrieve print device listing -"
        echo '  missing ' .join(l:missing_exes, ', ')
    endif

    " handle user-specified print devices                              {{{3
    if exists('g:prd_device_options')
                \ && type(g:prd_device_options) == type([])
        let l:warn = []
        for l:device in g:prd_device_options
            if count(s:settings.device.options, l:device)
                continue
            endif
            call add(s:settings.device.options, l:device)
            if !count(l:print_devices, l:device)
                call add(l:warn, l:device)
            endif
        endfor
        if !empty(l:warn)
            echo 'Warning: user-specified devices not available'
            echo '-- ' . join(l:warn, ', ')
        endif
    endif
    if exists('g:prd_device_options')
                \ && type(g:prd_device_options) != type([])
        echoerr "Unable to read 'g:prd_device_options' --"
        echoerr 'not a List variable'
    endif
    call uniq(sort(s:settings.device.options))

    " get system default device                                        {{{3
    if empty(l:missing_exes)
        let l:cmd = "lpstat -d | awk '{print $NF}'"
        let l:return_list = systemlist(l:cmd)
        if v:shell_error || len(l:return_list)    != 1
                    \    || len(l:return_list[0]) == 0
            echoerr 'Unable to obtain default print device'
            if len(l:return_list)
                echoerr 'Shell feedback:'
                for l:line in l:return_list
                    echoerr '  ' . l:line
                endfor
            endif
        else
            let l:default = l:return_list[0]
        endif
    endif
    if exists('l:default')
        let s:settings.device.default = l:default
    else
        let l:default = 'default'
    endif

    " prefer previously selected print device if still available       {{{3
    if count(s:settings.device.options, s:settings.device.current)
        let l:default = s:settings.device.current
    endif

    " prefer user default if provided                                  {{{3
    if exists('g:prd_device_default')
        if g:prd_device_default ==? ''
            echoerr "User variable 'g:prd_device_default' is empty"
        else
            if count(s:settings.device.options, g:prd_device_default)
                let l:default = g:prd_device_default
            else
                echoerr "User-specified default device '"
                            \ . g:prd_device_default . "' was not "
                            \ . 'included in the devices list'
            endif
        endif
    endif

    " set initial device option
    let s:settings.device.current = l:default                        " }}}3

endfunction

" s:UpdatePrintSettingOptionsFont()                                    {{{2
"  intent: check for fonts and add them
"  params: nil
"  prints: nil
"  return: n/a
function! s:UpdatePrintSettingOptionsFont()

    " reset font list as fonts may have been added or removed          {{{3
    let s:settings.font.options = []

    " add default system font                                          {{{3
    call add(s:settings.font.options, 'Courier')

    " attempt to add system fonts                                      {{{3
    " - depends on s:method which was set earlier
    let l:system_fonts = {}
    if     s:method ==# 'win'
        let l:system_fonts = s:GetSystemFontsOnWindows()
    elseif s:method ==# 'fc'
        let l:system_fonts = s:GetSystemFontsUsingFC()
    elseif s:method ==# 'mac'
        let l:system_fonts = s:GetSystemFontsOnMac()
        if empty(l:system_fonts)
            let l:system_fonts = s:GetSystemFontsUsingFC()
        endif
    endif

    " add default fonts found on system                                {{{3
    for l:font_group in s:default_fonts
        let l:font = ''
        for l:group_font in l:font_group
            if has_key(l:system_fonts, l:group_font)
                let l:font = l:group_font
                break
            endif
        endfor
        if l:font ==? '' | continue | endif
        if count(s:settings.font.options, l:font, 1) | continue | endif
        call add(s:settings.font.options, l:font)
    endfor

    " if not system fonts found, make sure to use vim print method     {{{3
    if s:method !=# 'vim' && len(s:settings.font.options) == 1
        let s:method = 'vim'
    endif

    " handle user-specified print fonts                                {{{3
    if s:method !=# 'vim'
                \ && exists('g:prd_font_options')
                \ && type(g:prd_font_options) == type([])
        let l:warn = []
        for l:font in g:prd_font_options
            if count(s:settings.font.options, l:font)
                continue
            endif
            call add(s:settings.font.options, l:font)
            if !has_key(l:system_fonts, l:font)
                call add(l:warn, l:font)
            endif
        endfor
        if !empty(l:warn)
            echo 'Warning: user-specified fonts do not appear '
                        \ . 'to be available'
            echo '-- ' . join(l:warn, ', ')
        endif
    endif
    if exists('g:prd_font_options')
                \ && type(g:prd_font_options) != type([])
        echoerr "Unable to read 'g:prd_font_options' --"
        echoerr 'not a List variable'
    endif

    " finished adding fonts, so tidy them                              {{{3
    call uniq(sort(s:settings.font.options))

    " system default font is 'courier'                                 {{{3
    let l:default = 'Courier'

    " prefer previously selected print font if still available         {{{3
    if count(s:settings.font.options, s:settings.font.current)
        let l:default = s:settings.font.current
    endif

    " prefer user default if provided                                  {{{3
    if exists('g:prd_font_default')
        if g:prd_font_default ==? ''
            echoerr "User variable 'g:prd_font_default' is empty"
        else
            if count(s:settings.font.options, g:prd_font_default)
                let l:default = g:prd_font_default
            else
                echoerr "User-specified default font '"
                            \ . g:prd_font_default . "' was not "
                            \ . 'included in the font list'
            endif
        endif
    endif

    " set initial font option                                          {{{3
    let s:settings.font.current = l:default                          " }}}3

endfunction

" s:GetSystemFontsOnWindows()                                          {{{2
"  intent: get MS Windows system fonts
"  params: nil
"  prints: nil
"  return: Dictionary (keys = fonts)
function! s:GetSystemFontsOnWindows()

    " get and tidy registry output                                     {{{3
    let l:output = systemlist('reg query "HKLM\SOFTWARE\Microsoft' .
                \ '\Windows NT\CurrentVersion\Fonts"')

    " - remove registry key at start of output
    unlet l:output[0]

    " - remove blank lines
    call filter(l:output, 'strlen(v:val) > 0')

    " extract font family from each line                               {{{3
    " - all lines begin with leading spaces and can have spaces in the
    "   font family portion
    " - lines have one of the following formats:
    "     Font family REG_SZ FontFilename
    "     Font family (TrueType) REG_SZ FontFilename
    "     Font family 1,2,3 (TrueType) REG_SZ FontFilename
    " - throw away everything before and after the font family
    " - assume that any '(' is not part of the family name
    " - assume digits followed by comma indicates point size
    call map(l:output, 'substitute(l:output,'
                \ . ''' *\(.\{-}\)\ *\((\|\d\+,\|REG_SZ\).\{-}$'', '
                \ . '''\1'', ''g'')')

    " return result                                                    {{{3
    let l:fonts = {}
    for l:font in l:output
        let l:fonts[l:font] = 1
    endfor
    return l:fonts                                                   " }}}3

endfunction

" s:GetSystemFontsUsingFC()                                            {{{2
"  intent: get system fonts using fontconfig
"  params: nil
"  prints: nil
"  return: Dictionary (keys = fonts)
function! s:GetSystemFontsUsingFC()

    " get list of system fonts using 'fc-list'                         {{{3
    if !executable('fc-list') | return [] | endif
    let l:font_list = systemlist("fc-list --format '%{family}\n'")

    " return result as dictionary                                      {{{3
    let l:fonts = {}
    for l:font in l:font_list
        let l:fonts[l:font] = 1
    endfor
    return l:fonts                                                   " }}}3

endfunction

" s:GetSystemFontsOnMac()                                              {{{2
"  intent: use Cocoa font manager to return list of all
"          installed font families on Apple Mac
"  params: nil
"  return: Dictionary (keys = fonts)
"  depend: uses python interface to Apple's cocoa api for Mac
" pyfunc fontdetect_listFontFamiliesUsingCocoa()                       {{{3
"  intent: python function for detecting installed font families
"          using Cocoa
"  params: nil
"  return: List
if has('python')
python << endpython
def fontdetect_listFontFamiliesUsingCocoa():
    try:
        import Cocoa
    except ImportError:
        return []
    manager = Cocoa.NSFontManager.sharedFontManager()
    font_families = list(manager.availableFontFamilies())
    return font_families
endpython
endif                                                                " }}}3
function! s:GetSystemFontsOnMac() abort

    " get list of system fonts using python cocoa                      {{{3
    if !has('python') | return [] | endif
    let l:font_list = pyeval('fontdetect_listFontFamiliesUsingCocoa()')

    " return result as dictionary                                      {{{3
    let l:fonts = {}
    for l:font in l:font_list
        let l:fonts[l:font] = 1
    endfor
    return l:fonts                                                   " }}}3

endfunction

" s:UpdatePrintSettingOptionsSyntax()                                  {{{2
"  intent: check for colorschemes and add them as options
"  params: nil
"  prints: nil
"  return: n/a
function! s:UpdatePrintSettingOptionsSyntax()

    " reset font list as colorschemes may have been added or removed   {{{3
    let s:settings.syntax.options = ['no', 'current', 'default']
    for l:scheme in ['print_bw', 'zellner', 'solarized']
        let l:path = 'colors/' . l:scheme . '.vim'
        if !empty(globpath(&runtimepath, l:path, 1, 1))
            call add(s:settings.syntax.options, l:scheme)
        endif
    endfor

    " handle user-specified colorschemes                               {{{3
    if exists('g:prd_syntax_options')
                \ && type(g:prd_syntax_options) == type([])
        let l:warn = []
        for l:scheme in g:prd_syntax_options
            if count(s:settings.syntax.options, l:scheme)
                continue
            endif
            call add(s:settings.syntax.options, l:scheme)
            let l:path = 'colors/' . l:scheme . '.vim'
            if empty(globpath(&runtimepath, l:path, 1, 1))
                call add(l:warn, l:scheme)
            endif
        endfor
        if !empty(l:warn)
            echoerr 'Warning: user-specified syntax colorschemes '
                        \ 'are not installed on the system'
            echoerr '-- ' . join(l:warn, ', ')
        endif
    endif
    if exists('g:prd_syntax_options')
                \ && type(g:prd_syntax_options) != type([])
        echoerr "Unable to read 'g:prd_syntax_options' --"
        echoerr 'not a List variable'
    endif
    call uniq(sort(s:settings.syntax.options))

    " system default syntax is 'default'                               {{{3
    let l:default = 'default'

    " prefer previously selected colorscheme if still available        {{{3
    if count(s:settings.syntax.options, s:settings.syntax.current)
        let l:default = s:settings.syntax.current
    endif

    " prefer user default if provided and available                    {{{3
    if exists('g:prd_syntax_default')
        if g:prd_syntax_default ==? ''
            echoerr "User variable 'g:prd_syntax_default' is empty"
        else
            if count(s:settings.syntax.options, g:prd_syntax_default)
                let l:default = g:prd_syntax_default
            else
                echoerr "User-specified default syntax colorscheme '"
                            \ . g:prd_syntax_default . "' was not "
                            \ . 'included in the syntax list'
            endif
        endif
    endif

    " set initial syntax option                                        {{{3
    let s:settings.syntax.current = l:default                        " }}}3

endfunction

" s:UpdatePrintSettingOptionsMargins()                                 {{{2
"  intent: check for margin settings and add them
"  params: nil
"  prints: nil
"  return: n/a
function! s:UpdatePrintSettingOptionsMargins()

    " loop through each margin setting in turn
    for l:margin in ['left', 'right', 'top', 'bottom']

        " set default options                                          {{{3
        let s:settings[l:margin].options =
                    \ ['5mm', '10mm', '15mm', '20mm', '25mm']

        " add user specified options                                   {{{3
        let l:var_name = 'g:prd_' . l:margin . '_options'
        if !exists(l:var_name) | continue | endif
        if type(g:prd_{l:margin}_options) != type([])
            echoerr "User variable '" . l:var_name . "' is not a list"
            continue
        endif
        let l:warn = []  " print warnings about invalid options
        for l:option in g:prd{l:margin}_options
            if count(s:settings[l:margin].options, l:option)
                continue
            endif
            let l:valid = 1
            let l:number = substitute(l:option,
                        \             '^\([\.0-9]*\).*', '\1', '')
            " - number part has to be valid integer or decimal
            if type(l:number) != type (0) && type(l:number) != type(0.0)
                let l:valid = 0
            endif
            " - only four units are allowed by vim
            let l:units = substitute(l:option,
                        \            '^[\.0-9]*\(.*\)', '\1', '')
            if l:units !~# '^in$\|^pt$\|^mm$\|^pc$'
                let l:valid = 0
            endif
            call add(s:settings[l:margin].options, l:option)
            if !l:valid | call add(l:warn, l:option) | endif
        endfor
        if !empty(l:warn)
            echoerr 'Warning: invalid user-specified ' . l:margin
                        \ . ' margin values'
            echoerr '-- ' . join(l:warn, ', ')
        endif

        " get default margin                                           {{{3
        let l:default = (l:margin =~# '^left$\|^right$') ? '15mm'
                    \                                    : '10mm'

        " prefer previously selected margin size if still available    {{{3
        if count(s:settings[l:margin].options,
                    \ s:settings[l:margin].current)
            let l:default = s:settings[l:margin].current
        endif

        " prefer user default if provided and available                {{{3
        let l:var_name = 'g:prd_' . l:margin . '_default'
        if exists(l:var_name)
            if g:prd_{l:margin}_default ==? ''
                echoerr "User variable '" . l:var_name "' is empty"
            else
                if count(s:settings[l:margin].options,
                            \ g:prd_{l:margin}_default)
                    let l:default = g:prd_{l:margin}_default
                else
                    echoerr 'Warning: user-specified default '
                                \ . l:margin . " margin '"
                                \ . g:prd_{l:margin}_default
                                \ . "' was not included in the "
                                \ . l:margin . ' margin options list'
                endif
            endif
        endif

        " set initial margin option                                    {{{3
        let s:settings[l:margin].current = l:default                 " }}}3

    endfor

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

" s:SetHardcopyArguments()                                             {{{2
"  intent: set 'printdevice', 'printoptions', 'printfont', 'printheader'
"          and printing colorscheme
"  params: nil
"  insert: nil
"  return: n/a
function s:SetHardcopyArguments()

    " set 'printdevice'                                                {{{3
    if tolower(s:settings.device.current) ==# 'default'
        let &printdevice = ''
    else
        let &printdevice = s:settings.device.current
    endif

    " set 'printoptions'                                               {{{3
    let l:opts = ''

    " - margins                                                        {{{4
    let l:opts .= ',left:'   . s:settings.left.current
    let l:opts .= ',right:'  . s:settings.right.current
    let l:opts .= ',top:'    . s:settings.top.current
    let l:opts .= ',bottom:' . s:settings.bottom.current

    " - header                                                         {{{4
    let l:opts .= ',header:' . s:settings.header.current

    " - duplex                                                         {{{4
    let l:opts .= ',duplex:' . s:settings.duplex.current

    " - paper size                                                     {{{4
    let l:opts .= ',paper:'  . s:settings.paper.current

    " - line numbering                                                 {{{4
    let l:number_options = {'yes': 'y', 'no': 'n'}
    let l:opts .= ',number:' . l:number_options[s:settings.number.current]

    " - line wrapping                                                  {{{4
    let l:wrap_options = {'yes': 'y', 'no': 'n'}
    let l:opts .= ',wrap:'   . l:wrap_options[s:settings.wrap.current]

    " - collate                                                        {{{4
    let l:collate_options = {'yes': 'y', 'no': 'n'}
    let l:opts .= ',collate:'
                \ . l:collate_options[s:settings.collate.current]

    " - split copies into individual print jobs                        {{{4
    let l:jobsplit_options = {'yes': 'y', 'no': 'n'}
    let l:opts .= ',jobSplit:'
                \ . l:jobsplit_options[s:settings.jobsplit.current]

    " - orientation                                                    {{{4
    let l:orientation_options = {'portrait': 'y', 'landscape': 'n'}
    let l:opts .= ',portrait:'
                \ . l:orientation_options[s:settings.orientation.current]

    " - syntax highlighting                                            {{{4
    if has('syntax')
        if s:settings.syntax.current ==? 'no'
            let l:opts .= ',syntax:n'
        else
            let l:opts .= ',syntax:y'
        endif
    endif

    " set &printoptions                                                {{{4
    let l:opts = strpart(l:opts, 1)  " remove leading comma
    let &printoptions = l:opts

    " set 'printfont'                                                  {{{3
    let &printfont = s:settings.font.current

    " set 'printheader'                                                {{{3
    if exists('s:prd_printheader')
        let &printheader = g:prd_printheader
    endif

    " set 'colorscheme'                                                {{{3
    let s:changed_colorscheme = 0
    if !has('syntax') | return | endif
    let l:element = tolower(s:settings.syntax.current)
    if l:element !~# '^no$\|^current$'
        let s:changed_colorscheme = 1
        execute 'colorscheme' l:element
    endif                                                            " }}}3

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
        let s:backup.colorscheme = (exists('g:colors_name'))
                    \ ? g:colors_name
                    \ : 'default'
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
    if has('syntax') && exists('s:changed_colorscheme')
                \ && s:changed_colorscheme == 1
        execute 'colorscheme' s:backup.colorscheme
    endif

endfunction

" s:ChangePrintSettingOption(setting, direction)                       {{{2
"  intent: change current print setting option to next or previous option
"  params: setting   - print setting to change; must be a primary key
"                      of variable 's:settings'
"          direction - direction to jump [+1 = forward, -1 = backwards]
"  insert: nil
"  return: n/a
"  assume: unique items in list; if duplicate items are present in
"          list, the function's behaviour is unpredictable
"  note:   wrap around
function s:ChangePrintSettingOption(setting, direction)

    " check parameters                                                 {{{3
    if !has_key(s:settings, a:setting)
        echoerr "Invalid print setting '" . a:setting . "'"
        return
    endif
    let l:size =  len(s:settings[a:setting].options)
    if l:size == 0
        echoerr "No options defined for print setting '" . a:setting . "'"
        return
    endif
    if type(a:direction) != type(0)
        echoerr 'Jump value (' . string(a:direction) . ') is not an integer'
        return
    endif
    if (abs(a:direction) - 1) != 0
        echoerr "Invalid direction value '" . string(a:direction) . "'"
        return
    endif
    if l:size != len(uniq(sort(copy(s:settings[a:setting].options))))
        echoerr "Duplicate options for print setting '" . a:setting . "'"
        echoerr 'May change option incorrectly'
    endif

    " handle huge jumps                                                {{{3
    let l:direction = a:direction % l:size

    " get index of current item                                        {{{3
    let l:start = index(s:settings[a:setting].options,
                \       s:settings[a:setting].current)
    if l:start == -1
        echoerr "Invalid setting option '"
                    \ . s:settings[a:setting].current . "'"
        return
    endif

    " jump to new item                                                 {{{3
    let l:end = l:start + l:direction

    " handle wrapping                                                  {{{3
    let l:last_index = l:size - 1
    if l:direction > 0 && l:end > l:last_index
        let l:end = l:direction - (l:last_index - l:start) - 1
    endif
    if l:direction < 0 && l:end < 0
        let l:end = l:last_index + l:end + 1
    endif

    " return next value                                                {{{3
    let s:settings[a:setting].current =
                \ s:settings[a:setting].options[l:end]               " }}}3

endfunction

" s:ModifyDialogParameter(line_no, option)                             {{{2
"  intent: modify display buffer parameter
"  params: line_no - buffer line holding parameter
"          option  - value to put against print setting
"  insert: new option value
"  return: n/a
"  assume: cursor is on line to be modified
function s:ModifyDialogParameter(line_no, option)

    " TODO: add setting as argument
    " TODO: for device add message if default
    " TODO: for font add message if only courier

    setlocal modifiable
    let l:param_line = getline(a:line_no)
    let l:param_line = strpart(l:param_line, 0, 13)
                \ . '<' . a:option . '>'
    call setline(a:line_no, l:param_line)
    setlocal nomodifiable

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

    " get name of setting being toggled                                {{{3
    let l:line = line('.')
    if has_key(s:optLine, l:line)
        let l:setting = s:optLine[l:line]
    else
        echo 'no parameter under cursor...'
        return
    endif

    " get new option value for setting                                 {{{3
    call s:ChangePrintSettingOption(l:setting, a:step)
    let l:option = s:settings[l:setting].current

    " display newly selected option value                              {{{3
    " TODO: add l:setting as argument
    call s:ModifyDialogParameter(l:line, l:option)                   " }}}3

endfunction

" <SID>PRD_ShowHelpOnParameter()                                       {{{2
"  intent: how help on parameter under cursor
"  params: nil
"  insert: nil
"  return: n/a
function <SID>PRD_ShowHelpOnParameter()

    " determine which setting cursor is on
    let l:line = line('.')
    if has_key(s:optLine, l:line)
        let l:setting = s:optLine[l:line]
    else
        echo 'to get help move cursor on parameter'
        return
    endif

    " display appropriate help
    echo s:settings[l:setting].help

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
    call s:SetHardcopyArguments()

    " construct print command                                          {{{3
    let l:cmd = s:range.start . ',' . s:range.end . 'hardcopy'
    if tolower(s:settings.dialog.current) ==# 'no'
        let l:cmd .= '!'
    endif

    " work with plugins that alter 'printexpr'                         {{{3
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



" SETTINGS:                                                            {{{1

" restore saved 'cpoptions'                                            {{{2
let &cpoptions = s:save_cpoptions                                    " }}}2
                                                                     " }}}1
" vim: fdm=marker :
