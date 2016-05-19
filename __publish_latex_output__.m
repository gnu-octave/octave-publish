function outstr = __publish_latex_output__ (type, str)
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