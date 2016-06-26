Print plugin for use on unix systems
====================================

This is a fork of Christian Habermann's [Printer Dialog][] plugin updated to use modern vimscript features, fix bugs and add features.

[Printer Dialog]: https://github.com/vim-scripts/Printer-Dialog

If you are familiar with the original plugin, simply skip to [Changes from original plugin](#changes-from-original-plugin). If you are new to it, please read on for a brief summary. Detailed information is available after installation with |:help printer-dialog|.

Installation
------------

Install using your favourite package manager.

If you prefer to install vim plugins from git repositories manually, then you don't need any additional help.

Print dialog
------------

The plugin provides a print dialog that is opened with `<Leader>pd`. In the dialog you can alter print settings and start printing or cancel the dialog.

The following settings can be changed:

* print device
* font and size
* paper size
* paper orientation
* size of header
* line-numbering
* syntax highlighting colorscheme
* line wrapping
* duplex printing (and which side to bind on)
* collation
* splitting individual copies into separate print jobs
* left, right, top and bottom print margins
* whether to display the operating system print dialog (MS Windows only)

Help is available in the print dialog for each setting.

Customisation
-------------

For each setting it is possible for a user to specify custom values and which value is the default. This is done by setting global variables, and can be done conveniently in your `.vimrc` file. Further details can be obtained after installation with |:help prtdialog-parameters|.

Changes from original plugin
----------------------------

### Modern features

The plugin has been updated to use modern vimscript features such as lists and dictionaries. Much of the plugin's work is manipulating lists of option values and using Lists makes the plugin script much easier to understand.

None of these changes make any difference to the user experience.

### Bugfix

Due to enclosing a newline in single quotes there is an off-by-one error in the script writing content to the print buffer.

The original version of the script fails it there are unsaved changes in the buffer to be printed. It now attempts to save the buffer before running.

The original plugin did not check availability of preset colorschemes before selecting them. Preset colorschemes are now checked before including them as selectable option values.

### Enhancements

Each time the print dialog is invoked the script scans for enabled print devices and adds them to the printer list. If the print dialog is invoked multiple times in a single editing session, it will remember the previously selected printer and, if still available, will preselect it.

License
-------

This plugin is made available under the same license as vim. See |:help license| for further details.
