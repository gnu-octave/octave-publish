## Copyright (C) 2016 Kai T. Ohlhus <k.ohlhus@gmail.com>
## Copyright (C) 2010 Fotios Kasolis <fotios.kasolis@gmail.com>
##
## This file is part of Octave.
##
## Octave is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or (at
## your option) any later version.
##
## Octave is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {} publish (@var{filename})
## @deftypefnx {Function File} {} publish (@var{filename}, @var{options})
## Produces latex reports from scripts.
##
## @example
## publish (@var{my_script})
## @end example
##
## @noindent
## where the argument is a string that contains the file name of
## the script we want to report.
##
## If two arguments are given, they are interpreted as follows.
##
## @example
## publish (@var{filename}, [@var{option}, @var{value}, ...])
## @end example
##
## @noindent
## The following options are available:
##
## @itemize @bullet
## @item format
## 
## the only available format values are the strings `latex' and
## `html'.
##
## @item
## imageFormat:
##
## string that specifies the image format, valid formats are `pdf',
## `png', and `jpg'(or `jpeg').
##
## @item
## showCode:
##
## boolean value that specifies if the source code will be included
## in the report.
##
## @item
## evalCode:
##
## boolean value that specifies if execution results will be included
## in the report.
## 
## @end itemize
##
## Default @var{options}
##
## @itemize @bullet
## @item format = latex
##
## @item imageFormat = pdf
##
## @item showCode =  1
##
## @item evalCode =  1
##
## @end itemize
##
## Remarks
##
## @itemize @bullet
## @item Any additional non-valid field is removed without
## notification.
##
## @item To include several figures in the resulting report you must
## use figure with a unique number for each one of them.
##
## @item You do not have to save the figures manually, publish will
## do it for you.
##
## @item The functions works only for the current path and no way ...
## to specify other path is allowed.
##
## @end itemize
##
## Assume you have the script `myscript.m' which looks like
##
## @example
## @group
## x = 0:0.1:pi;
## y = sin(x)
## figure(1)
## plot(x,y);
## figure(2)
## plot(x,y.^2);
## @end group
## @end example
##
## You can then call publish with default @var{options}
## 
## @example
## publish("myscript")
## @end example
## @end deftypefn

