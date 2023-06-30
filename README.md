# WebPaste

Paste between websites with better formatting. Use with Raycast, Alfred, or your preferred macOS
script runner.

## Usage

Copy text from a website, then activate WebPaste.

https://github.com/mkscrg/WebPaste/assets/471342/64d6b330-44d4-4f0b-8ce5-73f33f5687ab

## Install

Clone then build `WebPaste`:

```sh
      dev/ $ git clone git@github.com:mkscrg/web-paste.git
      dev/ $ cd web-paste
web-paste/ $ swift build -c release
```

Configure your script runner to use the executable at `.build/release/WebPaste`.

### Raycast example

Create a new script command in your script directory:

```sh
#!/usr/bin/env zsh

# @raycast.schemaVersion 1
# @raycast.title Web Paste
# @raycast.mode silent
# @raycast.icon 🌐

# path to your WebPaste build
~/dev/web-paste/.build/release/WebPaste
```

## DOM in the Pasteboard

When you copy from a website, your browser maps your selection to DOM elements, then converts those
elements to HTML which it writes to the pasteboard. When you paste into a website, the browser reads
that HTML and converts it back to DOM elements[^0]. Then the site you've pasted into does ...
whatever it feels like.

This process is not setup for success. The DOM is a messy intermediate step in the process of making
websites, full of site-specific implementation details and accidental complexity. It mixes content
we care about—actual text, as well as basic structures like lists, links, and headings—with a lot of
noise we'd rather omit. That's why our naively copied-and-pasted text looks like a zombie cutout of
the site we copied from.

Worse, try copying from a rich text editor like Google Docs into GMail:
- the fonts and font sizes are off
- everything is bold, but sometimes not the _same_ bold as if you'd clicked the `B` icon
- indendation levels are arbitrary, depending on some hidden state in your GDoc
- bulleted and numbered lists look OK, but further editing in GMail doesn't behave correctly
- etc

Some sites go to lengths to avoid these problems. Dropbox Paper, for example, ensures that clean
HTML winds up in the pasteboard, and then sanitizes pasted input before displaying. Good on 'em.

## Cleaning up

The standard solution is "paste without formatting". Browsers write plaintext to the pasteboard
alongside HTML, and apps can choose to access either when the user initiates a paste. Users can
force a plaintext paste in most apps with <kbd>⌘</kbd><kbd>⇧</kbd><kbd>⌥</kbd><kbd>V</kbd>.

But plaintext goes too far! We avoid the mismatched fonts and hidden structure, but we also lose the
links, lists, headings, emphasis, etc.

We can do better by cleaning up the HTML in the pasteboard. WebPaste reads and parses that HTML,
removes most of the attributes and extra structure, then writes it back to the pasteboard before
initiating a regular <kbd>⌘</kbd><kbd>V</kbd> paste.

This isn't a perfect solution. Picking out the formatting intent in a sea of markup is a heuristic
process, at best. WebPaste is more likely to over-clean your text than under-clean it. This is a
lark. YMMV. Pull requests welcome.

[^0]: An oversimplification. The truth is in [the docs](https://developer.apple.com/documentation/appkit/nspasteboard).
