# text2pdf2
An enhanced version of text2pdf, as in the PDF::API2 perl module at https://cpan.org

# Existing Features

# Features when initially donated to PDF::API2
# M Collins - mcollins@fcnetwork.com

A font could be named in the code.
Multiple text files could be converted to PDF.
One line in the text file was one line in the PDF file.
The output files were pdf files that printed the same as the text files,
  but with the specified font.
  
# Hank Ivy - hankivy@hankivy.com

1. Added changing the font, and size via a command line in the text file.
2. Added inserting a centered image into the PDF via a command line in the text file.
3. Added centering the text.
4. Added a debug switch to output status messages.
5. Added font name, font size as a command line parameter.
6. Added diagnostic tests for the command line parameters.
7. Improved documentation.
8. Removed, or commented out deprecated code.

--- This was donated and added to the PDF::API2 perl module

# Later Forks
# Features added by Phil M Perry in the PDF::Builder module

# Revision: by Phil M Perry  March 2017
1. cleanup: remove deprecated and commented-out old stuff  (HI deprecated PERL syntactical features)
2. diagnostic/debug print statements under "debug" control --debug
3. restructured command line parameter handling, and input is now positional
     with multiple file names or globs on command line
4. add named paper size --PGpaper=name
5. allow dimensions to have units (default units unchanged)
6. .PAGE=minsize;  if more space left, don't paginate
7.  --tabs="t1 t2 t3...tn"  default 9 17 25 33...  tab stops
8.  wrap lines that don't fit, so they don't just run off right side
9.  page numbering, file name each page

# Additional Features added by Hank Ivy (separate from Phill Perry's development)

1. Correct font name defect for specials like bold, italic, etc.
2. Add oblique to font styles.
3. Added diagnostic option --PrintControl to print FONT control line to PDF file.
4. Added subroutine newline.
    Changed code to use newline as needed.
    Adjusted code line lengths for readability.
5. Ran perltidy for readability.
6. Add RunMessages command line option. (Diagnostic to report code execution details.)
7. Enhance documentation on changing styles.
8. Document RunMessages command line option.
9. Changed number pattern for numeric parameters.
10. Corrected the use of the diagnostic parameter, RunMessages.
11. Added documentation on styles.
12. Changed Core Type font from C to CN, or CS.
13. Fixed defect in font name parameter pattern matching to allow hyphens in a font name.
14. Added exit 0 for the normal end of execution.
15. Updated documentation to reflect changes.
16. Added Font Directory search subroutine.
17. Added Font Directory parameter.
18. Added debugging feature for the Font Directory search support.
19. Added support for True Type fonts.
20. Added support for synthetic True Type fonts.
21. Added WarnWithPDF subroutine that duplicates warn messages to both ERROUT, and the PDF file.
22. Added ToDo list to code.
23. Consistent use of CS for core fonts.
24. Drop code for synthetic true type fonts. Leave it for future.
25. Drop support currently for Post Script fonts. Leave it for future.
26. Corrected use of __ FILE __ in messages.
27. Use parameter rather than the global $_ in the newline subroutine.
28. Check for new page, and process in the newline subroutine.
29. Add functionality to list the font directories as commanded in the input file.
30. Add functionality to add a directory to the font search directories as commanded in the input file.
31. Provide SRC root path of an image file as relative to the source text file.
32. Allow aspect ratio to set missing WIDTH or HEIGHT parm of image file.
33. Move code to test for page break caused by the image file.
34. Move internal diagnostic flags to CLI parameters.
35. Add CLI diagnostic parameters to usage statement.



# Road Map
1. Start with Hank Ivy's code fork.
2. Add Phil M Perry's feature set.
2a. Convert to PDF::Builder.
2b. Document Testing procedure.
2c. etc.

# New Features