function out_file = publish (file, varargin)
  narginchk (1, Inf);
  nargoutchk (0, 1);

  if (exist (file, "file") != 2)
    error ("publish: FILE does not exist.");
  endif

  ## Check file extension to be an Octave script
  [~,~,file_ext] = fileparts (file);
  if (!strcmp (file_ext, ".m"))
    error ("publish: Only Octave scripts can be published.");
  endif

  ## Get structure with necessary options
  options = struct ();
  if (numel (varargin) == 1)
    ## Call: publish (file, format)
    if (ischar (varargin{1}))
      options.format = varargin{1};
    ## Call: publish (file, options)
    elseif (isstruct (varargin{1}))
      options = varargin{1};
    else
      error ("publish: Invalid second argument.");
    endif
  ## Call: publish (file, Name1, Value1, Name2, Value2, ...)
  elseif ((rem (numel (varargin), 2) == 0) ...
          && (all (cellfun (@ischar, varargin))))
    for i = 1:2:numel(varargin)
      setfield (options, varargin{i}, varargin{i + 1});
    endfor
  else
    error ("publish: Invalid or inappropriate arguments.");
  endif

  ##
  ## Validate options struct
  ##

  ## Options for the output
  if (! isfield (options, "format"))
    options.format = "html";
  else
    options.format = validatestring (options.format, ...
      {"html", "doc", "latex", "ppt", "xml", "pdf"});
    ## TODO: implement remaining formats
    if (! any (strcmp (options.format, {"html", "latex"})))
      error ("publish: Output format currently not supported");
    endif
  endif

  if (! isfield (options, "outputDir"))
    options.outputDir = "";
  elseif (! ischar (options.outputDir))
    error ("publish: OUTPUTDIR must be a string");
  endif

  if (! isfield (options, "stylesheet"))
    options.stylesheet = "";
  elseif (! ischar (options.stylesheet))
    error ("publish: STYLESHEET must be a string");
  endif

  ## Options for the figures
  if (! isfield (options, "createThumbnail"))
    options.createThumbnail = true;
  elseif ((! isscalar (options.createThumbnail)) ...
          || (! isbool (options.createThumbnail)))
    error ("publish: CREATETHUMBNAIL must be TRUE or FALSE");
  endif

  if (! isfield (options, "figureSnapMethod"))
    options.figureSnapMethod = "entireGUIWindow";
  else
    options.figureSnapMethod = validatestring (options.figureSnapMethod, ...
      {"entireGUIWindow", "print", "getframe", "entireFigureWindow"});
    ## TODO: implement
    warning ("publish: option FIGURESNAPMETHOD currently not supported")
  endif

  if (! isfield (options, "imageFormat"))
    switch (options.format)
      case "latex"
        options.imageFormat = "epsc2";
      case "pdf"
        options.imageFormat = "bmp";
      otherwise
        options.imageFormat = "png";
    endswitch
  elseif (! ischar (options.imageFormat))
    error ("publish: IMAGEFORMAT must be a string");
  else
    ## check valid imageFormat for chosen format
    ##   html, latex, and xml accept any imageFormat
    switch (options.format)
      case {"doc", "ppt"}
        options.imageFormat = validatestring (options.imageFormat, ...
          {"png", "jpg", "bmp", "tiff"});
      case "pdf"
        options.imageFormat = validatestring (options.imageFormat, ...
          {"bmp", "jpg"});
    endswitch
  endif

  if (! isfield (options, "maxHeight"))
    options.maxHeight = [];
  elseif ((! isscalar (options.maxHeight)) ...
          || (uint64 (options.maxHeight) == 0))
    error ("publish: MAXHEIGHT must be a positive integer");
  else
    options.maxHeight = uint64 (options.maxHeight);
  endif

  if (! isfield (options, "maxWidth"))
    options.maxWidth = [];
  elseif ((! isscalar (options.maxWidth)) ...
          || (uint64 (options.maxWidth) == 0))
    error ("publish: MAXWIDTH must be a positive integer");
  else
    options.maxWidth = uint64 (options.maxWidth);
  endif

  if (! isfield (options, "useNewFigure"))
    options.useNewFigure = true;
  elseif (! isbool (options.useNewFigure))
    error ("publish: USENEWFIGURE must be TRUE or FALSE");
  endif

  ## Options for the code
  if (!isfield (options, "evalCode"))
    options.evalCode = true;
  elseif ((! isscalar (options.evalCode)) || (! isbool (options.evalCode)))
    error ("publish: EVALCODE must be TRUE or FALSE");
  endif

  if (!isfield (options, "catchError"))
    options.catchError = true;
  elseif ((! isscalar (options.catchError)) || (! isbool (options.catchError)))
    error ("publish: CATCHERROR must be TRUE or FALSE");
  endif

  if (!isfield (options, "codeToEvaluate"))
    options.codeToEvaluate = "";
  elseif (! ischar (options.codeToEvaluate))
    error ("publish: CODETOEVALUTE must be a string");
  endif

  if (! isfield (options, "maxOutputLines"))
    options.maxOutputLines = Inf;
  elseif (! isscalar (options.maxOutputLines))
    error ("publish: MAXOUTPUTLINES must be an integer >= 0");
  else
    options.maxOutputLines = uint64 (options.maxOutputLines);
  endif

  if (!isfield (options, "showCode"))
    options.showCode = true;
  elseif ((! isscalar (options.showCode)) || (! isbool (options.showCode)))
    error ("publish: SHOWCODE must be TRUE or FALSE");
  endif

  m_source = read_file_to_cellstr (file);
  parsed_source = deblank (m_source);

  doc_struct.title = file;
  doc_struct.intro = "";
  doc_struct.body = cell ();
  doc_struct.m_source = m_source;

  ##
  ## Start 1st level parsing
  ##
  [parsed_source, doc_struct] = read_doc_head (parsed_source, doc_struct);
  while (! isempty (parsed_source))
    [parsed_source, doc_struct] = read_paragraph (parsed_source, doc_struct);
    [parsed_source, doc_struct] = read_code (parsed_source, doc_struct);
  endwhile
  clear parsed_source m_source

  ##
  ## Start 2nd level parsing paragraphs
  ##

  ## Define parsing helper functions
  has_N_leading_spaces = @(cstr, N) ! isempty(cstr) ...
                                    && strncmp (char (cstr), "  ", N);
  has_preceding_blank_line = @(cstr, line) (line > 1) ...
                                           && isempty (cstr{line - 1});
  for i = 1:length(doc_struct.body)
    if (any (strcmp (doc_struct.body{i}.type, ...
                     {"paragraph", "paragraph_no_break"})))
      content = doc_struct.body{i}.content;
      p_content = cell ();
      j = 1;
      while (j <= length(content))
        ## Skip empty lines
        if (isempty (content{j}))
          j++;
          continue;
        endif

        start_block = j;
        ## Octave code (two leading spaces)
        if (has_preceding_blank_line (content, j) ...
            && has_N_leading_spaces (content{j}, 2))
          while ((j <= length(content)) ...
                 && (isempty (content{j}) ...
                     || has_N_leading_spaces (content{j}, 2)))
            j++;
          endwhile
          p_content{end+1}.type = "octave_code";
          pstr = content(start_block:j-1);
          for k = 1:length(pstr)
            s = pstr{k};
            pstr{k} = s(3:end);
          endfor
          p_content{end}.content = strjoin (pstr, "\n");
        ## Preformatted text (one leading space)
        elseif (has_preceding_blank_line (content, j) ...
                && has_N_leading_spaces (content{j}, 1))
          while ((j <= length(content)) ...
                 && (isempty (content{j}) ...
                     || has_N_leading_spaces (content{j}, 1)))
            j++;
          endwhile
          p_content{end+1}.type = "preformatted_text";
          pstr = content(start_block:j-1);
          for k = 1:length(pstr)
            s = pstr{k};
            pstr{k} = s(2:end);
          endfor
          p_content{end}.content = strjoin (pstr, "\n");
        ## Bulleted list *
        elseif (has_preceding_blank_line (content, j) ...
                && strncmp (content{j}, "* ", 2))
          while ((j <= length(content)) && (! isempty (content{j})))
            j++;
          endwhile
          p_content{end+1}.type = "bulleted_list";
          p_content{end}.content = strjoin (content(start_block:j-1), "\n");
          ## Revove first "* "
          p_content{end}.content = p_content{end}.content(3:end);
          ## Split items
          p_content{end}.content = strsplit (p_content{end}.content, "\n* ");
        ## Numbered list #
        elseif (has_preceding_blank_line (content, j) ...
                && strncmp (content{j}, "# ", 2))
          while ((j <= length(content)) && (! isempty (content{j})))
            j++;
          endwhile
          p_content{end+1}.type = "numbered_list";
          p_content{end}.content = strjoin (content(start_block:j-1), "\n");
          ## Revove first "# "
          p_content{end}.content = p_content{end}.content(3:end);
          ## Split items
          p_content{end}.content = strsplit (p_content{end}.content, "\n# ");
        ## Include <include>fname.m</include>
        elseif (has_preceding_blank_line (content, j) ...
                && strncmpi (content{j}, "<include>", 9))
          while ((j <= length(content)) && ! isempty (content{j}))
            j++;
          endwhile
          p_content{end+1}.type = "include";
          p_content{end}.content = strjoin (content(start_block:j-1), "");
          ## Remove leading <include>
          p_content{end}.content = p_content{end}.content(10:end);
          ## Remove trailing </include>
          idx = strfind (p_content{end}.content, "</");
          ## Leave malformed input for user to fix
          if (isscalar (idx))
            p_content{end}.content = p_content{end}.content(1:idx-1);
          endif
        ## Graphic <<myGraphic.png>>
        elseif (has_preceding_blank_line (content, j) ...
                && strncmpi (content{j}, "<<", 2))
          while ((j <= length(content)) && ! isempty (content{j}))
            j++;
          endwhile
          p_content{end+1}.type = "graphic";
          p_content{end}.content = strjoin (content(start_block:j-1), "");
          ## Remove leading <<
          p_content{end}.content = p_content{end}.content(3:end);
          ## Remove trailing >>
          idx = strfind (p_content{end}.content, ">>");
          ## Leave malformed input for user to fix
          if (isscalar (idx))
            p_content{end}.content = p_content{end}.content(1:idx-1);
          endif
        ## HTML markup
        elseif (strcmpi (content{j}, "<html>"))
          start_html = j + 1;
          while ((j < length(content)) && ! strcmpi (content{j}, "</html>"))
            j++;
          endwhile
          if ((j == length(content)) && ! strcmpi (content{j}, "</html>"))
            warning ("publish: no closing </html> found");
          else
            j++;  ## Skip closing tag
          endif
          if (j > start_html)
            p_content{end+1}.type = "html";
            p_content{end}.content = strjoin (content(start_html:j-2), "\n");
          endif
        ## LaTeX markup
        elseif (strcmpi (content{j}, "<latex>"))
          start_latex = j + 1;
          while ((j < length(content)) && ! strcmpi (content{j}, "</latex>"))
            j++;
          endwhile
          if ((j == length(content)) && ! strcmpi (content{j}, "</latex>"))
            warning ("publish: no closing </latex> found");
          else
            j++;  ## Skrip closing tag
          endif
          if (j > start_latex)
            p_content{end+1}.type = "latex";
            p_content{end}.content = strjoin (content(start_latex:j-2), "\n");
          endif
        ## Remaining normal text or markups belonging to normal text
        ## that are handled while output generation:
        ##
        ## * Italic, bold, and monospaced text
        ## * Inline and block LaTeX
        ## * Links
        ## * Trademark symbols
        ##
        else
          if (isempty (p_content) || ! strcmp (p_content{end}.type, "text"))
            p_content{end+1}.type = "text";
            p_content{end}.content = content{j};
          else
            p_content{end}.content = strjoin ({p_content{end}.content, ...
                                               content{j}}, "\n");
          endif
          j++;
        endif
      endwhile
      doc_struct.body{i}.content = p_content;
    endif
  endfor

  ##
  ## Start 3rd level code evaluation
  ##

  ## Neccessary as the code does not run interactively
  page_screen_output (0, "local");

  ## Evaluate code, that does not appear in the output.
  if (options.evalCode)
    eval_code (options.codeToEvaluate);
  endif
  for i = 1:length(doc_struct.body)
    if (strcmp (doc_struct.body{i}.type, "code"))
      if (options.evalCode)
        if (options.catchError)
          try
            doc_struct.body{i}.output = eval_code (doc_struct.body{i}.code);
           catch err
            doc_struct.body{i}.output = ["error: ", err.message, ...
              "\n\tin:\n\n", doc_struct.body{i}.code];
          end_try_catch
        else
          doc_struct.body{i}.output = eval_code (doc_struct.body{i}.code);
        endif

        ## Truncate output to desired length
        if (options.maxOutputLines < length (doc_struct.body{i}.output))
          doc_struct.body{i}.output = ...
            doc_struct.body{i}.output(1:options.maxOutputLines);
        endif
        doc_struct.body{i}.output = strjoin (doc_struct.body{i}.output, "\n");

        ## TODO: save figures
      endif

      ## Stip code from output
      if (! options.showCode)
        doc_struct.body{i}.code = [];
      endif
    endif
  endfor

  out_file = doc_struct;

  
  if (strcmpi (options.format, "latex"))
    create_latex (ifile, ofile, options);
  elseif strcmpi(options.format, "html")
    create_html (doc_struct, options);
  endif
  
