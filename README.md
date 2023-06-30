# WebPaste

Paste between websites with better formatting. Use with Raycast, Alfred, or your preferred macOS
script runner.

TODO
- [ ] fix line breaks between paragraphs, sometimes missing
- [ ] gif in README below
- [ ] test with more sites, inbound and outbound
  - how GMail-specific is this? any sites where it's super wrong?
- [ ] get images working

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
to HTML which it writes to the system pasteboard. When you paste into a website, the browser reads
that HTML and converts it back to DOM elements[^0]. The site you're pasting into then does ...
whatever it feels like with those elements.

Extracted-from-a-live-website DOM elements are not a great format for copying and pasting. The DOM
mixes content we care about—the actual text, as well as basic structures like lists, links, and
headings—with a lot of presentational noise and implementation details that we'd rather omit. It's
great (maybe) for building websites, but it fails quickly for our use case. The copied-and-pasted
output includes all that noise that we don't want.

Try pasting from Google Docs into GMail, and you'll discover:
- the fonts and font sizes are off
- everything is bold, but sometimes not the _same_ bold as if you'd clicked the `B` icon
- indendation levels are arbitrary, depending on some hidden state in your GDoc
- bulleted and numbered lists look OK, but further editing in GMail doesn't behave correctly
- etc

Some sites go to lengths to avoid these problems. Dropbox Paper, for example, ensures that clean
HTML winds up in the pasteboard, and then sanitizes pasted input before displaying. Good on 'em.

## Cleaning up

The standard solution is "paste without formatting". Browsers write plaintext to the pasteboard
alongside HTML, and apps can choose to access either. Users can force a plaintext paste in most
apps with <kbd>⌘</kbd><kbd>⇧</kbd><kbd>⌥</kbd><kbd>V</kbd>. But plaintext goes too far! We avoid the
mismatched fonts and hidden DOM structure, but we also lose the links, lists, headings, emphasis,
etc.

We can do better by cleaning up the HTML in the pasteboard. WebPaste reads and parses the HTML,
removes most of the attributes and extra structure, then writes it back to the pasteboard before
initiating a regular <kbd>⌘</kbd><kbd>V</kbd> paste.

This isn't a perfect solution! There's no rigorous way to separate the structure and attributes that
we do care about from those that we don't. This is just a set of basic rules that err on the side of
removing noise and implementation details. WebPaste is more likely to over-clean your text than
under-clean it. YMMV.

[^0]: An oversimplification. The truth is in [the docs](https://developer.apple.com/documentation/appkit/nspasteboard).
