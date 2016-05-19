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
  ## Matlab R2016a doc says default is "", but specifies to create a sub
  ## directory named "html" in the current working directory.
  options.outputDir = "html";
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

doc_struct.title = "";
doc_struct.intro = "";
doc_struct.body = cell ();
doc_struct.m_source = deblank (read_file_to_cellstr (file));
doc_struct.m_source_file_name = file;

## Split code and paragraphs, find formatting
doc_struct = parse_m_source (doc_struct);

## Create output directory
[mkdir_stat, mkdir_msg] = mkdir (options.outputDir);
if (mkdir_stat != 1)
  error ("publish: cannot create output directory. %s", mkdir_msg);
endif

if (options.evalCode)
  doc_struct = eval_code (doc_struct, options);
endif

out_file = create_output (doc_struct, options);

endfunction



function doc_struct = parse_m_source (doc_struct)
## PARSE_M_SOURCE First parsing level
##   This function extracts the overall structure (paragraphs and code
##   sections) given in doc_struct.m_source.
##
##   The result is written to doc_struct.body, which then contains a cell
##   vector of structs, either of
##
##     a) {struct ("type", "code", ...
##                 "lines", [a, b], ...
##                 "output", [])}
##     b) {struct ("type", "section", ...
##                 "content", title_str)}
##     c) {struct ("type", "section_no_break", ...
##                 "content", title_str)}
##
##   Second parsing level is invoked for the paragraph contents, resulting
##   in more elements for doc_struct.body.
##

## If there is nothing to parse
if (isempty (doc_struct.m_source))
  return;
endif

## Parsing helper functions
##
## Checks line to have N "%" or "#" lines
## followed either by a space or is end of string
is_publish_markup = @(cstr, N) ...
  any (strncmp (char (cstr), {"%%%", "###"}, N)) ...
  && ((length (char (cstr)) == N) || ((char (cstr))(N + 1) == " "));
## Checks line of cellstring to be a paragraph line
is_paragraph = @(cstr) is_publish_markup (cstr, 1);
## Checks line of cellstring to be a section headline
is_head = @(cstr) is_publish_markup (cstr, 2);
## Checks line of cellstring to be a headline without section break
is_no_break_head = @(cstr) is_publish_markup (cstr, 3);

## Find the indices of paragraphs starting with "%%", "##", "%%%", or "###"
par_start_idx = find ( ...
  cellfun (is_head, doc_struct.m_source) ...
  | cellfun (is_no_break_head, doc_struct.m_source));

## If the whole document is code
if (isempty (par_start_idx))
  doc_struct.body{end + 1}.type = "code";
  doc_struct.body{end}.lines = [1, length(doc_struct.m_source)];
  doc_struct.body{end}.output = [];
  return;
endif

## Determine continuous range of paragraphs
par_end_idx = [par_start_idx(2:end) - 1, length(doc_struct.m_source)];
for i = 1:length(par_end_idx)
  idx = find (! cellfun (is_paragraph, ...
                  doc_struct.m_source(par_start_idx(i) + 1:par_end_idx(i))));
  if (! isempty (idx))
    par_end_idx(i) = par_start_idx(i) + idx(1) - 1;
  endif
endfor
## Code sections between paragraphs
code_start_idx = par_end_idx(1:end - 1) + 1;
code_end_idx = par_start_idx(2:end) - 1;
## Code at the beginning?
if (par_start_idx(1) > 1)
  code_start_idx = [1, code_start_idx];
  code_end_idx = [par_start_idx(1) - 1, code_end_idx];
endif
## Code at the end?
if (par_end_idx(end) < length (doc_struct.m_source))
  code_start_idx = [code_start_idx, par_end_idx(end) + 1];
  code_end_idx = [code_end_idx, length(doc_struct.m_source)];
endif
## Remove overlaps
idx = code_start_idx > code_end_idx;
code_start_idx(idx) = [];
code_end_idx(idx) = [];
## Remove empty code blocks
idx = [];
for i = 1:length(code_start_idx)
  if (all (cellfun (@(cstr) isempty (char (cstr)), ...
                    doc_struct.m_source(code_start_idx(i):code_end_idx(i)))))
    idx = [idx, i];
  endif
endfor
code_start_idx(idx) = [];
code_end_idx(idx) = [];

