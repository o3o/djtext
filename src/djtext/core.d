// Copyright 2013 Gushcha Anton
module djtext.core;

import std.experimental.logger;

/**
 * Special locale that doesn't have own locale file.
 */
enum BASE_LOCALE = "en_US";

/**
 * Language file extension
 */
enum LOCALE_EXTESION = ".json";

private string _defaultLocale = BASE_LOCALE;
private string[string][string] localeMap;
private string[][string] fuzzyText;

/**
 * Returns translated string $(B s) for specified $(B locale). If locale is empty default
 * locale will be taken. If locale name is equal to base locale $(B s) string is returned
 * without modification.
 *
 * Localization strings are taken from special files previosly loaded into memory.
 *
 * If string $(B s) isn't persists in locale strings it will be put into fuzzy text map.
 * Fuzzy strings is saved in separate file for each locale to be translated later.
 *
 * See_Also: BASE_LOCALE, defaultLocale properties.
 *
 * Example:
 * --------
 * assert(getdtext("Hello, world!", "ru_RU") == "Привет, мир!");
 * assert(getdtext("Hello, world!", "es_ES") == "Hola, mundo!");
 * assert(getdtext("") == "");
 * --------
 */
string getdtext(string s, string locale = "") {
   import std.algorithm : find;

   if (locale == "") {
      locale = defaultLocale;
   }
   if (locale == BASE_LOCALE) {
      return s;
   }

   if (locale in localeMap) {
      auto map = localeMap[locale];
      if (s in map) {
         return map[s];
      }
   }
   if (locale !in fuzzyText) {
      fuzzyText[locale] = [];
   }
   if (fuzzyText[locale].find(s) == []) {
      fuzzyText[locale] ~= s;
   }
   return s;
}

/// Short name for getdtext
alias _ = getdtext;

/**
 * Setups current locale name. If empty string is passed to
 * $(B getdtext) then default locale will be taken.
 *
 * Example:
 * --------
 * defaultLocale = "ru_RU";
 * defaultLocale = BASE_LOCALE;
 * --------
 */
void defaultLocale(string locale) {
   _defaultLocale = locale;
}

/**
 * Returns current locale name. If empty string is passed to
 * $(B getdtext) then default locale will be taken.
 */
string defaultLocale() {
   return _defaultLocale;
}

/**
 * Manuall loads localization file with $(B name).
 *
 * Example:
 * --------
 * loadLocaleFile("ru_RU");
 * loadLocaleFile("es_ES");
 * --------
 */
void loadLocaleFile(string name) {
   import std.path : baseName;
   import std.file : readText;
   import std.string : endsWith;
   import std.json;

   //import vibe.data.json: Json, parseJsonString;

   if (!name.endsWith(LOCALE_EXTESION)) {
      name ~= LOCALE_EXTESION;
   }

   auto localeName = baseName(name, LOCALE_EXTESION);
   if (localeName !in localeMap) {
      localeMap[localeName] = ["" : ""];
   }
   auto map = localeMap[localeName];

   string jsonString = readText(name);
   JSONValue json = parseJSON(jsonString);

   foreach (string k, v; json) {
      map[k] = v.str;
   }
}

private string getFuzzyLocaleFileName(string locale) {
   return locale ~ ".fuzzy";
}

void saveFuzzyText() {
   import std.stdio : File;

   foreach (locale, strs; fuzzyText) {
      try {
         auto file = new File(getFuzzyLocaleFileName(locale), "wr");
         scope (exit)
            file.close;
         file.writeln('{');

         foreach (i, s; strs) {
            string row = `    "` ~ s ~ `" : "` ~ s ~ `"`;
            if (i++ == strs.length - 1) {
               file.writeln(row);
            } else {
               file.writeln(row ~ ",");
            }
         }
         file.write('}');
      } catch (Exception e) {
         errorf("Failed to save fuzzy text for locale %s", locale);
      }
   }
}

unittest {
   loadAllLocales("./locale");
   defaultLocale = "es";

   _("Hello, world!");
   _("Hello, json!");
   _("Hello, json!", "ru");
   _("Hello, json!", "it");
   _("Hello, dj!", "it");
   saveFuzzyText();
}

/**
 * Loads all localization files in `dir`
 *
 * Params:
 *  dir = The directory to iterate over.*
 */
void loadAllLocales(string dir) {
   import std.algorithm : filter, each;

   //import std.algorithm.searching: endsWith;
   import std.string : endsWith;
   import std.file : dirEntries, SpanMode;

   //auto locFiles = dirEntries(dir, SpanMode.shallow).filter!(f => f.name.endsWith(".json"));
   dirEntries(dir, SpanMode.shallow).filter!(f => f.name.endsWith(".json"))
      .each!(f => loadLocaleFile(f.name));
   /+
      //auto locFiles = filter!`endsWith(a.name,".json")`(dirEntries(dir, SpanMode.shallow));
      foreach (entry; locFiles) {
         try {
            loadLocaleFile(entry.name);
         } catch (Exception e) {
            import std.stdio;

            writeln("Failed to load localization file ", entry.name, ". Reason: ", e.msg);
         }
      }
   +/
}

unittest {
   loadAllLocales("./locale");
   defaultLocale = "ru";
   assert(_("Hello, world!") == "Привет, мир!");
   assert(_("Hello, world!", "es") == "Hola, mundo!");
   assert(getdtext("") == "");
   assert(getdtext("cul") == "cul");
}

unittest {
   class Test {
      string getHello() {
         return _("Hello");
      }
   }

   //this setting also takes effect in the test module
   defaultLocale = "it";
   loadAllLocales("./locale");
   assert(_("Hello") == "Ciao");

   auto x = new Test();
   assert(x.getHello() == "Ciao");
}
