#!/usr/bin/perl
#
# RCS Comments.
# $Author: hank $
# $Date: 2018/10/24 03:50:18 $
# $RCSfile: text2pdf.pl,v $
# $Revision: 1.19 $
# $Source: /home/hank/bin/RCS/text2pdf.pl,v $
# $Header: /home/hank/bin/RCS/text2pdf.pl,v 1.19 2018/10/24 03:50:18 hank Exp hank $
# $Id: text2pdf.pl,v 1.19 2018/10/24 03:50:18 hank Exp hank $
# $Log: text2pdf.pl,v $
# Revision 1.19  2018/10/24 03:50:18  hank
# Move internal diagnostic flags to CLI parameters.
# Add CLI diagnostic parameters to usage statement.
#
# Revision 1.18  2018/10/24 00:52:53  hank
# Provide SRC root path of an image file as relative to the source text file.
# Allow aspect ratio to set missing WIDTH or HEIGHT parm of image file.
# Move code to test for page break caused by the image file.
#
# Revision 1.17  2018/10/09 21:17:57  hank
# Use parameter rather than the global $_ in the newline subroutine.
# Check for new page, and process in the newline subroutine.
# Add functionality to list the font directories as commanded in the input file.
# Add functionality to add a directory to the font search directories.
# as commanded in the input file.
#
# Revision 1.16  2018/10/09 02:37:15  hank
# Added ToDo list to code.
# Consistent use of CS for core fonts.
# Drop code for synthetic true type fonts.
# Drop support currently for Post Script fonts. Leave it for future.
# Corrected use of __ FILE __ in message.
#
# Revision 1.15  2018/09/25 00:44:44  hank
# Added Font Directory search subroutine.
# Added Font Directory parameter.
# Added debugging feature for the Font Directory search support.
# Added support for True Type fonts.
# Added support for synthetic True Type fonts.
# Added WarnWithPDF subroutine that duplicates
#   warn messages to both ERROUT, and the PDF file.
#
# Revision 1.14  2018/09/16 02:48:24  hank
# Changed Core Type font from C to CN, or CS.
# Fixed defect in font name parameter pattern matching to allow 
#  hyphens in a font name.
# Added exit 0 for the normal end of execution.
# Updated documentation to reflect changes.
#
# Revision 1.13  2018/09/01 21:28:26  hank
# Changed number pattern for numeric parameters.
# Corrected the use of the diagnostic parameter, RunMessages.
# Added documentation on styles.
#
# Revision 1.12  2018/08/31 21:08:22  hank
# Add RunMessages command line option.
# Enhance documentation on changing styles.
# Document RunMessages command line option.
#
# Revision 1.11  2018/08/30 18:39:42  hank
# Ran perltidy for readability.
#
# Revision 1.10  2018/08/30 18:35:58  hank
# Added subroutine newline.
# Changed code to use newline as needed.
# Adjusted line lengths for readability.
#
# Revision 1.9  2018/08/30 17:44:47  hank
# Added diagnostic option --PrintControl to print FONT control line.
# Fixed minor syntax issues.
#
# Revision 1.8  2018/08/29 15:32:44  hank
# Add oblique to font styles.
#
# Revision 1.7  2018/08/23 03:35:52  hank
# Correct font specials like bold, italic, etc.
#
# Revision 1.6  2013/08/14 20:26:56  hank
# Improved documentation.
# Removed, or commented out deprecated code.
#
# Revision 1.5  2013/07/20 02:30:41  hank
# Add font name, font size, as parameters to the command line.
# Add tests to validate the new parameters.
#
# Revision 1.4  2013/06/11 03:42:28  hank
# Add debug switch for status messages.
#
# Revision 1.3  2013/06/10 23:05:28  hank
# Added centering.
#
# Revision 1.2  2013/06/08 03:54:23  hank
# Add changing fonts, sizes, and pictures.
#
# Revision 1.1  2013/05/30 20:31:54  hank
# Initial revision
#
#
#
# txt2pdf.pl from mcollins@fcnetwork.com
#
# MC's Q&D text to PDF converter.
#
# FYI,
#
# I wrote a simple text file to PDF converter that uses PDF::API2::Lite.
# It isn't full-featured by any stretch but it does illustrate one of the
# many uses of this cool module.  I'm submitting it here for your perusal.
# If you think of any useful things to add to it please let me know.
# Fredo, please feel free to include it in the contributed items if you
# would like.
#
# Thanks!  (Sorry about the long comments that wrap around to the next
# line...)
#
# -MC
#

# TODO List
# 3. in file, Add dir. to font search.
# 4. in file, Add list font search dirs.
# X 1. Consistent use of CS for core fonts, in code and documentation.
# 2. Delete code for Synthetic TrueType fonts.
# Drop PS fonts. Both code support, and any tests.
# Minimise test files.

use strict;
use warnings;
use PDF::API2;
use PDF::API2::Util;
# use PDF::API2::Lite;
use Getopt::Long;
use File::Basename;
# use diagnostics;
use Encode::Locale;
use Encode;

my $ENCODING_LOCALE;

$|++;    # turn off buffering on output.

print "Running " . __FILE__ . " \n";

