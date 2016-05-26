function varargout = grabcode (url)
  narginchk (1, 1);
  nargoutchk (0, 1);

  [~,~,ext] = fileparts (url);
  if (! strncmp (ext, ".htm", 4))
    error ("grabcode: URL should point to a published \".html\"-file");
  endif

  ## If url is a local file
  if (exist (url) == 2)
    oct_code = fileread (url);
  ## Otherwise try to read a url
  else
    [oct_code, success, message] = urlread (url);
    if (! success)
      error (["grabcode: ", message]);
    endif
  endif

  ## Extract relevant part
  start_str = "##### SOURCE BEGIN #####";
  end_str = "##### SOURCE END #####";
  oct_code = oct_code(strfind (oct_code, start_str) + length(start_str) + 1: ...
    strfind (oct_code, end_str)-1);

  ## Return Octave code string ...
  if (nargout == 1)
    varargout{1} = ooct_code;
  ## ... or open temporary file in editor
  else
    fname = tempname ();
    fid = fopen (fname, "w");
    if (fid < 0)
      error ("grabcode: cannot open temporary file");
    endif
    fprintf (fid, "%s", oct_code);
    fclose (fid);
    warning (["grabcode: created temporary file '", fname, ...
      "' make sure to 'Save File As' a document of your choice.",
      " Otherwise all code will be lost!"]);
    edit (fname);
  endif
endfunction

%!test
%! grabcode ("html/test_script.html")