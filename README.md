# djtext
djtext provides functions to handle localization.

Based on [Anton Gushcha](https://github.com/NCrashed/dtext) similar work.


Example:
```
import std.stdio, std.opt, dtext;

void main(string[] args) {
  string locale;
  getopt(args, "l|lang", &locale);

  defaultLocale = locale;
  writeln(_("Hello, world!")); \\ or use getdtext
}
```

If text for translation cannot be found in specified locale name, the text can be saved and written down to a special fuzzy texts file at program shutdown. That should help to add new localization fast and without program recompilation.

## License
Distributed under the Boost Software License, Version 1.0. See copy at http://www.boost.org/LICENSE_1_0.txt.