endfunction



function m_source = read_file_to_cellstr (file)
## READ_FILE_TO_CELLSTR reads a given file line by line to a cellstring
fid = fopen (file, "r");
i = 1;
m_source{i} = fgetl (fid);
while (ischar (m_source{i}))
  i++;
  m_source{i} = fgetl (fid);
endwhile
fclose(fid);
m_source = cellstr (m_source(1:end-1)); ## No EOL
endfunction



function bool = is_head (line)
## IS_HEAD Checks line to be a section headline
bool = (! isempty (line)) ...
       && any (strncmp (line, {"%%", "##"}, 2)) ...
       && ((length (line) == 2) || (line(3) == " "));
endfunction



function bool = is_no_break_head (line)
## IS_NO_BREAK_HEAD Checks line to be a headline without section break
bool = (! isempty (line)) ...
       && any (strncmp (line, {"%%%", "###"}, 3)) ...
       && ((length (line) == 3) || (line(4) == " "));
endfunction



function bool = is_paragraph (line)
## IS_PARAGRAPH Checks line to be a paragraph line
bool = (! isempty (line)) ...
       && any (strcmp (line(1), {"%", "#"})) ...
       && ((length (line) == 1) || (line(2) == " "));
endfunction



function [p_source, doc_struct] = read_doc_head (p_source, doc_struct)
## READ_DOC_HEAD Reads the documents title and introduction text into the
##  document strucure.
##
##   p_source is a cellstring vector
##   doc is a document structure
##
## If a document title or introduction text was found, p_source is reduced
## by the already parsed lines and doc is modified in title and intro
## accordingly.  Otherwise the input and output arguments are identical.
##