## Try to find a document title and introduction text
##   1. First paragraph must start in first line
##   2. Second paragraph must start before any code
title_offset = 0;
# TODO: is_head??
if ((! isempty (par_start_idx)) && (par_start_idx(1) == 1) ...
    && ((isempty (code_start_idx))
        || ((length (par_start_idx) > 1)
            && (par_start_idx(2) < code_start_idx(1)))))
  doc_struct.title = doc_struct.m_source{1};
  doc_struct.title = doc_struct.title(4:end);
  content = doc_struct.m_source(2:par_end_idx(1));
  ## Strip leading "# "
  content = cellfun(@(c) cellstr (c(3:end)), content);
  doc_struct.intro = parse_paragraph_content (content);
  title_offset = 1;
endif

## Add non-empty paragraphs and code to doc_struct
j = 1;
for i = (1 + title_offset):length(par_start_idx)
  ## Add code first
  while ((j <= length(code_start_idx))
    && (par_start_idx(i) > code_start_idx(j)))
    doc_struct.body{end + 1}.type = "code";
    doc_struct.body{end}.lines = [code_start_idx(j), code_end_idx(j)];
    doc_struct.body{end}.output = [];
    j++;
  endwhile

  type_str = "section";
  title_str = doc_struct.m_source{par_start_idx(i)};
  if (is_head (doc_struct.m_source(par_start_idx(i))))
    title_str = title_str(4:end);
  else
    type_str = "section_no_break";
    title_str = title_str(5:end);
  endif
  ## Append, if paragraph title is given
  if (! isempty (title_str))
    doc_struct.body{end + 1}.type = type_str;
    doc_struct.body{end}.content = title_str;
  endif

  content = doc_struct.m_source(par_start_idx(i) + 1:par_end_idx(i));
  ## Strip leading "# "
  content = cellfun(@(c) cellstr (c(3:end)), content);
  doc_struct.body = [doc_struct.body, parse_paragraph_content(content)];
endfor

endfunction



function [p_content] = parse_paragraph_content (content)
## PARSE_PARAGRAPH_CONTENT second parsing level
##
##   Parses the content of a paragraph (without potential title) and
##   returns a cell vector of structs, that can be appended to
##   doc_struct.body, either of
##
##     a) {struct ("type", "preformatted_code", ...
##                 "content", code_str)}
##     b) {struct ("type", "preformatted_text", ...
##                 "content", text_str)}
##     c) {struct ("type", "bulleted_list", ...
##                 "content", {"item1", "item2", ..})}
##     d) {struct ("type", "numbered_list", ...
##                 "content", {"item1", "item2", ..})}
##     e) {struct ("type", "include", ...
##                 "content", file_str)}
##     f) {struct ("type", "graphic", ...
##                 "content", file_str)}
##     g) {struct ("type", "html", ...
##                 "content", html_str)}
##     h) {struct ("type", "latex", ...
##                 "content", latex_str)}
##     i) {struct ("type", "text", ...
##                 "content", text_str)}
##
##   Option i) might contain:
##
##     * Italic "_", bold "*", and monospaced "|" text
##     * Inline "$" and block "$$" LaTeX math
##     * Links
##     * Trademark symbols
##

p_content = cell ();

if (isempty (content))
  return;
endif

