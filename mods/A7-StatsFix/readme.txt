Fix corruption from the "Detectable Spells" library
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Version:    1.0
Author:     Argent77

Download:   https://www.gibberlings3.net/forums/topic/41551-a-mod-for-fixing-compatibility-issues-between-ds-and-weidu-251/


Overview
~~~~~~~~

This mod can be used to fix file corruptions that were caused by installing mods with outdated
"Detectable Spell" library versions with WeiDU version 251.

The consequences of the file corruption usually become apparent only much later in the mod
installation process, when it is too late to safely undo the changes manually.

It manifests itself as an error message like this:

  [some_script.BCS.BAF] PARSE ERROR at line 103 column 1-37
  Near Text: )
          syntax error

  [some_script.BCS.BAF]  ERROR at line 103 column 1-37
  Near Text: )
          Parsing.Parse_error
  ERROR: parsing [some_script.BCS.BAF]: Parsing.Parse_error
  ERROR: [some_script.BCS] -> [override/some_script.BCS] Patching Failed (COPY) (Parsing.Parse_error)
  Stopping installation because of error.


If that error is encountered in a mod installation then run this fix and try installing the mod again.
It is possible to run this mod multiple times in case the error is triggered again by another mod.


Credits
~~~~~~~

Coding and testing: Argent77


Copyright Notice
~~~~~~~~~~~~~~~~

This mod is published under the "MIT License". See LICENSE for details.


History
~~~~~~~

1.0
- Initial release