## First line starting with "##" or "%%",
## followed by either a blank or end-of-line (no title)
ntitle = "";
if (isempty (p_source)
    || isempty (p_source{1})
    || ! is_head (p_source{1}))
  return;
elseif (length (p_source{1}) >= 2)
  ntitle = p_source{1};
endif

## Protect against only title documents
if (length (p_source) < 2)
  if (! isempty (ntitle))
    doc_struct.title = ntitle(4:end);
  endif
  p_source(1) = [];
  return;
endif

## Following lines are (0..N) intro lines ...
curr_line = 2;
while ((curr_line <= length(p_source)) ...
       && (is_paragraph (p_source{curr_line})))
  curr_line++;
endwhile
nintro = p_source(2:curr_line-1);

## ... and (0..M) blank lines ...
while ((curr_line <= length(p_source)) ...
       && (isempty (p_source{curr_line})))
  curr_line++;
endwhile

## .. until next section head
if ((curr_line <= length(p_source)) ...
    && ! (is_head (p_source{curr_line})
          || is_no_break_head (p_source{curr_line})))
  return;
endif

if (! isempty (ntitle))
  doc_struct.title = ntitle(4:end);
endif
for i = 1:length(nintro)
  if (! isempty (l = nintro{i}))
    doc_struct.intro = [doc_struct.intro, " ", l(3:end)];
  endif
