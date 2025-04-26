﻿{ -------------------------------------------------------------------------------
  The contents of this file are subject to the Mozilla Public License
  Version 1.1 (the "License"); you may not use this file except in
  compliance with the License. You may obtain a copy of the License at
  https://www.mozilla.org/MPL/

  Software distributed under the License is distributed on an "AS IS"
  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
  License for the specific language governing rights and limitations
  under the License.

  The Original Code is SynHighlighterPukiWiki.pas, released 2025-04-26.

  The Initial Developer of the Original Code is MASUDA Takshi.
  Portions created by the Initial Developer are Copyright (C) 2025
  the Initial Developer. All Rights Reserved.

  Contributor(s):

  Alternatively, the contents of this file may be used under the terms of
  the GNU General Public License Version 2 or later (the  "GPL"),
  in which case the provisions of GPL are applicable instead of those
  above.  If you wish to allow use of your version of this file only
  under the terms of the GPL and not to allow others to use your version of
  this file under the MPL, indicate your decision by deleting the provisions
  above and replace  them with the notice and other provisions required
  by the GPL. If you do not delete the provisions above, a recipient may use
  your version of this file under either the MPL or the GPL.
  ------------------------------------------------------------------------------- }

unit SynHighlighterPukiWiki;

interface

uses
  System.Classes, System.StrUtils, System.Math, Vcl.Graphics,
  System.RegularExpressions, SynEditHighlighter;

type
  TtkTokenKind = (tkUnknown, tkBlockQuote, tkCode, tkDelete, tkEmphasis,
    tkHeader, tkLink, tkList, tkSpace);

  TSynPukiWikiSyn = class(TSynCustomHighlighter)
  private
    FBlockQuoteAttri: TSynHighlighterAttributes;
    FCodeAttri: TSynHighlighterAttributes;
    FDeleteAttri: TSynHighlighterAttributes;
    FEmphasisAttri: TSynHighlighterAttributes;
    FHeadingAttri: TSynHighlighterAttributes;
    FLinkAttri: TSynHighlighterAttributes;
    FListAttri: TSynHighlighterAttributes;
    FSpaceAttri: TSynHighlighterAttributes;
    FTextAttri: TSynHighlighterAttributes;

    FTokenID: TtkTokenKind;

    function BlockQuoteProc: Boolean;
    function DeleteProc: Boolean;
    function EmphasisProc: Boolean;
    function HeadingProc: Boolean;
    function IndentedCodeBlockProc: Boolean;
    function ListProc: Boolean;
    function PageLinkProc: Boolean;
    function UrlLinkProc: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetDefaultAttribute(Index: Integer)
      : TSynHighlighterAttributes; override;
    class function GetFriendlyLanguageName: String; override;
    function GetEol: Boolean; override;
    class function GetLanguageName: String; override;
    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenKind: Integer; override;
    procedure Next; override;
  published
    property BlockQuoteAttri: TSynHighlighterAttributes read FBlockQuoteAttri
      write FBlockQuoteAttri;
    property CodeAttri: TSynHighlighterAttributes read FCodeAttri
      write FCodeAttri;
    property DeleteAttri: TSynHighlighterAttributes read FDeleteAttri
      write FDeleteAttri;
    property EmphasisAttri: TSynHighlighterAttributes read FEmphasisAttri
      write FEmphasisAttri;
    property HeadingAttri: TSynHighlighterAttributes read FHeadingAttri
      write FHeadingAttri;
    property LinkAttri: TSynHighlighterAttributes read FLinkAttri
      write FLinkAttri;
    property ListAttri: TSynHighlighterAttributes read FListAttri
      write FListAttri;
    property SpaceAttri: TSynHighlighterAttributes read FSpaceAttri
      write FSpaceAttri;
  end;

implementation

{ TSynPukiWikiSyn }

function TSynPukiWikiSyn.BlockQuoteProc: Boolean;
const
  BlockQuote = '^>.+$';
