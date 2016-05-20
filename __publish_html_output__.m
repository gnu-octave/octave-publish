function outstr = __publish_html_output__ (varargin)
  ##
  ## Types to handle are:
  ##
  ## * "header" (title_str, intro_str, toc_cstr)
  ## * "footer" ()
  ## * "code" (str)
  ## * "code_output" (str)
  ## * "section" (str)
  ## * "section_no_break" (str)
  ## * "preformatted_code" (str)
  ## * "preformatted_text" (str)
  ## * "bulleted_list" (cstr)
  ## * "numbered_list" (cstr)
  ## TODO: * "include" (str)
  ## * "graphic" (str)
  ## * "html" (str)
  ## * "latex" (str)
  ## * "text" (str)
  ## * "bold" (str)
  ## * "italic" (str)
  ## * "monospaced" (str)
  ## * "link" (url_str, url_str, str)
  ## * "TM" ()
  ## * "R" ()
  ##
  eval (["outstr = handle_", varargin{1}, " (varargin{2:end});"]);
endfunction

function outstr = handle_include ()
  outstr = ""; ##TODO
endfunction

function outstr = handle_header (title_str, intro_str, toc_cstr)
  outstr = ["<!DOCTYPE html>\n", ...
    "<html>\n", ...
    "<head>\n", ...
    "<meta charset=\"UTF-8\">\n", ...
    "<title>", title_str, "</title>\n", ...
    "<script type=\"text/javascript\" async ", ...
    "src=\"https://cdn.mathjax.org/mathjax/latest/MathJax.js", ...
    "?config=TeX-MML-AM_CHTML\">\n", ...
    "</script>\n", ...
    "</head>\n", ...
    "<body>\n", ...
    "<h1>", title_str, "</h1>\n", ...
    intro_str];

  if (! isempty (toc_cstr))
    ## TODO
  endif

  ## Reset section counter
  handle_section ();
endfunction

function outstr = handle_footer (m_source_str)
  outstr = ["\n", ...
    "<footer>Published with GNU Octave ", version(), "</footer>\n", ...
    "<!--\n", ...
    "##### SOURCE BEGIN #####\n", ...
    m_source_str, ...
    "\n##### SOURCE END #####\n", ...
    "-->\n", ...
    "</body>\n", ...
    "</html>\n"];
endfunction

function outstr = handle_code (str)
  outstr = ["<pre class=\"oct-code\">", str, "</pre>"];
endfunction

function outstr = handle_code_output (str)
  outstr = ["<pre class=\"oct-code-output\">", str, "</pre>"];
endfunction

function outstr = handle_section (varargin)
  persistent counter = 1;
  if (nargin == 0)
    counter = 1;
    outstr = "";
    return;
  endif
  outstr = ["<h2><a name=\"node", num2str(counter), "\">", varargin{1}, ...
    "</a></h2>"];
  counter++;
endfunction

function outstr = handle_section_no_break (str)
  ## Note: Matlab R2016a treats both as new section heads
  outstr = handle_section (str);
endfunction

function outstr = handle_preformatted_code (str)
  outstr = ["<pre class=\"pre-code\">", str, "</pre>"];
endfunction

function outstr = handle_preformatted_text (str)
  outstr = ["<pre class=\"pre-text\">", str, "</pre>"];
endfunction

function outstr = handle_bulleted_list (cstr)
  outstr = "<ul>";
  for i = 1:length(cstr)
    outstr = [outstr, "<li>", cstr{i}, "</li>"];
  endfor
  outstr = [outstr, "</ul>"];
endfunction

function outstr = handle_numbered_list (cstr)
  outstr = "<ol>";
  for i = 1:length(cstr)
    outstr = [outstr, "<li>", cstr{i}, "</li>"];
  endfor
  outstr = [outstr, "</ol>"];
endfunction

function outstr = handle_graphic (str)
  outstr = ["<img src=\"", str,"\" alt=\"", str, "\">"];
endfunction

function outstr = handle_html (str)
  outstr = str;
endfunction

function outstr = handle_latex (str)
  outstr = "";
endfunction

function outstr = handle_link (url_str, str)
  outstr = ["<a href=\"", url_str,"\">", str, "</a>"];
endfunction

function outstr = handle_text (str)
  outstr = ["<p>", str, "</p>"];
endfunction

function outstr = handle_bold (str)
  outstr = ["<b>", str, "</b>"];
endfunction

function outstr = handle_italic (str)
  outstr = ["<i>", str, "</i>"];
endfunction

function outstr = handle_monospaced (str)
  outstr = ["<code>", str, "</code>"];
endfunction

function outstr = handle_TM ()
  outstr = "&trade;";
endfunction

function outstr = handle_R ()
  outstr = "&reg;";
endfunction