endfor

## Strip parsed lines
p_source(1:curr_line-1) = [];
endfunction



function [p_source, doc_struct] = read_paragraph (p_source, doc_struct)
## READ_PARAGRAPH Reads a paragraph into the document strucure.
##
##   p_source is a cellstring vector
##   doc_struct is a document structure
##
## If a paragraph title or text was found, p_source is reduced by the already
## parsed lines and doc is modified in title and intro accordingly.
## Otherwise the input and output arguments are identical.
##

## First line starting with "##" or "%%",
## followed by either a blank or end-of-line (no title)
title_str = "";
no_break = false;
if (isempty (p_source{1})
    || ! (is_head (p_source{1}) || is_no_break_head (p_source{1})))
  return;
elseif ((is_head (p_source{1})) && (length (p_source{1}) > 2))
  title_str = p_source{1};
  title_str = title_str(4:end);
elseif ((is_no_break_head (p_source{1})) && (length (p_source{1}) > 3))
  title_str = p_source{1};
  title_str = title_str(5:end);
  no_break = true;
endif

## Following lines are (0..N) paragraph lines
curr_line = 2;
while ((curr_line <= length(p_source)) ...
       && (is_paragraph (l = p_source{curr_line})))
  p_source{curr_line} = l(3:end);
  curr_line++;
endwhile
content = p_source(2:curr_line-1);

if (! isempty (title_str) ...
    || ! (isempty (content) ...
          || all (cellfun (@isempty, content))))
  doc_struct.body{end + 1}.type = "paragraph";
  if (no_break)
    doc_struct.body{end}.type = "paragraph_no_break";
  endif
  doc_struct.body{end}.title = title_str;
  doc_struct.body{end}.content = content;
endif

## Strip parsed lines
p_source(1:curr_line-1) = [];
endfunction



function [p_source, doc_struct] = read_code (p_source, doc_struct)
## READ_CODE Reads code (or blank) lines from the document.
##
##   p_source is a cellstring vector
##   doc_struct is a document structure
##
## If code was found, p_source is reduced by the already parsed lines and
## doc_struct is appended by a code entry.  If no code was found, the input
## and output arguments are identical, except for any whitespace is removed
## up to the next section start.
##

curr_line = 1;
while ((curr_line <= length(p_source)) ...
       && ! is_head (p_source{curr_line}) ...
       && ! is_no_break_head (p_source{curr_line}))
  curr_line++;
endwhile

## Remove incipient blank lines
code_start = 1;
while ((code_start < curr_line) ...
       && isempty (p_source{code_start}))
  code_start++;