var
  Ret: TMatch;
begin
  if Run > 0 then
    Exit(False);

  Ret := TRegEx.Match(FLine, BlockQuote, [roCompiled]);
  if Ret.Success then
  begin
    FTokenID := tkBlockQuote;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

constructor TSynPukiWikiSyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FBlockQuoteAttri := TSynHighlighterAttributes.Create('BlockQuote',
    'Block Quote');
  FBlockQuoteAttri.Foreground := clWebDimGray;
  AddAttribute(FBlockQuoteAttri);

  FCodeAttri := TSynHighlighterAttributes.Create('Code', 'Code');
  FCodeAttri.Foreground := clWebFirebrick;
  AddAttribute(FCodeAttri);

  FDeleteAttri := TSynHighlighterAttributes.Create('Delete', 'Delete');
  FDeleteAttri.Foreground := clWebDimGray;
  AddAttribute(FDeleteAttri);

  FEmphasisAttri := TSynHighlighterAttributes.Create('Emphasis', 'Emphasis');
  FEmphasisAttri.Foreground := clWebDeepPink;
  AddAttribute(FEmphasisAttri);

  FHeadingAttri := TSynHighlighterAttributes.Create('Heading', 'Heading');
  FHeadingAttri.Foreground := clWebMediumBlue;
  AddAttribute(FHeadingAttri);

  FLinkAttri := TSynHighlighterAttributes.Create('Link', 'Link');
  FLinkAttri.Foreground := clBlue;
  AddAttribute(FLinkAttri);

  FListAttri := TSynHighlighterAttributes.Create('List', 'List');
  FListAttri.Foreground := clWebDeepPink;
  AddAttribute(FListAttri);

  FSpaceAttri := TSynHighlighterAttributes.Create('Space', 'Space');
  FSpaceAttri.Foreground := clWebCornFlowerBlue;
  AddAttribute(FSpaceAttri);

  FTextAttri := TSynHighlighterAttributes.Create('Text', 'Text');
  AddAttribute(FTextAttri);

  FBrackets := '<>()[]{}';
end;

function TSynPukiWikiSyn.DeleteProc: Boolean;
const
  Delete = '(%%)[^%]+\1';
var
  Ret: TMatch;
begin
  var
    Regex: TRegEx := TRegEx.Create(Delete, [roCompiled]);

  Ret := Regex.Match(FLine, Run + 1);
  if Ret.Success and (Run = (Ret.Index - 1)) then
  begin
    FTokenID := tkDelete;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

destructor TSynPukiWikiSyn.Destroy;
begin

  inherited;
end;

function TSynPukiWikiSyn.EmphasisProc: Boolean;
const
  Emphasis1 = '(''{2,3})[^'']+?\1';
  Emphasis2 = '(%%%)[^%].*?\1';
var
  Ret: TMatch;
begin
  var
    Regex1: TRegEx := TRegEx.Create(Emphasis1, [roCompiled]);

  Ret := Regex1.Match(FLine, Run + 1);
  if Ret.Success and (Run = (Ret.Index - 1)) then
  begin
    FTokenID := tkEmphasis;
    Run := Run + Ret.Length;
    Exit(True);
  end;

  var
    Regex2: TRegEx := TRegEx.Create(Emphasis2, [roCompiled]);

  Ret := Regex2.Match(FLine, Run + 1);
  if Ret.Success and (Run = (Ret.Index - 1)) then
  begin
    FTokenID := tkEmphasis;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

function TSynPukiWikiSyn.GetDefaultAttribute(Index: Integer)
  : TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_WHITESPACE:
      Result := FSpaceAttri;
  else
    Result := nil;
  end;

end;

function TSynPukiWikiSyn.GetEol: Boolean;
begin
  Result := Run = FLineLen + 1;
end;

