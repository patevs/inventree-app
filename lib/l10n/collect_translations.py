"""
Collect translation files into a single directory,
where they can be accessed by the flutter i18n library.

Translations provided from crowdin are located in subdirectories,
but we need the .arb files to appear in this top level directory
to be accessed by the app.

So, simply copy them here!

"""

import os
import glob
from posixpath import dirname
import shutil
import re


def process_locale_file(filename, locale_name):
    """
    Process a locale file after copying

    - Ensure the 'locale' matches
    """

    # TODO: Use JSON processing instead of manual
    # Need to work out unicode issues for this to work

    with open(filename, "r", encoding="utf-8") as input_file:
        lines = input_file.readlines()

    with open(filename, "w", encoding="utf-8") as output_file:
        # Using JSON processing would be simpler here,
        # but it does not preserve unicode data!
        for line in lines:
            if "@@locale" in line:
                new_line = f'    "@@locale": "{locale_name}"'

                if "," in line:
                    new_line += ","

                new_line += "\n"

                line = new_line

            output_file.write(line)


def copy_locale_file(path):
    """
    Locate and copy the locale file from the provided directory
    """

    here = os.path.abspath(os.path.dirname(__file__))

    for f in os.listdir(path):
        src = os.path.join(path, f)
        dst = os.path.join(here, "collected", f)

        if os.path.exists(src) and os.path.isfile(src) and f.endswith(".arb"):
            shutil.copyfile(src, dst)
            print(f"Copied file '{f}'")

            locale = os.path.split(path)[-1]

            process_locale_file(dst, locale)

            # Create a "fallback" locale file, without a country code specifier, if it does not exist
            r = re.search(r"app_(\w+)_(\w+).arb", f)
            locale = r.groups()[0]
            fallback = f"app_{locale}.arb"

            fallback_file = os.path.join(here, "collected", fallback)

            if not os.path.exists(fallback_file):
                print(f"Creating fallback file:", fallback_file)
                shutil.copyfile(dst, fallback_file)

                process_locale_file(fallback_file, locale)


def generate_locale_list(locales):
    """
    Generate a .dart file which contains all the supported locales,
    for importing into the project
    """

    with open("supported_locales.dart", "w") as output:
        output.write(
            "// This file is auto-generated by the 'collect_translations.py' script - do not edit it directly!\n\n"
        )
        output.write("// dart format off\n\n")
        output.write('import "package:flutter/material.dart";\n\n')
        output.write("const List<Locale> supported_locales = [\n")

        locales = sorted(locales)

        for locale in locales:
            if locale.startswith("."):
                continue

            splt = locale.split("_")

            if len(splt) == 2:
                lc, cc = splt
            else:
                lc = locale
                cc = ""

            output.write(
                f'    Locale("{lc}", "{cc}"),   // Translations available in app_{locale}.arb\n'
            )

        output.write("];\n")
        output.write("")


if __name__ == "__main__":
    here = os.path.abspath(os.path.dirname(__file__))

    # Ensure the 'collected' output directory exists
    output_dir = os.path.join(here, "collected")
    os.makedirs(output_dir, exist_ok=True)

    # Remove existing .arb files from output directory
    arbs = glob.glob(os.path.join(output_dir, "*.arb"))

    for arb in arbs:
        os.remove(arb)

    locales = ["en"]

    for locale in os.listdir(here):
        # Ignore the output directory
        if locale == "collected":
            continue

        f = os.path.join(here, locale)

        if os.path.exists(f) and os.path.isdir(locale):
            copy_locale_file(f)
            locales.append(locale)

    # Ensure the translation source file ('app_en.arb') is copied also
    # Note that this does not require any further processing
    src = os.path.join(here, "app_en.arb")
    dst = os.path.join(here, "collected", "app_en.arb")

    shutil.copyfile(src, dst)

    generate_locale_list(locales)

    print(f"Updated translations for {len(locales)} locales.")