endwhile

## Remove trailing blank lines
code_end = curr_line-1;
while ((code_end >= 1) && isempty (p_source{code_end}))
  code_end--;
endwhile

## Extract code to evaluate
code_str = "";
for i = code_start:code_end
  code_str = [code_str, "\n", p_source{i}];
endfor

## Append code block
if (! isempty (code_str))
  doc_struct.body{end + 1}.type = "code";
  doc_struct.body{end}.code = strtrim(code_str);
  doc_struct.body{end}.output = [];
endif

## Strip parsed lines
p_source(1:curr_line-1) = [];
endfunction



function create_html (doc_struct, options)
html_head = ["<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"UTF-8\">\n", ...
  "<title>", doc_struct.title, "</title>\n", ...
  "<script type=\"text/javascript\" async ", ...
  "src=\"https://cdn.mathjax.org/mathjax/latest/MathJax.js", ...
  "?config=TeX-MML-AM_CHTML\">\n", ...
  "</script>\n</head>\n<body>\n"];

html_fmatter = "";
html_toc = "<h2>Contents</h2>\n<ul>\n";
if (! isempty (doc_struct.title))
  html_fmatter = ["<h1>", doc_struct.title, "</h1>\n"];
endif
if (! isempty (doc_struct.intro))
  html_fmatter = [html_fmatter, "<p>", doc_struct.intro, "</p>\n"];
endif

node_counter = 1;
html_content = "";
for i = 1:length(doc_struct.body)
  switch (doc_struct.body{i}.type)
    case "code"
      if (! isempty (doc_struct.body{i}.code))
        html_content = [html_content, "<pre class=\"oct-code\">", ...
          doc_struct.body{i}.code, "</pre>"];
      endif
      if (! isempty (doc_struct.body{i}.output))
        html_content = [html_content, "<pre class=\"oct-code\">", ...
          doc_struct.body{i}.output, "</pre>"];
      endif
    ## Note: Matlab R2016a treats both as new section heads
    case {"paragraph", "paragraph_no_break"}
      if (! isempty (doc_struct.body{i}.title))
        html_content = [html_content, "<h2><a name=\"node", ...
          num2str(node_counter), "\">", ...
          doc_struct.body{i}.title, "</a></h2>\n"];
        html_toc = [html_toc, "<li><a href=\"#node", ...
          num2str(node_counter), "\">", ...
          doc_struct.body{i}.title, "</a></li>\n"];
        node_counter++;
      endif
      for j = 1:length(doc_struct.body{i}.content)
        elem = doc_struct.body{i}.content{j};
        switch (elem.type)
          case "graphic"
            html_content = [html_content, "<img src=\"", ...
              elem.content, "\" alt=\"", ...
              elem.content, "\">\n"];
          case "include"
          case "octave_code"
            html_content = [html_content, "<pre class=\"pre-code\">", ...
              elem.content, "</pre>\n"];
          case "preformatted_text"
            html_content = [html_content, "<pre class=\"pre-text\">", ...
              elem.content, "</pre>\n"];
          case "numbered_list"
          case "bulleted_list"
          case "text"
            str = elem.content;
            ## Bold
            str = strsplit (str, "*");
            for k = 2:2:length(str)
              str{k} = ["<b>", str{k}, "</b>"];
            endfor
            str = strjoin (str, "");
            ## Italic
            str = strsplit (str, "_");
            for k = 2:2:length(str)
              str{k} = ["<i>", str{k}, "</i>"];
            endfor
            str = strjoin (str, "");
            ## Monospaced
            str = strsplit (str, "|");
            for k = 2:2:length(str)
              str{k} = ["<code>", str{k}, "</code>"];
            endfor
            str = strjoin (str, "");
            ## Replace special symbols
            str = strrep (str, "(TM)", "&trade;");
            str = strrep (str, "(R)", "&reg;");
            html_content = [html_content, str, "\n"];
          case "html"
            html_content = [html_content, elem.content, "\n"];
        endswitch
      endfor
  endswitch
endfor

html_toc = [html_toc, "</ul>\n"];
html_content = [html_fmatter, html_toc, html_content];

