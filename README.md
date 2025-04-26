# SynEdit highlighter for PukiWiki


## Overview

A PukiWiki highlighter component for SynEdit.


## Requirement

- Delphi 12.1
- [SynEdit](https://github.com/pyscripter/SynEdit)


## Usage

### Using Source

Add SynHighlighterPukiWiki.pas to your project.

```pascal
uses
  SynHighlighterPukiWiki;

...

var
  HL: TSynPukiWikiSyn;

...

HL := TSynPukiWikiSyn.Create(Self);
SynEdit1.Highlighter := HL;

```

### Componentization

1. Open SynEditHighlighterPukiWiki.dproj
2. Install SynEditHighlighterPukiWiki.bpl
3. Place the TSynPukiWikiSyn component from the Tool Palette on the form
4. In the Object Inspector, assign the TSynPukiWikiSyn component to the Highlighter
   property of the SynEdit


## Author

MASUDA Takashi <https://mas3lab.net/>