# variables from the command line
my $CLleft     = 0;  # left margin/starting point; default = 36pts from page
my $CLright    = 0;  # right margin ; default = 36pts from page
my $CLtop      = 0;  # top margin/starting point; default = 36pts from page
my $CLbottom   = 0;  # bottom margin/starting point; default = 36pts from page
my $CLPGwidth  = 0;  # Page width in inches.
my $CLPGheight = 0;  # Page height in inches.
my $CLinfile   = ""; # input path & file (from cmd line arg - could be glob)
# my $lpp;              	# lines per page
# Obsolete - Replaced by counting points, instead of lines.
# my $layout;           	# portrait or landscape; default = portrait
# Obsolete - Replaced by page height, and width.
my $CLlandscape = "";    # landscape cmd line flag
my $CLportrait  = "";    # portrait cmd line flag
# landscape and portrait, both assume American letter size paper.
#   Any other size paper can be set using Page Width, and Page Height in inches.
#   It is left as an exercise for future development to support more
#   page sizes by name.
my $CLFontName = "";    # cmd line fontname.
my $CLfontsize = 7;     # font size; default = 7
my $CLFontType = "CS";   # Font Type, CS =Core, TT=TrueType font.
# The implementation of CJK fonts, PS fonts, BDF fonts, and/or uni-fonts is left
#   as an exercise for future development.
my $CLbold   = 0;    # set to non-zero for bold on; default = 0;
my $CLitalic = 0;
# Set to non-zero for Italic style of font; default =0 for normal
my $CLslant   = 0;  # Set to non-zero for slanted font; default = 0 for normal
my $CLoblique = 0;  # Set to non-zero for oblique font; default = 0 for normal
# All three above control the degree of the style.
#  Floating point numbers are allowed.
my $CLspacing = 8;     # text spacing ($pdf->textlead); default = 8
my $CLalign   = "";    # Alignment of the text.
#  Valid values are L, left, C, center, or a case-insensitive variant.
my $CLencode = "";     # Character encoding.
# The default is taken from the first environment variable LC_ALL, LC_CTYPE,
#   or LANG that has a value.
#   The value is the encoding, or other values, period, encoding.
#   We use the character string after the last period for the encoding value.
my $CLdestpath      = "";    # destination path

my @CLFontLib = () ; # Command line folders to add to the Font search.

my $CLPrintControls = 0;
#  Print Control Keyword inputs like FONT, etc. in the PDF file.
#  Also print warn messages in the PDF file.
#  For Testing/diagnostic purposes only.
#  This parmameter is a useful way to demonstrate a font and styles.
#    It also makes it easier to understand why a font might not work.
my $CLRunMessages = 0;  # Print Line and file running messages.
#  For Testing/diagnostic purposes only.

my $pdf;            # main PDF document object
my $page;           # current page being processed
my $text;           # current page's text object
my $font;           # current font being used
my $pointscount;    # how many points have been processed on this page.
# Starts with zero at the top of the page.
my $PGheight = 0;    # Physical sheet height in points.
my $PGwidth  = 0;    # Physical sheet height in points.
my ( $left, $right, $top, $bottom );
my ( $LineStart, $LineBottom );
my ( $gfx, $txt, $gfx_border, $gfx_image );

# other variables
my @FILES;           # list of input files, in case of glob
my $file;            # Current file being converted
my $destpath;        # destination path
my $infile;          # Source file name
my $outfile;         # output path & file
my $arg;             # command line argument being processed
my $help = 0;        # Flag for displaying help
my @FDirs = ();      # Font Search folders.

my $FontNameStr = "Helvetica";    # Sample fontnames.
$FontNameStr = "TimesRoman";
$FontNameStr = "Courier";
my $FontTypeStr = "CS";
# CS means Core (Adobe core font), TT means TrueType font
my $FontBold    = 0;                  # degree of Boldness of the font.
my $FontItalic  = 0;                  # degree of Italic of the font.
my $FontSlant   = 0;                  # degree of slant of the font.
my $FontOblique = 0;                  # degree of oblique of the font.
my $Encoding    = $ENCODING_LOCALE;   # byte character encoding, default value
my $fontsize;                         # font size
my $spacing;                          # spacing
my $CenterTextMode = 0;               # Center the text.

my $DebugParmsFlag = 0;    # Help by printing processed parameter values
my $DebugFontDirsFlag = 0 ; 
my $Debug_Image_Placement = 0;
my $Debug_newpage = 0;

if ( $#ARGV < 0 ) {
  &usage;
  exit(1);
}

# NOTE: A point is 1/72 inch.
# Other environments use other slightly different values.
# get those cmd line args!
my $opts_okay = GetOptions(
  'h'          => \$help,
  'help'       => \$help,          # Can use -h or --help
  'left=f'     => \$CLleft,        # Left Margin - points
  'right=f'    => \$CLright,       # Right Margin - points
  'top=f'      => \$CLtop,         # Top Margin - points
  'bottom=f'   => \$CLbottom,      # Bottom Margin - points
  'PGwidth=f'  => \$CLPGwidth,     # Page Width - inches
  'PGheight=f' => \$CLPGheight,    # Page Height - inches
  'fontname=s' => \$CLFontName,    # font name
  'fonttype=s' => \$CLFontType,
  # font type, C=Core, TT=TrueType, PS=Adobe Type1 font
  'fontsize=f' => \$CLfontsize,    # Nominal height of characters - points
  'spacing=f'  => \$CLspacing,     # Spacing between successive lines - points
  'b=f'        => \$CLbold,        # Bold flag, value.
  'bold=f'     => \$CLbold,        # Bold flag, value.
  'i=f'        => \$CLitalic,      # Italic flag, value.
  'italic=f'   => \$CLitalic,      # Italic flag, value.
  's=f'        => \$CLslant,       # slant flag, value.
  'slant=f'    => \$CLslant,       # slant flag, value.
  'o=f'        => \$CLoblique,     # oblique flag, value.
  'oblique=f'  => \$CLoblique,     # oblique flag, value.
  'a=s' => \$CLalign,  # Alignment value: l, left, c, center, case-insensitive
  'align=s' => \$CLalign,
  # Alignment value: l, left, c, center, case-insensitive
  'e=s'          => \$CLencode,           # character byte encoding
  'encoding=s'   => \$CLencode,           # character byte encoding
  'l'            => \$CLlandscape,
  'p'            => \$CLportrait,
  'PrintControl' => \$CLPrintControls,    # Testing / Diagnostic Flag
  'RunMessages'  => \$CLRunMessages,      # Testing / Diagnostic Flag
  'DbParms'      => \$DebugParmsFlag,     # Testing / Diagnostic Flag
  'DbFontDirs'   => \$DebugFontDirsFlag,  # Testing / Diagnostic Flag
  'DbImagePlacement' => \$Debug_Image_Placement, # Testing / Diagnostic Flag
  'DbNewPage'    => \$Debug_newpage,      # Testing / Diagnostic Flag
  'in=s'         => \$CLinfile,
  'dir=s'        => \$CLdestpath,
  'fontlib=s'    => \@CLFontLib     # Folders to add to the Font search folders.
);