html_foot = ["\n", ...
  "<footer>Published with GNU Octave ", version(), "</footer>\n", ...
  "<!--\n##### SOURCE BEGIN #####\n", ...
  strjoin(doc_struct.m_source, "\n"), ...
  "\n##### SOURCE END #####\n-->\n", ...
  "</body>\n</html>\n"];

  fid = fopen ("bla.html", "w");
  fputs (fid, [html_head, html_content, html_foot]);
  fclose (fid);

endfunction

function create_latex (ifile, ofile, options)
  latex_preamble = "\
\\documentclass[a4paper,12pt]{article}\n\
\\usepackage{listings}\n\
\\usepackage{graphicx}\n\
\\usepackage{color}\n\
\\usepackage[T1]{fontenc}\n\
\\definecolor{lightgray}{rgb}{0.9,0.9,0.9}\n";

  listing_source_option = "\
\\lstset{\n\
language = Octave,\n\
basicstyle =\\footnotesize,\n\
numbers = left,\n\
numberstyle = \\footnotesize,\n\
backgroundcolor=\\color{lightgray},\n\
frame=single,\n\
tabsize=2,\n\
breaklines=true}\n";

  listing_exec_option = "\
\\lstset{\n\
language = Octave,\n\
basicstyle =\\footnotesize,\n\
numbers = none,\n\
backgroundcolor=\\color{white},\n\
frame=none,\n\
tabsize=2,\n\
breaklines=true}\n";

  if options.showCode
    section1_title = strcat ("\\section*{Source code: \\texttt{", ifile, "}}\n");
    source_code    = strcat ("\\lstinputlisting{", ifile, "}\n");
  else
    section1_title = "";
    source_code    = "";
  endif
  
  if options.evalCode
    section2_title = "\\section*{Execution results}\n";
    oct_command    = strcat ("octave> ", ifile(1:end-2), "\n");
    script_result = exec_script (ifile);
  else
    section2_title = "";
    oct_command    = "";
    script_result  = "";
  endif

  [section3_title, disp_fig] = exec_print (ifile, options);

  final_document = strcat (latex_preamble, listing_source_option, 
                           "\\begin{document}\n", 
                           section1_title, source_code, 
                           section2_title, listing_exec_option,
                           "\\begin{lstlisting}\n",
                           oct_command, script_result,
                           "\\end{lstlisting}\n",
                           section3_title,
                           "\\begin{center}\n",
                           disp_fig,
                           "\\end{center}\n",
                           "\\end{document}");

  fid = fopen (ofile, "w");
  fputs(fid, final_document);
  fclose(fid);
endfunction



function ___cstr___ = eval_code (___code___);
## EVAL_CODE evaluates a given string with Octave code in an extra
##   temporary context and returns a cellstring with the eval output

## TODO: potential conflicting variables sourrounded by "___"
##       better solution?
## TODO: suppres any eval output
persistent ___context___ = [tempname(), ".mat"];
if (isempty (___code___))
  return;
endif

if (exist (___context___, "file") == 2)
  load (___context___);
endif
___f___ = tempname ();
diary (___f___)
eval (___code___);
diary off
___cstr___ = read_file_to_cellstr (___f___);
unlink (___f___);
clear ___code___ ___f___
save (___context___);
endfunction



function [section3_title, disp_fig] = exec_print (ifile, options)
  figures = findall (0, "type", "figure");
  section3_title = "";
  disp_fig       = "";
  if (!isempty (figures))
    for nfig = 1:length (figures)
      figure (figures(nfig));
      print (sprintf ("%s%d.%s", ifile(1:end-2), nfig, options.imageFormat),
             sprintf ("-d%s", options.imageFormat), "-color");
      if (strcmpi (options.format, "html"));
        section3_title = "<h2>Generated graphics</h2>\n";
        disp_fig = strcat (disp_fig, "<img src=\"", ifile(1:end-2), 
                           sprintf ("%d", nfig), ".", options.imageFormat, "\"/>");
      elseif (strcmpi (options.format, "latex"))
        section3_title = "\\section*{Generated graphics}\n";
        disp_fig = strcat (disp_fig, "\\includegraphics[scale=0.6]{", ifile(1:end-2), 
                           sprintf("%d",nfig), "}\n");
      endif
    endfor
  endif
endfunction

%!test
%! cases = dir ("test_script*.m");
%! cases = strsplit (strrep ([cases.name], ".m", ".m\n"));
%! for i = 1:length(cases)-1
%!   publish (cases{i});
%! endfor