class function TSynPukiWikiSyn.GetFriendlyLanguageName: String;
begin
  Result := 'PukiWiki';
end;

class function TSynPukiWikiSyn.GetLanguageName: String;
begin
  Result := 'PukiWiki';
end;

function TSynPukiWikiSyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case FTokenID of
    tkUnknown:
      Result := FTextAttri;
    tkBlockQuote:
      Result := FBlockQuoteAttri;
    tkCode:
      Result := FCodeAttri;
    tkDelete:
      Result := FDeleteAttri;
    tkEmphasis:
      Result := FEmphasisAttri;
    tkHeader:
      Result := FHeadingAttri;
    tkLink:
      Result := FLinkAttri;
    tkList:
      Result := FListAttri;
    tkSpace:
      Result := FSpaceAttri
  else
    Result := nil;
  end;
end;

function TSynPukiWikiSyn.GetTokenKind: Integer;
begin
  Result := Ord(FTokenID);
end;

function TSynPukiWikiSyn.HeadingProc: Boolean;
const
  Heading = '^\*{1,3}.+$';
var
  Ret: TMatch;
begin
  if Run > 0 then
    Exit(False);

  Ret := TRegEx.Match(FLine, Heading, [roCompiled]);
  if Ret.Success then
  begin
    FTokenID := tkHeader;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

function TSynPukiWikiSyn.IndentedCodeBlockProc: Boolean;
const
  Code = '^ .*';
var
  Ret: TMatch;
begin
  if Run > 0 then
    Exit(False);

  Ret := TRegEx.Match(FLine, Code, [roCompiled]);
  if Ret.Success then
  begin
    FTokenID := tkCode;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

function TSynPukiWikiSyn.ListProc: Boolean;
const
  List1 = '^([-+])(\1)*';
  List2 = '^(:{1,3}).*\|';
var
  Ret: TMatch;
begin
  if Run > 0 then
    Exit(False);

  Ret := TRegEx.Match(FLine, List1, [roCompiled]);
  if Ret.Success then
  begin
    if LeftStr(Ret.Value, 4) = '----' then
      Exit(False);
    FTokenID := tkList;
    Run := Run + Min(Ret.Length, 3);
    Exit(True);
  end;

  Ret := TRegEx.Match(FLine, List2, [roCompiled]);
  if Ret.Success then
  begin
    FTokenID := tkList;
    Run := Run + Length(Ret.Groups[1].Value);
    Exit(True);
  end;
  Result := False;
end;

procedure TSynPukiWikiSyn.Next;
begin
  FTokenPos := Run;

  if not(HeadingProc or BlockQuoteProc or ListProc or IndentedCodeBlockProc or
    EmphasisProc or DeleteProc or UrlLinkProc or PageLinkProc) then
  begin
    FTokenID := tkUnknown;
    Inc(Run);
  end;

  inherited;
end;

function TSynPukiWikiSyn.PageLinkProc: Boolean;
const
  Link = '\[\[.+?\]\]';
var
  Ret: TMatch;
begin
  var
    Regex: TRegEx := TRegEx.Create(Link, [roCompiled]);

  Ret := Regex.Match(FLine, Run + 1);
  if Ret.Success and (Run = (Ret.Index - 1)) then
  begin
    FTokenID := tkLink;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

function TSynPukiWikiSyn.UrlLinkProc: Boolean;
const
  Link = 'https?://[\w!?/+\-_~=;.,*&@#$%()'']+';
var
  Ret: TMatch;
begin
  var
    Regex: TRegEx := TRegEx.Create(Link, [roCompiled]);

  Ret := Regex.Match(FLine, Run + 1);
  if Ret.Success and (Run = (Ret.Index - 1)) then
  begin
    FTokenID := tkLink;
    Run := Run + Ret.Length;
    Exit(True);
  end;
  Result := False;
end;

initialization

RegisterPlaceableHighlighter(TSynPukiWikiSyn);

end.