if ($DebugParmsFlag) {
  print "opts_okay =", $opts_okay, "X; help =", $help, "X; \nLeft Margin =",
    $CLleft, "X; Right Margin =", $CLright, "X; Top Margin =", $CLtop,
    "X; Bottom Margin =", $CLbottom,   "X; \nPage Width =",     $CLPGwidth,
    "X; Page Height =",   $CLPGheight, "X; \nfont name =",      $CLFontName,
    "X; font type =",     $CLFontType, "X; font size height =", $CLfontsize,
    "X; line spacing =",  $CLspacing,  "X;\nBold =",            $CLbold,
    "X; Italic =", $CLitalic, "X; slant =", $CLslant, "X; oblique =",
    $CLoblique, "X; Alignment =", $CLalign, "X; \ncharacter byte encoding =",
    $CLencode, "X; landscape =", $CLlandscape, "X; portrait =", $CLportrait,
    "X; PrintControls=", $CLPrintControls, "X;\nInput File(s) =", $CLinfile,
    "X; Destination Folder =", $CLdestpath, "X;\n";
  print "\nNEW Font Libs\n" ;
  print join("\n", @CLFontLib) ;
  print "\n" ;
  print "EXISTING Font Libs\n" ;
  print join ("\n", PDF::API2::addFontDirs()) ;
  print "\n" ;
}

# if help, then display usage
if ( !$opts_okay || $help ) { &usage; exit(0); }

# Check path
if   ( !$CLdestpath ) { $destpath = './'; }
else                  { $destpath = $CLdestpath; }
# Default destination directory is the current working directory.