## Split into blocks seperated by empty lines
idx = [0, find(cellfun (@isempty, content)), length(content) + 1];
## For each block
for i = find (diff(idx) > 1)
  block = content(idx(i) + 1:idx(i+1) - 1);

  ## Octave code (two leading spaces)
  if (all (cellfun (@(c) strncmp (char (c), "  ", 2), block)))
    p_content{end+1}.type = "preformatted_code";
    block = cellfun(@(c) cellstr (c(3:end)), block);
    p_content{end}.content = strjoin (block, "\n");
    continue;
  endif

  ## Preformatted text (one leading space)
  if (all (cellfun (@(c) strncmp (char (c), " ", 1), block)))
    p_content{end+1}.type = "preformatted_text";
    block = cellfun(@(c) cellstr (c(2:end)), block);
    p_content{end}.content = strjoin (block, "\n");
    continue;
  endif

  ## Bulleted list starts with "* "
  if (strncmp (block{1}, "* ", 2))
    p_content{end+1}.type = "bulleted_list";
    p_content{end}.content = strjoin (block, "\n");
    ## Revove first "* "
    p_content{end}.content = p_content{end}.content(3:end);
    ## Split items
    p_content{end}.content = strsplit (p_content{end}.content, "\n* ");
    continue;
  endif

  ## Numbered list starts with "# "
  if (strncmp (block{1}, "# ", 2))
    p_content{end+1}.type = "numbered_list";
    p_content{end}.content = strjoin (block, "\n");
    ## Revove first "# "
    p_content{end}.content = p_content{end}.content(3:end);
    ## Split items
    p_content{end}.content = strsplit (p_content{end}.content, "\n# ");
    continue;
  endif

  ## Include <include>fname.m</include>
  if (! isempty ([~,~,~,~,fname] = regexpi (strjoin (block, ""), ...
                                            '^<include>(.*)<\/include>$')))
    p_content{end+1}.type = "include";
    p_content{end}.content = strtrim ((fname{1}){1});
    continue;
  endif
  
  ## Graphic <<myGraphic.png>>
  if (! isempty ([~,~,~,~,fname] = regexpi (strjoin (block, ""), ...
                                            '^<<(.*)>>$')))
    p_content{end+1}.type = "graphic";
    p_content{end}.content = strtrim ((fname{1}){1});
    continue;
  endif

  ## Parse remaining blocks line by line
  j = 1;
  while (j <= length(block))
    ## HTML markup
    if (strcmpi (block{j}, "<html>"))
      start_html = j + 1;
      while ((j < length(block)) && ! strcmpi (block{j}, "</html>"))
        j++;
      endwhile
      if ((j == length(block)) && ! strcmpi (block{j}, "</html>"))
        warning ("publish: no closing </html> found");
      else
        j++;  ## Skip closing tag
      endif
      if (j > start_html)
        p_content{end+1}.type = "html";
        p_content{end}.content = strjoin (block(start_html:j-2), "\n");
      endif
    ## LaTeX markup
    elseif (strcmpi (block{j}, "<latex>"))
      start_latex = j + 1;
      while ((j < length(block)) && ! strcmpi (block{j}, "</latex>"))
        j++;
      endwhile
      if ((j == length(block)) && ! strcmpi (block{j}, "</latex>"))
        warning ("publish: no closing </latex> found");
      else
        j++;  ## Skrip closing tag
      endif
      if (j > start_latex)
        p_content{end+1}.type = "latex";
        p_content{end}.content = strjoin (block(start_latex:j-2), "\n");
      endif
    ## Remaining normal text or markups belonging to normal text
    ## that are handled while output generation:
    ##
    ## * Italic "_", bold "*", and monospaced "|" text
    ## * Inline "$" and block "$$" LaTeX math
    ## * Links
    ## * Trademark symbols
    ##
    else
      if ((j == 1) || isempty (p_content) ...
          || ! strcmp (p_content{end}.type, "text"))
        p_content{end+1}.type = "text";
        p_content{end}.content = block{j};
      else
        p_content{end}.content = strjoin ({p_content{end}.content, ...
                                           block{j}}, "\n");
      endif
      j++;
    endif
  endwhile
endfor

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



function ofile = create_output (doc_struct, options)
formatter = [];
switch (options.format)
  case "html"
    formatter = @__publish_html_output__;
    ## Reset HTML toc counter
    formatter ("init", doc_struct);
  case "latex"
    formatter = @__publish_latex_output__;
endswitch

content = formatter ("header", doc_struct);

html_fmatter = "";
html_toc = "<h2>Contents</h2>\n<ul>\n";
if (! isempty (doc_struct.title))
  html_fmatter = ["<h1>", doc_struct.title, "</h1>\n"];
else
  html_fmatter = ["<h1>", doc_struct.m_source_file_name, "</h1>\n"];
endif
if (! isempty (doc_struct.intro))
  for i = 1:length(doc_struct.intro)
    html_fmatter = [html_fmatter, "<p>", doc_struct.intro{i}.content, ...
      "</p>\n"];
  endfor
endif

