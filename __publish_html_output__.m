function outstr = __publish_html_output__ (type, val)
persistent toc = cellstr ();
##
## Types to handle are:
##
## * "code"
## * "section"
## * "section_no_break"
## * "preformatted_code"
## * "preformatted_text"
## * "bulleted_list"
## * "numbered_list"
## * "include"
## * "graphic"
## * "html"
## * "latex"
## * "text"
## * "italic"
## * "bold"
## * "link"
## * "TM"
## * "R"
##
## Special types are
##
## * "header"
## * "footer"
##
switch (nargin)
  case "init"
    for i = 1:length(val.body)
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
  otherwise
    eval (["outstr = handle_", type, " (val);"]);
endswitch
endfunction

function outstr = handle_header (doc_struct)
outstr = ["<!DOCTYPE html>\n", ...
  "<html>\n", ...
  "<head>\n", ...
  "<meta charset=\"UTF-8\">\n", ...
  "<title>", doc_struct.title, "</title>\n", ...
  "<script type=\"text/javascript\" async ", ...
  "src=\"https://cdn.mathjax.org/mathjax/latest/MathJax.js", ...
  "?config=TeX-MML-AM_CHTML\">\n", ...
  "</script>\n", ...
  "</head>\n", ...
  "<body>\n"];
## Reset section counter
handle_section ();
endfunction

function outstr = handle_code (str)
outstr = ["<pre class=\"oct-code\">", str, "</pre>"];
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
outstr = handle_section (str)
endfunction

function outstr = handle_text (str)
outstr = ["<p>", str, "</p>"];
endfunction