# Check for filename vs. filespec(glob)
if ( $CLinfile =~ m/\*|\?/ ) {
  print "Found glob spec, checking...\n";
  @FILES = glob($CLinfile);
  if ( !@FILES ) {
    warn "Please specify a file name or glob with --in=<filename>\n";
    die "No files match spec: '$infile', exiting...\n";
  }    # if no files match
  print "Found file";
  if ( $#FILES > 0 ) { print "s"; }    # Be nice, use plural
  print ":\n";
  foreach (@FILES) {
    print "$_\n";
  }                                    # foreach @FILES

}
else {
  if ( !-f $CLinfile ) {
    warn "Please specify a file name or glob with --in=<filename>\n";
    die "Could not locate file '$CLinfile', exiting...\n";
  }                                    # if $infile not found
  @FILES = ($CLinfile);
}    # if $infile contains wildcards

# Validate remaining cmd line args

### Validate physical sheet size.

if ($CLlandscape) {
  ## Set up landscape defaults and maxima
  die "ERROR: Had a page width and landscape option on command line.\n"
    if ($CLPGwidth);
  die "ERROR: Had a page height and landscape option on command line.\n"
    if ($CLPGheight);
  die "ERROR: Had portrait and landscape options on command line.\n"
    if ($CLportrait);
  $PGheight = 8 * 72 + 36;    # sheet height at 8.5 inches.
  $PGwidth  = 11 * 72;        # sheet width at 11 inches.
                              # 72 points per inch.
}

if ($CLportrait) {
  ## Set up portrait defaults and maxima
  die "ERROR: Had a page width and portrait option on command line.\n"
    if ($CLPGwidth);
  die "ERROR: Had a page height and portrait option on command line.\n"
    if ($CLPGheight);
  $PGheight = 11 * 72;        # sheet height at 11 inches.
  $PGwidth  = 8 * 72 + 36;    # sheet width at 8.5 inches.
                              # 72 points per inch.
}

$PGwidth  = $CLPGwidth * 72  if ( $CLPGwidth  and $CLPGwidth > 0 );
$PGheight = $CLPGheight * 72 if ( $CLPGheight and $CLPGheight > 0 );
print "Page Width is $PGwidth.\n";
print "Page Height is $PGheight.\n";

die "ERROR: Page width not specified.\n"  unless ($PGwidth);
die "ERROR: Page height not specified.\n" unless ($PGheight);

### Validate Left and Right margins.

## If left margin not specified, default to 1/2" or 36 points
unless ($CLleft) { $left = 36; }    # Default left margin
elsif ( $CLleft < 0 ) {
  die "ERROR: Left margin on command line is negative.\n";
}
else { $left = $CLleft; }

## If right margin not specified, default to 1/2" or 36 points
unless ($CLright) { $right = 36; }    # Default right margin
elsif ( $CLright < 0 ) {
  die "ERROR: Right margin on command line is negative.\n";
}
else { $right = $CLright; }

print "Left margin is $left.\n";
print "Right margin is $right.\n";

# The left and right margins need to leave some space to print.
# Some space is arbitrarily set at 1/8 inch, or 9 points.
die
  "ERROR: Left margin, right margin, and page width leave too little space to print.\n"
  if ( $PGwidth <= ( $left + $right + 9 ) );

### Validate Top and Bottom margins.

## If top margin not specified, default to 1/2" or 36 points
unless ($CLtop) { $top = 36; }    # Default top margin
elsif ( $CLtop < 0 ) {
  die "ERROR: Left margin on command line is negative.\n";
}
else { $top = $CLtop; }
print "Top Margin is $top.\n";

## If bottom margin not specified, default to 1/2" or 36 points
unless ($CLbottom) { $bottom = 36; }    # Default bottom margin
elsif ( $CLbottom < 0 ) {
  die "ERROR: Right margin on command line is negative.\n";
}
else { $bottom = $CLbottom; }
print "Bottom Margin is $bottom.\n";

# The top and bottom margins need to leave some space to print.
# Some space is arbitrarily set at 1/8 inch, or 9 points.
die
  "ERROR: Left margin, bottom margin, and page height leave too little space to print.\n"
  if ( $PGheight <= ( $top + $bottom + 9 ) );

$spacing = $CLspacing if ($CLspacing);

my $FntBold = 0;
$FntBold = $CLbold if ($CLbold);
my $FntItalic = 0;
$FntItalic = $CLitalic if ($CLitalic);
my $FntSlant = 0;
$FntSlant = $CLslant if ($CLslant);
my $FntOblique = 0;
$FntOblique = $CLoblique if ($CLoblique);

my $PDFtop    = $PGheight - $top;
my $PDFbottom = $bottom;

# Validate byte character encoding or set default.
# Validation is left to the user or future development.
$Encoding = $CLencode if ($CLencode);
# $Encoding has the default.
# $CLencode has the command line parameter.

# Validate and set font type, font, font size, and spacing.
$fontsize = $CLfontsize;
if ( $CLFontType eq "CS" 
    || $CLFontType eq "TT" 
    || $CLFontType eq "PS" ) {
  $FontTypeStr = $CLFontType;
}
else {
  die "ERROR: Font Type on command line $CLFontType is invalid.\n";
}

if ($CLFontName) {
  $FontNameStr = $CLFontName;
}

# Process Font Search folders on the Command Line.
@FDirs = PDF::API2::addFontDirs() ;
my $NewFontDir = "" ;
foreach $NewFontDir (@CLFontLib) {
  addDirToFontFolders ($NewFontDir) ;
}

if ( $CLfontsize <= 1 ) {
  die "ERROR: Font size on command line $CLfontsize is less than 1.\n";
}
elsif ( !$CLfontsize ) {
  die "ERROR: Font size on command line $CLfontsize is invalid.\n";
}
else {
  $fontsize = $CLfontsize;
}

# Set max, min spacing
if ( $spacing > 720 ) { $spacing = 720; }
# why would anyone want this much spacing?
if ( $spacing < 1 ) { $spacing = 1; }    # That's awfully crammed together...

foreach $file (@FILES) {
  $SIG{__WARN__} = 'DEFAULT' ; 
  # Turn off WarnWithPDF signal processing until the PDF object/page exists.
  print "Processing $file...\n";
  my ( $name, $dir, $suf ) = fileparse( $file, qr/\.[^.]*/ );
  my $SRC_dir = $dir ;
  if ( $suf =~ m/txt2pdf|txt/ ) {
    # replace .txt or .txt2pdf with .pdf
    $outfile = $destpath . $name . '.pdf';
  }
  else {
    # just append .pdf to end of filename
    $outfile = $destpath . $name . $suf . '.pdf';
  }    # if suffix is '.txt' or '.txt2pdf'
  
  $pdf = PDF::API2->new( -file => $outfile );

  # Errors that occur in the first calls to setfonts, and newpage will not
  #   appear in the PDF file.  The PDF objects are not ready yet.
  &setfonts;    # Set the fonts.
  &newpage;     # create first page in PDF document
  $SIG{__WARN__} = \&WarnWithPDF ; 

  print
    "Page Length data LineBottom $LineBottom - spacing $spacing - bottom $bottom \n";
  open( FILEIN, "$file" ) or die "$file - $!\n";
  while (<FILEIN>) {
    # chomp is insufficient when dealing with EOL from different systems
    # this little regex will make things a bit easier
    s/(\r)|(\n)//g;

    if ( m/\x0C/ || ( ( $LineBottom - $spacing - $bottom ) < 0 ) )
    {    # found page break
      &FinishObjects;
      &newpage;
      next if (m/\x0C/);
    }    # if
    my (
      $NewFontFound,        $NewFont,             $NewFontSizeFound,
      $NewFontSize,         $NewFontSpacingFound, $NewFontSpacing,
      $NewFontTypeStrFound, $NewFontBold,         $NewFontItalic,
      $NewFontSlant,        $NewFontOblique
    );
    if (m/^FONT /) {
      $NewFontFound        = 0;
      $NewFont             = "";
      $NewFontSizeFound    = 0;
      $NewFontSize         = 0;
      $NewFontSpacingFound = 0;
      $NewFontSpacing      = 0;
      $NewFontBold         = 0;
      $NewFontItalic       = 0;
      $NewFontSlant        = 0;
      $NewFontOblique      = 0;
      # Change Centering if asked.
      if (m/\sLEFT(\s|$)/) {
        $CenterTextMode = 0;
      }
      if (m/\sCENTER(\s|$)/) {
        $CenterTextMode = 1;
      }
      # Change the font.
      if (m/FONT\s*\=\s*(\S+)\s/) {
        $NewFontFound = 1;
        $NewFont      = $1;
        $FntBold      = 0;
        $FntItalic    = 0;
        $FntSlant     = 0;
        if (m/TYPE\s*\=\s*(\w+)(\W|$)/) {
          $NewFontTypeStrFound = 1;
          $FontTypeStr         = $1;
        }
        if (m/\sBOLD\s*\=\s*(-?\d*\.?\d+)/) {
          $FntBold = $1;
        }
        if (m/\sITALIC\s*\=\s*(-?\d*\.?\d+)/) {
          $FntItalic = $1;
        }
        if (m/\sSLANT\s*\=\s*(-?\d*\.?\d+)/) {
          $FntSlant = $1;
        }
        if (m/\sOBLIQUE\s*\=\s*(-?\d*\.?\d+)/) {
          $FntOblique = $1;
        }
      }
      if (m/\sSIZE\s*\=\s*(\d+)(\D|$)/) {
        $NewFontSizeFound = 1;
        $NewFontSize      = $1;
      }
      if (m/\sSPACING\s*\=\s*(\d+)(\D|$)/) {
        $NewFontSpacingFound = 1;
        $NewFontSpacing      = $1;
      }
      unless ( $NewFontFound or $NewFontSizeFound or $NewFontSpacingFound ) {
        warn "ERROR: No Font, Size, or Spacing given on FONT line.\n";
        warn "ERROR Line: $_\n";
      }
      if ($NewFontFound) {
        $FontNameStr = $NewFont;
        &setfonts;
      }
      $fontsize = $NewFontSize    if ($NewFontSizeFound);
      $spacing  = $NewFontSpacing if ($NewFontSpacingFound);
      $txt->font( $font, $fontsize );
      newline($_) if ($CLPrintControls);
      next;
      # The FONT line will print in the new font if $CLPrintControls.
    }
    elsif (m/^IMAGE /) {
      # Load a picture.  The picture file name is all.
      newline($_) if ($CLPrintControls);
      my ( $imageFileName, $ImageFileSuff, $imageObj ) = ();
      my ( $imageHeight, $imageWidth, $imageUpDown, $ImageLeftRight ) = ();
      my $imageIntrinsicHeight = 0 ;
      my $imageIntrinsicWidth = 0 ;
      my $imagePrintHeight = 0 ;
      my $imagePrintWidth = 0 ;
      $imageFileName = "";
      $imageHeight   = 0;
      $imageWidth    = 0;
      $ImageFileSuff = "";

      # Trim leading and trailing white space from the file name.
      if (m/FILE\s*\=\s*(\S+)(\s|$)/) {
        $imageFileName = $1;
      }
      # NOTE: $SRC_dir is used as a prefix to the folders 
      #   if the $imageFileName starts with SRC as the first folder name.
      #   Image filenames are then relative to the source file name.
      $imageFileName =~ s/^SRC([\/\\])/${SRC_dir}/ ;
      if (m/HEIGHT\s*\=\s*(\d+)(\D|$)/) {
        $imageHeight = $1;
      }
      if (m/WIDTH\s*\=\s*(\d+)(\D|$)/) {
        $imageWidth = $1;
      }
      $imageFileName =~ m/\.([^\.]+)$/;
      $ImageFileSuff = $1 || "";
      warn "ERROR: No image file name.\n"        unless ($imageFileName);
      warn "ERROR: No image file name suffix.\n" unless ($ImageFileSuff);
      unless ( -r $imageFileName && -s _ ) {
        warn
          "ERROR: The file $imageFileName is either unreadable or empty.\n";
        next;
      }
      if ( $ImageFileSuff =~ m/^jpg$|^jpeg$/i ) {
        $imageObj = $pdf->image_jpeg($imageFileName);
      }
      elsif ( $ImageFileSuff =~ m/^tif$|^tiff$/i ) {
        $imageObj = $pdf->image_tiff($imageFileName);
      }
      elsif ( $ImageFileSuff =~ m/^png$/i ) {
        $imageObj = $pdf->image_png($imageFileName);
      }
      elsif ( $ImageFileSuff =~ m/^pnm$|^ppm$|^pgm$|^pbm$/i ) {
        $imageObj = $pdf->image_pnm($imageFileName);
      }
      else {
        warn "ERROR: The file $imageFileName has an unsupported suffix $ImageFileSuff.\n";
        next;
      }
      $imageIntrinsicHeight = ${ ${$imageObj}{Height} }{val} ;
      $imageIntrinsicWidth = ${ ${$imageObj}{Width} }{val} ;
      unless ($imageIntrinsicHeight && $imageIntrinsicWidth) {
        # The image file is missing Height and/or Width.
        warn "ERROR: Image file is missing Height and/or Width." ;
        warn "Image line is $_ \n" ;
        warn "imageFileName is $imageFileName \n" ;
        warn "IntrinsicHeight is $imageIntrinsicHeight, IntrinsicWidth is $imageIntrinsicWidth \n" ;
        warn "Using default of 144 for any missing value.\n" ;
        $imageIntrinsicHeight = 144 unless ($imageIntrinsicHeight) ;
        $imageIntrinsicWidth = 144 unless ($imageIntrinsicWidth) ;        
      }
      # It is assumed that we have good data for both Intrinsic values.
      # We might have been given 0, 1, or 2 values on the IMAGE line.
      unless ($imageHeight || $imageWidth) {
        # Neither Width nor Height was on the IMAGE line.
        $imagePrintHeight = $imageIntrinsicHeight ;
        $imagePrintWidth = $imageIntrinsicWidth ;
      } elsif ($imageHeight && $imageWidth) {
        # Both Width and Height was on the IMAGE line.
        $imagePrintHeight = $imageHeight ;
        $imagePrintWidth = $imageWidth ;
      } elsif ($imageHeight) {
        # Only Height was on the IMAGE line.
        $imagePrintHeight = $imageHeight ;
        $imagePrintWidth = int ((($imageIntrinsicWidth / $imageIntrinsicHeight) * $imageHeight) + 0.5) ;
      } elsif ($imageWidth) {
        # Only Width was on the IMAGE line.
        $imagePrintWidth = $imageWidth ;
        $imagePrintHeight = int ((($imageIntrinsicHeight / $imageIntrinsicWidth) * $imageWidth) + 0.5) ;
      } else {
        # Somehow a logic error has occurred.
        warn "ERROR: Logic error in image processing." ;
        warn "Image line is $_ \n" ;
        warn "imageFileName is $imageFileName \n" ;
        warn "IntrinsicHeight is $imageIntrinsicHeight, IntrinsicWidth is $imageIntrinsicWidth \n" ;
        warn "Parm Height is $imageHeight, Parm Width is $imageWidth \n" ;
        warn "Using default Height and width of 144, and 144.\n" ;
        $imagePrintHeight = 144 ;
        $imagePrintWidth = 144 ;        
      }

      $imageUpDown = $LineBottom - $imagePrintHeight;
      $ImageLeftRight = int( ( $PGwidth - $imagePrintWidth ) / 2 );
      if ( ( $LineBottom - $imagePrintHeight - $bottom ) < 0 ) {
        # found page break - Not enough height for image.
        &FinishObjects;
        &newpage;
        $imageUpDown = $LineBottom - $imagePrintHeight;
      }    # if
      if ($Debug_Image_Placement) {
        print "imageFileName is $imageFileName \n" ;
        print "LineBottom $LineBottom \n";
        print "imageHeight $imagePrintHeight imageWidth $imagePrintWidth \n";
        print "imageUpDown $imageUpDown ImageLeftRight $ImageLeftRight \n";
      }
      $gfx->image(
        $imageObj,   $ImageLeftRight, $imageUpDown,
        $imagePrintWidth, $imagePrintHeight
      );
      $LineBottom -= $imagePrintHeight;
      $pointscount += $imagePrintHeight;
      next;
    }
    elsif (m/^FONTDIRS /) {
      # addFontDirs
      @FDirs = PDF::API2::addFontDirs() ;
      my $console = 0 ;
      my $inpdf = 0 ;
      my $dirOfFont = "" ;
      $console = 1 if (m/CONSOLE/) ;
      $inpdf = 1 if (m/PDF/) ;
      newline($_) if ($CLPrintControls);
      if ($console) {
        print "\nFont Directories\n" ;
        foreach $dirOfFont (@FDirs) {
          print $dirOfFont, "\n" ;
        }
        print "\n" ;
      }
      if ($inpdf) {
        newline( "") ;
        newline( "Font Directories") ;
        foreach $dirOfFont (@FDirs) {
          newline( $dirOfFont) ;
        }
        newline( "") ;
      }
      unless ($inpdf || $console) {
        warn "FONTDIRS used without either CONSOLE or PDF.\n" ;
      }
      next ;
    }
    elsif (m/^NEWFONTDIR /) {
      # addFontDirs
      newline($_) if ($CLPrintControls);
      my $dirOnLine = "" ;
      if (m/^NEWFONTDIR\s+(.+)\s*$/) {
        # The pattern allows embedded whitespace, but not leading or trailing.
        $dirOnLine = $1 ;
        addDirToFontFolders($dirOnLine) ;
      } else {
        warn "NEWFONTDIR line without data.\n";
      } 
      next ;
    }
    # Print the line.
    newline($_);
  }    # while(<FILEIN>)
  print "Finished while loop ", __FILE__, " ", __LINE__, ".\n"
    if ($CLRunMessages);
  # $pdf->textend;
  close(FILEIN);
  print "Finished close ", __FILE__, " ", __LINE__, ".\n"
    if ($CLRunMessages);
  &FinishObjects;
  print "Finished FinishObjects ", __FILE__, " ", __LINE__, ".\n"
    if ($CLRunMessages);
  $SIG{__WARN__} = 'DEFAULT' ; 
  # Turn off WarnWithPDF signal processing since the PDF object/page is gone.  
  $pdf->save;
  print "Finished save ", __FILE__, " ", __LINE__, ".\n"
    if ($CLRunMessages);
  $pdf->end;
  print "Finished end ", __FILE__, " ", __LINE__, ".\n"
    if ($CLRunMessages);
}    # foreach $file (@FILES)
if ($DebugFontDirsFlag) {
  print "AT END Font Libs\n" ;
  print join ("\n", PDF::API2::addFontDirs()) ;
  print "\n" ;
}
print "Finished end ", __FILE__, " ", __LINE__, ".\n"
  if ($CLRunMessages);
exit 0;
# Normal end of the main routine.

sub newline {
  my $TextLineWidth = 0;
  my @overrides     = ();
  my $NewLineTxt = $_[0] ;
    if ( ( $LineBottom - $spacing - $bottom ) < 0 )
    { # found page break
      &FinishObjects;
      &newpage;
    }    # if
  if ($FontTypeStr =~ m/^CS/) {
    if ($CenterTextMode) {
      $txt->font( $font, $fontsize );
      $TextLineWidth = $txt->advancewidth( $NewLineTxt, @overrides );
      $txt->textlabel(
        ( int( ( $PGwidth - $TextLineWidth ) / 2 ) ),
        $LineBottom - $spacing,
        $font, $fontsize, $NewLineTxt
      );
    }
    else {
      $txt->textlabel( $LineStart, $LineBottom - $spacing,
        $font, $fontsize, $NewLineTxt );
    }
  }
  elsif ($FontTypeStr eq "TT") {
    if ($CenterTextMode) {
      $gfx->font( $font, $fontsize );
      $TextLineWidth = $gfx->advancewidth( $NewLineTxt, @overrides );
      $gfx->textlabel(
        ( int( ( $PGwidth - $TextLineWidth ) / 2 ) ),
        $LineBottom - $spacing,
        $font, $fontsize, $NewLineTxt );
    }
    else {
      $gfx->textlabel( $LineStart, $LineBottom - $spacing,
        $font, $fontsize, $NewLineTxt );
    }
  } else {
    warn "ERROR: FontTypeStr $FontTypeStr not supported by newline.\n" ;
  }
  $LineBottom -= $spacing;
  $pointscount += $spacing;
}    # sub newline

sub newpage {
  my (
    $border_left, $border_bottom,
    $border_right,  $border_top,  $Draw_Border
  );
  $Draw_Border   = 0;
  $page          = $pdf->page;
  $page->mediabox( $PGwidth, $PGheight );
  $LineStart   = $left;
  $LineBottom  = $PGheight - $top;
  $pointscount = 0;
  $gfx         = $page->gfx;
  $txt         = $page->text;
  # Draw a border around the page.
  $border_left   = int( $left / 2 );
  $border_right  = $PGwidth - int( $right / 2 );
  $border_bottom = int( $bottom / 2 );
  $border_top    = $PGheight - int( $top / 2 );
  if ($Debug_newpage) {
    warn "Debug newpage PGwidth $PGwidth PGheight $PGheight\n";
    warn "Margins left $left right $right top $top bottom $bottom\n";
    warn
      "Border  left $border_left right $border_right top $border_top bottom $border_bottom\n";
  }
  $gfx_border = $page->gfx;
  if ($Draw_Border) {
    $gfx_border->strokecolor('black');
    $gfx_border->move( $border_left, $border_bottom );
    $gfx_border->line( $border_left,  $border_top );
    $gfx_border->line( $border_right, $border_top );
    $gfx_border->line( $border_right, $border_bottom );
    $gfx_border->close;
    $gfx_border->stroke;
  }

  &setfonts();
  $txt->font( $font, $fontsize );

  # $pdf->textstart;
  # $pdf->textlead($spacing);
  # $pdf->transform(-translate => [$left,$top]);
  # $pdf->textfont($font,$fontsize);

}

sub FinishObjects () {
  $pdf->finishobjects( $page, $gfx );
}

sub setfonts () {
  # print "FontTypeStr $FontTypeStr.\n" ;
  my %options = ();
  my $font1;
  my $font0;
  #
  # $FntBold - Typical is 1, embolden by 10em.
  # $FntItalic - Typical is -12, italic at 12 degrees
  # $FntSlant - Typical is 0.85, compressed by 85%.
  #
  $options{'-bold'}    = $FntBold    if ($FntBold);
  $options{'-slant'}   = $FntSlant   if ($FntSlant);
  $options{'-oblique'} = $FntOblique if ($FntOblique);
  $options{'-italic'}  = $FntItalic  if ($FntItalic);
  if ( $FontTypeStr eq "TT" ) {
    # warn "True Type Font called X", $FontNameStr, "X.\n" ;
    eval {$font0 = $pdf->ttfont( $FontNameStr, -encode => 'latin1' ) };
    if ($@) {
      warn "ERROR: Returned string is $@." ;
      warn "ERROR: Font creation issue; FontNameStr is $FontNameStr.\n" ;
      return 0;
    }
    $font1 = $font0 ;
    if (%options) {
      eval {$font0 = $pdf->synfont( $font1, %options )};
      if ($@) {
        warn "ERROR: Returned string is $@." ;
        warn "ERROR: Synthetic Font creation issue; FontNameStr is $FontNameStr." ;
        warn "ERROR: Bold=$FntBold Slant=$FntSlant Oblique=$FntOblique Italic=$FntItalic\n" ;
        $font = $font1;
      } else {$font = $font0 ; }     
    } else { 
      $font = $font0; 
    }
  }
  elsif ( $FontTypeStr eq "CS" ) {
    # $font1 = $pdf->corefont( $FontNameStr, -encode => $Encoding );
    eval {$font0 = $pdf->corefont( $FontNameStr, -encode => 'latin1' ) };
    if ($@) {
      warn "ERROR: Returned string is $@." ;
      warn "ERROR: Font creation issue; FontNameStr is $FontNameStr.\n" ;
      return 0;
    }
    $font1 = $font0 ;
    if (%options) { 
      eval {$font0 = $pdf->synfont( $font1, %options ) }; 
      if ($@) {
        warn "ERROR: Returned string is $@." ;
        warn "ERROR: Synthetic Font creation issue; FontNameStr is $FontNameStr." ;
        warn "ERROR: Bold=$FntBold Slant=$FntSlant Oblique=$FntOblique Italic=$FntItalic\n" ;
        $font = $font1;
      } else {$font = $font0 ; }     
    } else { 
      $font = $font1; 
    }
  }
  else {
    warn "ERROR: Incorrect Font Type string is $FontTypeStr.\n";
  }
}

sub addDirToFontFolders {
  my $OldFDirsCnt = $#FDirs ;
  my $NewFDirsCnt = -2 ; # Choosen to never test valid if we never set it.
  my $NumParms = $#_ + 1 ;
  if ($NumParms != 1) {
    die "ERROR: addDirToFontFolders called with ${NumParms} parameters." ;
  }
  my $NewDir = $_[0] ; # First and only parameter.
  unless ($NewDir) {
    warn "ERROR: addDirToFontFolders called with a Null parameter." ;
    return 0 ;
  }
  if (! -e $NewDir) {
    warn "ERROR: addDirToFontFolders called with a non-existant folder, $NewDir " ;
    return 0 ;
  } elsif (! -d _ ) {
    warn "ERROR: addDirToFontFolders called with a file, not a folder, $NewDir " ;
    return 0 ;
  } elsif (! (-r _ && -x _ ) ) {
    warn "ERROR: addDirToFontFolders called with a non-readable or non-accessible folder, $NewDir " ;
    return 0 ;
  }
  @FDirs = PDF::API2::addFontDirs($NewDir) ;
  $NewFDirsCnt = $#FDirs ;
  unless (($OldFDirsCnt + 1) == $NewFDirsCnt) {
    warn "ERROR: addDirToFontFolders called with $NewDir did not add to folders." ;
    return 0;
  }
  return 0 ;
}

sub WarnWithPDF {
  my @MessageParm = () ;
  @MessageParm = map { split "\n" } @_ ;
  # Multi-line messages are split into one text string per array element.
  # Normally @_ will have one and only one array element.
  # We will deal with 0 elements by calling warn with a default message.
  # We will deal with more elements by processing them 
  #   as if they were part of the first element.
  my $message_txt = "" ;
  if ($#MessageParm == -1 ) {
    push @MessageParm, ( "ERROR: WarnWithPDF called without a message." ) ;
  }
  foreach $message_txt (@MessageParm) {
    $message_txt =~ s/[\n\r]//g ; # Delete extraneous line feeds and carriage returns.
    warn $message_txt . "\n" ; 
    # Add carriage return so we do not get this line listed as the source of the warn message.
    newline($message_txt) if ($CLPrintControls);
  }
}

sub usage() {
  print "Usage:\n";
  print STDOUT __FILE__, " ";
  print "\[options\] \<source file name\>\n";
  print << 'END_OF_USAGE'

Options:

  --bottom=##    specify bottom margin in points. 36 points = .5 inch
  --dir=pathname  specify destination pathname of the pdf file.
    Default is the input textfile name with a pdf suffix.
  --fontname=ss    specify the Fontname.  Default is TimesBold.
  --fonttype=ss    specify the font type.
        CS means Core w/ Styles controlled by a number.  
        TT means TrueType. 
        The default is CS.
  --fontsize=##       Specify font size, nominal height of characters in points.  The default is 7.
  -b, --bold=#.#   Specify bold style, and bold-ness.  0 implies not bold.
        1 implies embolden by 10 em
  -i, --italic=#.#  Specify italic style, and italic-ness.  0 implies not italic.
       Warning: Italic and Slant generally are mutually exclusive.
       Italic may only be accessible by font name.
  -s, --slant=#.#   Specify slant style, and slant-ness.  0 implies not slant.
        0.85 implies compressed 85%, (0.1-0.9) is slant; (1.1+) is expansion
  -o, --oblique=#.#   Specify oblique style, and oblique-ness.  0 implies not oblique.
        -12 implies italic at -12 degrees, Positive or negative may be supported.
     Any combination of styles may be listed.  These four styles imply a 
        CS fonttype.  Results will depend on the font support of the styles.
  -h, --help  This help page
  --in=pathname    Specify the input textfile.
  -l, -L      Set doc to landscape, (11 in. wide, 8.5 in. high).  Default is portrait.
  --left=##   Specify left margin in points. 72 points = 1 inch
  -p, -P      Set doc to portrait, (8.5 in. wide, 11 in. high).  This is the default.
  --PGheight=#.#  Specify the page height in inches.
  --PGwidth=#.#  Specify the page width in inches.
  --right=##   Specify right margin in points. 72 points = 1 inch
  --spacing=#.#    Specify spacing between lines in points.
  --top=##    Specify top margin in points. 36 points = .5 inch
  
  Diagnostic Parameters
  --PrintControl  Diagnostic flag to turn on printing FONT and IMAGE lines
  --RunMessages   Diagnostic flag to turn on printing "Running " here messages.
  --DbParms       Diagnostic flag to print the Command Line Parameters.
  --DbFontDirs    Diagnostic flag to print the Font search directory details.
  --DbImagePlacement Diagnostic flag to print Image placement details.
  --DbNewPage     Diagnostic flag to print page break details.

  
  The end of page is determined by the spacing in points, rather than lines per inch,
    or a form feed on a line will force a new page.
  Any other text on the line with the form feed will be ignored.

Changing fonts in the text file.
  General Font change line:
  FONT = font_name LEFT|CENTER SIZE = num SPACING = num TYPE = CS|TT
      BOLD = num ITALIC = num SLANT = num OBLIQUE = num 
    All keywords and values are case sensitive.
    The keyword FONT starts with the first character in the line.
    The " = font_name" must have a space in front of the =,
      and must immediately follow the FONT keyword.  It is optional.
    LEFT or CENTER are optional, and may be in any order.
    LEFT means left justify the text.
    CENTER means center justify the text.
    The SIZE parameter is the font size for the text.
    The SPACING parameter sets the space between lines.
    SIZE=8 SPACING=16 is like double line spacing.
    The TYPE keyword is for choosing a Core, or True Type font.
    Using the TYPE keyword requires having " = font_name".

    The style keywords BOLD, ITALIC, SLANT, or OBLIQUE must have a number
      value. It may be an integer, or decimal number like 1, .85, 2.5, etc.
    Not listing a style, or a num value of 0, implies not using the style.

  Any extra text on the font change line is ignored.

Inserting an image in the text file.
  General Image insertion line:
  IMAGE FILE = image_filename HEIGHT = num WIDTH = num
    Errors in the image insertion line are written to the error output,
      and the line is ignored.
    The suffix of the image_filename is used to determine the image type.
    The suffixes jpg, jpeg, tif, tiff, png, pnm, ppm, pgm, and pbm are supported.
       The suffixes are case-insensitive.
    The HEIGHT and WIDTH are in points, and optional.
    The default values are the height and width of the image in pixels.
    If only HEIGHT or WIDTH are given, the other is choosen to maintain
      the aspect ratio of the image.
    The images are always printed, center justified.

  Special thanks to Michael Collins for getting me started.
  Special thanks to Alfred Reibenschuh for such a cool Perl module!
  Also, many thanks to the PDF::API2 community for such great ideas.

END_OF_USAGE
}

__END__