html_content = "";
for i = 1:length(doc_struct.body)
  switch (doc_struct.body{i}.type)
    case "code"
      if (options.showCode)
        r = doc_struct.body{i}.lines;
        code_str = strtrim (strjoin (doc_struct.m_source(r(1):r(2)), "\n"));
        html_content = [html_content, "<pre class=\"oct-code\">", ...
          code_str, "</pre>"];
      endif
      if (! isempty (doc_struct.body{i}.output))
        html_content = [html_content, "<pre class=\"oct-code\">", ...
          doc_struct.body{i}.output, "</pre>"];
      endif
    ## Note: Matlab R2016a treats both as new section heads
    case {"section", "section_no_break"}
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
          case "preformatted_code"
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
            str2 = regexprep(str,'\*([\w]*)\*', "<b>$1</b>");
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



function doc_struct = eval_code (doc_struct, options)
## EVAL_CODE Thrid level parsing
##
##   Generates the output of the script code and takes care of generated
##   figures.
##

## Neccessary as the code does not run interactively
page_screen_output (0, "local");

## Remember previously opened figures
fig_ids = findall (0, "type", "figure");
[~,fig_name] = fileparts (doc_struct.m_source_file_name);
fig_num = 1;
fig_list = struct ();

## Evaluate code, that does not appear in the output.
eval_code_helper (options.codeToEvaluate);

## Create a new figure, if there are existing plots
if (! isempty (fig_ids) && options.useNewFigure)
  figure ();
endif

for i = 1:length(doc_struct.body)
  if (strcmp (doc_struct.body{i}.type, "code"))
    r = doc_struct.body{i}.lines;
    code_str = strjoin (doc_struct.m_source(r(1):r(2)), "\n");
    if (options.catchError)
      try
        doc_struct.body{i}.output = eval_code_helper (code_str);
       catch err
        doc_struct.body{i}.output = ["error: ", err.message, ...
          "\n\tin:\n\n", doc_struct.body{i}.code];
      end_try_catch
    else
      doc_struct.body{i}.output = eval_code_helper (code_str);
    endif

    ## Check for newly created figures ...
    fig_ids_new = setdiff (findall (0, "type", "figure"), fig_ids);
    ## ... and save them
    for j = 1:length(fig_ids_new)
      drawnow ();
      if (isempty (get (fig_ids_new(j), "children")))
        continue;
      endif
      fname = [fig_name, "-", num2str(fig_num), ".", options.imageFormat];
      print (fig_ids_new(j), [options.outputDir, filesep(), fname], ...
        ["-d", options.imageFormat], "-color");
      fig_num++;
      delete (fig_ids_new(j));
      fname = {fname};
      if (isfield (fig_list, num2str (i)))
        fname = [getfield(fig_list, num2str (i)), fname];
      endif
      fig_list = setfield (fig_list, num2str (i), fname);
      ## Create a new figure, if there are existing plots
      if (isempty (setdiff (findall (0, "type", "figure"), fig_ids)) ...
          &&! isempty (fig_ids) && options.useNewFigure)
        figure ();
      endif
    endfor

    ## Truncate output to desired length
    if (options.maxOutputLines < length (doc_struct.body{i}.output))
      doc_struct.body{i}.output = ...
        doc_struct.body{i}.output(1:options.maxOutputLines);
    endif
    doc_struct.body{i}.output = strjoin (doc_struct.body{i}.output, "\n");
  endif
endfor

## Close any by publish opened figures
delete (setdiff (findall (0, "type", "figure"), fig_ids));

## Insert figures to document
fig_code_blocks = fieldnames (fig_list);
for i = 1:length(fig_code_blocks)
  elem.type = "section";
  elem.title = "";
  fnames = getfield (fig_list, fig_code_blocks{i});
  for j = 1:length(fnames)
    elem.content{j} = struct ("type", "graphic", "content", fnames{j});
  endfor
  ## Compute index, where the figure(s) has to be inserterd,
  ## changes with i!
  j = str2num (fig_code_blocks{i}) + i - 1;
  doc_struct.body = [doc_struct.body(1:j), elem, doc_struct.body(j+1:end)];
  elem = [];
endfor

endfunction



function ___cstr___ = eval_code_helper (___code___);
## EVAL_CODE_HELPER evaluates a given string with Octave code in an extra
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



%!test
%! cases = dir ("test_script*.m");
%! cases = strsplit (strrep ([cases.name], ".m", ".m\n"));
%! for i = 1:length(cases)-1
%!   publish (cases{i});
%! endfor