/*= ratty FORTRAN preprocessor, so that same code works on more machines */
/*& bpw */
/*: tools */
/*+
Ratty is a FORTRAN preprocessor for MIRIAD source code, intended to
make the same FORTRAN code compatible on VMS, SUN, Cray, Alliant,
and Convex. The output is suitable for use with the specified compilers
for these machines.

Usage:

 ratty [-h] [-s system] [-I incdir] [-D symbol] [-bglu [-n start inc]
       [-p data-type] [-a] [in] [out]

    system:  compiler/system type, one of
               "alliant"   (alliant unix compiler)
               "alpha"     (DEC alpha compiler)
               "convex"    (CONVEX unix compiler)
               "f2c"       (NETLIBs f2c compiler)
               "f77"       (generic unix compiler)
               "g77"       (GNU g77 compiler)
               "gfortran"  (GNU gfortran chmpiler)
               "hpux"      (HPUX compiler)
               "linux"     (generic Linux compiler)
               "sgi"       (SGI compiler)
               "sun"       (sun unix compiler)
               "unicos"    (Cray Fortran compiler)
               "vms"       (VMS Fortran compiler)

    incdir:  Directory to search for include files.  The -I option may
             be used repeatedly, but must list only one directory for
             each -I parameter (eg, list two directories as
             "-I dir1 -I dir2").

    symbol:  Define this symbol to the preprocessor. Multiple
             definitions are allowed, defining one symbol per -D entry
             (eg, define two symbols as "-D sym1 -D sym2").

    -a:      shortcut when sizeof(long) == 8, use '-p INTEGER*8'

    -b:      If specified, backslashes inside quoted textstrings are
             doubled. This allows for compilers which treat the
             backslash as an escape character.

    -g:      If specified, it will direct the code to include line number
             directives for your native compiler, if it understands them.
             This will enable you to run dbx, and look directly at your
             [in] file, instead of your [out] file. Note that standard
             input cannot be used with this option.

    -h:      give some help and exit

    -n:      This gives the start and increment for line numbers generated
             by ratty. The default is 90000 1.

    -l:      Convert all variables, etc, to lower case.

    -u:      Convert all variables, etc, to upper case.
             (some of the system-generated if/then/else/endif/continue
              are not converted to upper case)

    -p:      Give the FORTRAN type to be used for "ptrdiff" data type.

    in:      Input file name. If omitted, standard input is assumed
             and output must be the standard output.

    out:     Output file name. If omitted, standard output is assumed.


Ratty recognizes the standard C preprocessor directives #ifdef,
#ifndef, #else and #endif.

The VAX do/dowhile/enddo extension for do loops is converted to
ANSI-FORTRAN if the host machine does not support this extension.

'IMPLICIT NONE' and 'IMPLICIT UNDEFINED(A-Z)' are converted to
whatever the specified compiler supports.

Certain directives are recognized if the target machine has
vector processing capacities (compilers "unicos", "alliant" and "convex"):

    #maxloop, followed by a number, is converted to "cdir$ shortloop"
    on "unicos" and to "cvd$  shortloop" on "alliant".

    #ivdep is converted to "cdir$ ivdep" on "unicos", to "cvd$  nodepchk"
    on "alliant", and to "c$dir no_recurrence" on "convex".

    #nooptimize is converted to "cdir$ nextscalar" on "unicos" and to
    "cvd$ noconcur" followed by "cvd$ novector" on "alliant".
*/
/*-- */
/*****************************************************************************
*
* History:
*   Refer to the RCS log, v1.1 includes prior revision information.
*
* CARMA MIRIAD customizations:
*
* 2011/Jul/07  pkgw  Reduce chattiness by removing "number of lines" message
* 2012/Feb/15  pjt   -a flag to simplify 64bit usage of integer*8
*
* $Id$
******************************************************************************
* ToDos/Shortcomings:
*  The -u flag doesn't convert self-generated if/then/continue etc.
*  This would mean occurences like
*      textout("continue\n");
*  to be changed to:
*      (uflag?textout("continue\n"):textout("CONTINUE\n"));
*  comment lines like "c#define foo bar" still define !!! 
*****************************************************************************/
#define VERSION_ID   "2012/02/15"

#define max(a,b) ((a) > (b) ? (a) : (b) )
#define min(a,b) ((a) < (b) ? (a) : (b) )

#define private static
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define TRUE 1
#define FALSE 0

static void get_labelnos(char *slower, char *sinc);
static void process(FILE *in, char *infile);
static void message(char *text);
static void textout(char *text);
static void numout(int label);
static void labelout(int label);
static void blankout(int blanks);
static void lowercase(char *string);
static char *getparm(char *line, char *token);
static void cppline(char *line);
static char *progtok(char *line, char *token, int *indent, int *lineno,
                     int *bracketting);
static char *skipexp(char *s, int *bracketting);
static int get_line(FILE *in, char *line);
static int reformat(char *s);
static struct link_list *add_list(struct link_list *list, char *name);
static FILE *incopen(char *name, char *pathname);
static int isdefine(char *name);
static void usage(void);

/* A few things to stop lint complaining. */
#define Strcpy (void)strcpy
#define Strcat (void)strcat
#define Fclose (void)fclose
#define Fputc  (void)fputc
#define Malloc(a) malloc((unsigned int)(a))

/*
 * Define capacities of the various compilers. These are:
 *  doloop	is true if the compiler handles the VAX do/dowhile/enddo
 *		extension.
 *  prog	is true if the compiler expects the CTSS/NOS form of the
 *		program statement.
 *  vector	is true if the target machine has vector processing
 *		capacities.
 *  bslash	is  1 if the -b option probably should be used, or
 *                 -1 if it probably shouldn't (subject to compiler options).
 */

struct system {
  char *name;
  int doloop;
  int prog;
  int vector;
  int bslash;
} systems[] = {
  { "unknown",  FALSE, FALSE, FALSE,  0 },
  { "alliant",  TRUE,  FALSE, TRUE,   0 },
  { "alpha",    TRUE,  FALSE, FALSE,  1 },
  { "convex",   TRUE,  FALSE, TRUE,  -1 },
  { "f2c",      TRUE,  FALSE, FALSE,  1 },
  { "f77",      FALSE, FALSE, FALSE,  0 },
  { "g77",      TRUE,  FALSE, FALSE,  1 },  /* -fbackslash is the default */
  { "gfortran", TRUE,  FALSE, FALSE, -1 },  /* -fno-backslash is default */
  { "hpux",     FALSE, FALSE, FALSE,  0 },
  { "linux",    TRUE,  FALSE, FALSE,  0 },
  { "sgi",      TRUE,  FALSE, FALSE,  0 },
  { "sun",      TRUE,  FALSE, FALSE,  1 },
  { "trace",    TRUE,  FALSE, FALSE,  0 },
  { "unicos",   FALSE, TRUE,  TRUE,  -1 },
  { "vms",      TRUE,  FALSE, FALSE, -1 }};

#define SYS_UNKNOWN   0
#define SYS_FX        1
#define SYS_ALPHA     2
#define SYS_CONVEX    3
#define SYS_F2C       4
#define SYS_F77       5
#define SYS_G77       6
#define SYS_GFORTRAN  7
#define SYS_HPUX      8
#define SYS_LINUX     9
#define SYS_SGI      10
#define SYS_SUN      11
#define SYS_TRACE    12
#define SYS_CFT      13
#define SYS_VMS      14
#define NSYS (sizeof(systems)/sizeof(struct system))

#define LOWER 90000	/* Ratty uses statement labels above this number. */
#define MAXDEPTH 32	/* Max nesting of do-loops than Ratty can handle. */
#define MAXLINE 256	/* Max length of a line. */

static FILE *out;
static int dbslash,offlevel,level,sys,label,uselabel,depth,lines,routines,chars;
static int comment,in_routine,gflag,lflag,uflag;
static int loops[MAXDEPTH],dowhile[MAXDEPTH];
struct link_list {char *name; struct link_list *fwd;} *defines,*incdir;
static char *ptrdiff;

private int continuation,quoted=FALSE;
private int lower,increment;

/****************************************************************************/

int main(int argc,char *argv[])
{
  char *s,*infile,*outfile,*sysname;
  int i;
  FILE *in;

  /* Initalize everything in sight. */
  incdir = defines = NULL;
  in_routine = dbslash = comment = gflag = lflag = uflag = FALSE;
  offlevel = level = uselabel = depth = lines = routines = chars= 0;
  lower = LOWER;
  increment = 1;
  ptrdiff = "integer";

  /* Handle the command line. */
  sysname = "unknown";
  infile = NULL;
  outfile = NULL;

  for(i=1;i<argc;i++){
    s = argv[i];
    if(*s == '-'){				/* Handle flags. */
      s++;
      while(*s)switch(*s++){
	case 'a': if (sizeof(long)==8) ptrdiff = "integer*8";   break;
        case 'b': dbslash = TRUE;				break;
	case 's': if(++i < argc) sysname = argv[i];		break;
	case 'd':
	case 'D': if(++i < argc) defines = add_list(defines,argv[i]);	break;
	case 'n': if(i+2 < argc) {
                    get_labelnos(argv[i+1],argv[i+2]); i += 2;
                  };
                  break;
	case 'i':
	case 'I': if(++i < argc) incdir  = add_list(incdir,argv[i]);	break;
	case 'p': 
	case 'P': if(++i < argc) ptrdiff = argv[i];		break;
	case 'g': gflag=TRUE; 					break;
        case 'l': lflag = TRUE;                                 break;
	case 'u': uflag = TRUE;                                 break;
        case 'h':
	case '?': usage();		/* will also exit */
	default:  fprintf(stderr,"### Ignored unrecognized flag %c\n",*(s-1));
						break;
      }
    } else if(infile == NULL) infile = s;
    else if(outfile == NULL ) outfile = s;
    else fprintf(stderr,"### Argument %s ignored\n",s);
  }

  label = lower - increment;

  /* Open the input and output files. If not file is present, assume
     standard input and output. */
  if(infile == NULL) in = stdin;
  else in = fopen(infile,"r");
  if(in==NULL){
    fprintf(stderr,"### Failed to open input file\n");
    exit(2);
  }
  if(outfile == NULL) out = stdout;
  else out = fopen(outfile,"w");
  if(out==NULL){
    fprintf(stderr,"### Failed to open output file\n");
    exit(2);
  }
  if(gflag && infile==NULL) gflag=FALSE;  /* handle idiots */

  /* Determine the target compiler type, and define a few parameters. */
  sys = 0;
  while(sys < NSYS && strcmp(systems[sys].name,sysname) != 0) sys++;
  if(sys == NSYS){
    message("Unrecognised system type, basic system assumed");
    sys = 0;
  }
  defines = add_list(defines,sysname);
  if(systems[sys].vector) defines = add_list(defines,"vector");

  /* Check for sensible use of the -b flag. */
  if((systems[sys].bslash > 0 && !dbslash) ||
     (systems[sys].bslash < 0 &&  dbslash))
    fprintf(stderr,"### Warning: Should the -b switch be used?\n");

  /* Process the input file, creating the output. Then close down. */
  process(in,infile);
  Fclose(in);
  Fclose(out);
  return 0;
}

/****************************************************************************/

/* Get lowest label to use, and the increment to apply. */

private void get_labelnos(slower,sinc)
char *slower,*sinc;
{
  char *s;
  lower = 0;

  s = slower; lower = 0;
  while(*s >= '0' && *s <= '9') lower = 10*lower + *s++ - '0';
  if(*s != 0){
    fprintf(stderr,"### Bad label start: %s\n",slower);
    exit(2);
  }

  s = sinc; increment = 0;
  while(*s >= '0' && *s <= '9') increment = 10*increment + *s++ - '0';
  if(*s != 0){
    fprintf(stderr,"### Bad label increment: %s\n",sinc);
    exit(2);
  }
}

/****************************************************************************/

/* Process a newly opened input file, writing code to the output.
   Note: process() is called recursively. */

private void process(in,infile)
FILE *in;
char *infile;
{
  int type,lineno,lineno1,indent,bracketting, glines=0, oldglines;
  char *s,*s0,line[MAXLINE],pathname[MAXLINE],token[MAXLINE],msg[MAXLINE];
  char gfile[MAXLINE];
  FILE *in2;

  if(gflag)strcpy(gfile,infile);            /* init -g filename */

  while((type = get_line(in,line))){
    lines++;
    if(gflag){
        glines++;
        sprintf(msg,"# %d \"%s\"\n",glines,gfile);
        textout(msg);
    }
    if(*line == 0);			/* Do nothing if a null line. */
    else if(type == '#')cppline(line);	/* Handle preprocessor line. */
    else if(offlevel != 0);		/* Do nothing if output is off. */
    else if(type == 'c'){		/* Handle a comment. */
      textout(line); textout("\n");
    } else {				/* Handle FORTRAN. */
      in_routine = TRUE;
      s = progtok(line,token,&indent,&lineno,&bracketting);
      if(lineno >= lower && lineno <= uselabel)
	message("RATTY may have used this label number");
      label = max(label,lineno);

      if(!strcmp(token,"program") && systems[sys].prog){
        /* Program statement. */
	blankout(indent); textout("program "); textout(s);
	textout("(tty,input=tty,output=tty)\n");

      } else if(!strcmp(token,"ptrdiff")){
        /* ptrdiff statement. */
        blankout(indent); textout(ptrdiff); textout(" "); textout(s);
        textout("\n");

      } else if(!systems[sys].doloop &&
	       (!strcmp(token,"do") || !strcmp(token,"dowhile"))){
        /* DO and DOWHILE loops. */
	if(depth == MAXDEPTH){
	  message("DO/DOWHILE loops nested too deep");
	} else {
	  if(lineno == 0 && !strcmp(token,"dowhile")){
	    label += increment;
	    lineno1 = lineno = uselabel = label;
	  }else if(!strcmp(token,"do")){
	    label += increment;
	    lineno1 = uselabel = label;
	  }else lineno1 = lineno;
	  loops[ ++depth ] = lineno1;
	  if(!strcmp(token,"do")){
	    dowhile[depth] = FALSE;
	    if(lineno != 0) {labelout(lineno); blankout(indent-5);}
	    else blankout(indent);
	    textout("do " ); numout(lineno1); textout(" "); textout(s);
	    textout("\n");
	  } else {
	    dowhile[depth] = TRUE;
	    labelout(lineno1); blankout(indent-5);
	    textout("if"); textout(s);
	    while(bracketting){
	      textout("\n");
	      type = get_line(in,line);
	      if(type != '*'){
		message("Bad DOWHILE statement");
		bracketting = 0;
	      }else{
		s = skipexp(line+6,&bracketting);
		if(*s) message("Bad DOWHILE statement");
	      }
	      textout(line);
	    }
	    textout("then\n");
	  }
	}

      } else if(!strcmp(token,"enddo") && !systems[sys].doloop){
        /* ENDDO statement. */
	if(depth == 0) message("Found ENDDO without corresponding DO");
	else {
	  if(lineno != 0){
	    labelout(lineno); blankout(indent-5); textout("continue\n");

	  }
	  if(dowhile[depth]){
	    blankout(indent); textout("goto "); numout(loops[depth]);
	    textout("\n");
	    blankout(indent); textout("endif\n");
	  } else {
	    labelout(loops[depth]); blankout(indent-5); textout("continue\n");
	  }
	  depth --;
	}

      } else if(!strcmp(token,"include")){
        /* Process an INCLUDE file. */
	s++;
	s0 = token;
	while(*s && *s != '\'')*s0++ = *s++;
	*s0 = 0;
	in2 = incopen(token,pathname);
	if(in2 == NULL){
	  sprintf(msg,"Error opening include file %s",token);
	  message(msg);
	  textout(line); textout("\n");
	} else {
	  if(lineno != 0){
	    labelout(lineno); blankout(indent-5); textout("continue\n");
	  }
          oldglines = glines;
	  sprintf(msg,"c >>> %s\n",pathname);
	  textout(msg);
	  process(in2,token);
	  sprintf(msg,"c <<< %s\n",pathname);
	  textout(msg);
	  Fclose(in2);
          glines = oldglines;
	}

      } else if(!strcmp(token,"end")){
        /* Procedure END */
	if(depth != 0)message("Ended a procedure with DO/DOWHILE unclosed");
	depth = 0;
	label = LOWER - 1;
	uselabel = 0;
	textout(line); textout("\n");
	routines++;
	in_routine = FALSE;

      } else if(!strcmp(token,"implicitnone") ||
		!strcmp(token,"implicitundefined")){
        /* IMPLICIT NONE statement. */
	if(sys == SYS_VMS || sys == SYS_FX || sys == SYS_CONVEX || 
           sys == SYS_SUN || sys == SYS_F2C) {
	  blankout(indent); textout("implicit none\n");
	} else if(sys == SYS_F77){
	  blankout(indent); textout("implicit undefined (a-z)\n");
	}

      } else {
        /* Some other line. */
	textout(line); textout("\n");
      }
    }
  }
}

/****************************************************************************/

private void message(text)
char *text;
{
  fprintf(stderr,"### %s\n",text);
  fprintf(out,"c### %s\n",text);
}

/****************************************************************************/

private void textout(text)
char *text;
{
  int l;
  if(!chars ) comment = (*text == 'c');
  l = strlen(text); chars += l;
  fprintf(out,"%s",text);
  if(*(text+l-1) == '\n'){
    chars --;
    l = (chars > 72 && !comment);
    chars = 0;
    comment = FALSE;
    if(l) message("Line longer than 72 chars");
  }
}

/****************************************************************************/

private void numout(label)
int label;
{
  char num[10];
  sprintf(num,"%d",label);
  fprintf(out,"%s",num);
  chars += strlen(num);
  comment = FALSE;
}

/****************************************************************************/

private void labelout(label)
int label;
{
  fprintf(out,"%5d",label);
  chars += 5;
  comment = FALSE;
}

/****************************************************************************/

private void blankout(blanks)
int blanks;
{
  chars += blanks;
  while(blanks-- > 0)Fputc(' ',out);
  comment = FALSE;
}

/****************************************************************************/

/* Convert a string to lower case. */

private void lowercase(string)
char *string;
{
  while(*string){
    if(*string >= 'A' && *string <= 'Z') *string = *string - 'A' + 'a';
    string++;
  }
}

/****************************************************************************/

private char *getparm(line,token)
char *line,*token;
{
  while(*line == ' ')line++;				/* Skip white. */
  while(*line != ' ' && *line != 0)*token++ = *line++;	/* Copy token. */
  *token = 0;						/* Terminate token. */
  return(line);
}

/****************************************************************************/

private void cppline(line)
char *line;
{
  int ok,loop;
  char *s,token[MAXLINE],parm[MAXLINE];

  /* Skip leading blanks, c's and hashes. */
  while(*line == ' ' ||
        *line == '#' ||
        *line == 'c' ||
        *line == 'C' ||
        *line == '*') line++;
  line = getparm(line,token);
  lowercase(token);

  /* Determine what the directive is. */
  if(!strcmp(token,"ifdef") || !strcmp(token,"ifndef")){
    /* #ifdef or #ifndef derective. */
    line = getparm(line,parm);
    level++;
    if(!offlevel){
      if(!*parm)message("Bad #ifdef statement taken as satisfied.");
      else {
	ok = isdefine(parm);
	if((ok && !strcmp(token,"ifndef")) || (!ok && !strcmp(token,"ifdef")))
	  offlevel = level;
      }
    }

  } else if(!strcmp(token,"else")){
    /* #else directive. */
    if(!level) message("Unexpected #else ignored");
    else if(!offlevel) offlevel = level;
    else if(offlevel == level) offlevel = 0;

  } else if(!strcmp(token,"endif")){
    /* #endif directive. */
    if(!level) message("Unexpected #endif ignored");
    else if(offlevel == level--) offlevel = 0;

  } else if(!strcmp(token,"define")){
    /* #define directive. */
    if(!offlevel){
      line = getparm(line,parm);
      if(!*parm)message("Bad #define statement ignored.");
      else defines = add_list(defines,parm);
    }
    
  } else if(!strcmp(token,"maxloop")){
    /* #maxloop directive. Issue a "short loop" directive if appropriate. */
    line = getparm(line,parm);
    loop = 0;
    s = parm;
    while(*s) loop = 10*loop + *s++ - '0';
    if(!loop) message("Bad #maxloop directive");
    else if(offlevel);
    else if(sys == SYS_CFT && loop <= 64) textout("cdir$ shortloop\n");
    else if(sys == SYS_FX  && loop <= 32) textout("cvd$  shortloop\n");

  } else if(!strcmp(token,"ivdep")){
    /* #ivdep directive. Issue a "no dependency" directive. */
    if(offlevel);
    else if(sys == SYS_CFT) textout("cdir$ ivdep\n");
    else if(sys == SYS_FX ) textout("cvd$  nodepchk\n");
    else if(sys == SYS_CONVEX) textout("c$dir no_recurrence\n");

  } else if(!strcmp(token,"nooptimize")){
    /* #nooptimize directive. Do not optimize the following loop. */
    if(offlevel);
    else if(sys == SYS_CFT)
      textout("cdir$ nextscalar\n");
    else if(sys == SYS_FX ){
      textout("cvd$  noconcur\n");
      textout("cvd$  novector\n");
    }

  } else {
    /* Unrecognised directive. */
    message("Unrecognised directive ignored");
    textout("c"); textout(token); textout("\n");
  }
}

/****************************************************************************/

/* This gets the first token out of a line.  Tokens can be:
     program
     do
     dowhile
     enddo
     end
     include
     implicit none
     DEC continuation format

   Some checks are also made for "standard" format of comments and
   parameter statements. */

private char *progtok(line,token,indent,lineno,bracketting)
char *line,*token;
int *indent,*lineno,*bracketting;
{
  char *s,*t,*u;

  /* Determine the statement label and the indentation. */
  s = line;
  *bracketting = 0;
  *lineno = 0;
  while(*s == ' ')s++;
  while(*s >= '0' && *s <= '9' && s - line < 5) *lineno = 10 * *lineno + *s++ - '0';
  while(*s == ' ')s++;
  *indent = s - line;

  t = token;
  u = s;

  if (*indent == 5);
    /* A standard continuation line. Just ignore it. */

  else if ((*s < 'a' || *s > 'z') && (*s < 'A' || *s > 'Z')){
    /* DEC format for fortran continuation. */
    *(line+5) = '*';
    *s = ' ';
    *indent = 5;
    message("VMS format continuation converted");

  } else {
    while(*s == ' ' ||
         (*s >= 'a' && *s <= 'z') ||
         (*s >= 'A' && *s <= 'Z') ||
          *s == '$' ||
          *s == '_' ||
         (*s >= '0' && *s <= '9')) {
    /* Some form of statement. Handle it correctly. Copy, ignoring blanks, to
       the first  non-alphanumeric code. Convert to lower case on the way. */

    if(*s == ' ')s++;
    else if(*s >= 'A' && *s <= 'Z') *t++ = *s++ + 'a' - 'A';
    else 			    *t++ = *s++;

    }
  }
  *t = 0;			/* Zero terminate. */

  /* Make sure the token is really what it looks like. */
  if(!strcmp(token,"implicitnone") || !strcmp(token,"enddo")
				   || !strcmp(token,"end")){
    if(*s) *token = 0;
  } else if(!strcmp(token,"implicitundefined")){
    if(*s != '(') *token = 0;
  } else if(!strcmp(token,"include")){
    if(*s != '\'') *token = 0;
  } else if(!strncmp(token,"program",7)){
    if(*s)*token = 0;
    else  token[7] = 0;

  } else if(!strncmp(token,"ptrdiff",7)){
    /* ptrdiff declaration */
    if(*s == '(')s = skipexp(s,bracketting);
    if(*s == ',' || *s == 0) token[7]=0;
    else *token=0;


  } else if(!strcmp(token,"dowhile")){
    /* DOWHILE statement. */
    if(*skipexp(s,bracketting)) *token = 0;

  } else if(!strncmp(token,"do",2)){
    /* DO statement. */
    if((token[2] >= '0' && token[2] <= '9') || *s != '=') *token = 0;
    else {
      if(*skipexp(s+1,bracketting) != ',') *token = 0;
      else token[2] = 0;
    }

  } else {
    /* Make a few checks to see if its one of the other ANSI statements. */    
    *token = 0;
  }

  /* Skip over the part of the line which corresponds to the token.  Remember
     that FORTRAN allows embedded blanks. */
  s = u;
  t = token;
  while(*t){
    if(*s != ' ')t++;
    s++;
  }
  while(*s == ' ')s++;

  return(s);
}

/****************************************************************************/

/* This skips over an expression.  It returns a pointer to the first non-blank
   character after the expression. */

private char *skipexp(s,bracketting)
char *s;
int *bracketting;
{
  int inchar,inexp,depth;

  depth = *bracketting;
  inchar = FALSE;
  inexp = TRUE;
  while(*s && inexp){
    if(*s == '\'')inchar = !inchar;
    else if(inchar);
    else if(*s == '(') depth++;
    else if(*s == ')') depth--;
    else if(!depth)inexp = *s != ',' && *s != '=';
    if(inexp)s++;
  }
  *bracketting = depth;
  return(s);
}

/****************************************************************************/

/* Get a line from the input file, and make a quick determination about what
   it is.  This returns: 'c' if its a comment, ' ' for a normal line, '#' for
   a preprocessor line, and 0 for EOF. */

private int get_line(in,line)
FILE *in;
char *line;
{
  char *s;
  int type;

  if(fgets(line,MAXLINE,in) == NULL)return(0);

  /* Trim trailing blanks. */
  s = line + strlen(line);
  while(s-line >= 0 && *s <= ' ')*s-- = 0;

  if(!*line){
    /* Handle a blank line. */
    type = 'c';
    if(in_routine) Strcpy(line,"c");

  } else if(!strncmp(line, "#",1) ||
            !strncmp(line,"C#",2) ||
            !strncmp(line,"c#",2)){
    /* Handle a RATTY directive. */
    type = '#';

  } else if(*line == 'c' || *line == 'C' || *line == '*' || *line == 'd' ||
	   *line == 'D' ){
    /* A comment. */
    *line = 'c';
    type = 'c';


  } else {
    /* Must be a normal line. Reformat it. */
    type = reformat(line);
  }
  return(type);
}

/****************************************************************************/

/* Reformat a normal line. Get rid of tabs. Look for special characters.
   Check for unbalanced quotes. Strip off trailing ! comments. */

private int reformat(s)
char *s;
{
  char *s0,*t,line[MAXLINE],c;
  int pad,first,type;

/* Make a copy of the input, so we can overwrite it. */

  Strcpy(line,s);
  s0 = s;

  t = line;
  continuation=FALSE;
  while(*t == ' ')t++;
  while(*t >= '0' && *t <= '9' && t-s < 5) t++;
  while(*t == ' ')t++;
/* A standard continuation line. */
  if(t-line == 5) continuation=TRUE;
/* DEC format for fortran continuation. */
  else if((*t < 'a' || *t > 'z') && (*t < 'A' || *t > 'Z')) continuation=TRUE;
  if ( !continuation && quoted ) message("Quotes are not balanced");
  if ( !continuation ) quoted = FALSE;

/* Scan through the line. */
  type = ' ';
  first = TRUE;
  t = line;
  while((c = *t++)){
    if(c == ' ') *s++ = ' ';
    else if(c == '\t'){
      pad = 8 * ( (s - s0)/8 + 1 ) - (s - s0);
      while(pad-- > 0)*s++ = ' ';
    } else{
      if( (s-s0) == 5 ||
	(first && (s-s0) > 5 && (c <'a' || c > 'z') && (c < 'A' || c > 'Z')) ){
	*s++ = ' ';
	*(s0+5) = '*';
	first = FALSE;
	type = '*';
      } else if(c == '\''){
	quoted = !quoted;
	*s++ = c;
      } else if(quoted){
	if(c == '\\' && dbslash)*s++ = '\\';
	*s++ = c;
      } else if(c == '!'){
	while(*t)t++;
        while(*(s-1) == ' ')s--;
      } else if(lflag && isupper(c)){
        *s++ = tolower(c);
      } else if(uflag && islower(c)){
        *s++ = toupper(c);
      } else *s++ = c;
      first = FALSE;
    }
  }
  *s = 0;
  return(type);
}

/****************************************************************************/

/* Indicate that a thing is defined. */

private struct link_list *add_list(list,name)
struct link_list *list;
char *name;
{
  struct link_list *s,*t;

  t = (struct link_list *)Malloc(sizeof(struct link_list));
  t->fwd = NULL;
  t->name = (char *)Malloc(strlen(name)+1);
  Strcpy(t->name,name);

/* Link it in. */

  if(list == NULL) return(t);

  for(s=list; s->fwd != NULL; s = s->fwd);
  s->fwd = t;
  return(list);
}

/****************************************************************************/

/* Attempt to open an include file. */

private FILE *incopen(name,pathname)
char *name,*pathname;
{
  char c, *s;
  int  i;
  struct link_list *t;
  FILE *fd;

  /* Try the plain, unadulterated name. */
  if ((fd = fopen(name,"r")) != NULL) {
    getcwd(pathname,MAXLINE);
    if (strncmp(pathname, "/private", 8) == 0) {
      /* Strip off MacOSX automounter mount point. */
      s = pathname;
      for (i = 8; i < MAXLINE; i++, s++) {
        *s = pathname[i];
        if (*s == '\0') break;
      }
    }
    strcat(pathname,"/");
    strcat(pathname,name);
    return(fd);
  }

  /* Otherwise try appending it to the list of include directories. */
  for(t = incdir; t != NULL; t = t->fwd){
    s = t->name;
    Strcpy(pathname,s);
    c = *(s + strlen(s) - 1);
    if(isalnum(c))Strcat(pathname,"/");
    strcat(pathname,name);
    if((fd = fopen(pathname,"r")) != NULL) break;
  }

  return(fd);
}

/****************************************************************************/

/* Check whether a thingo is defined. */

private int isdefine(name)
char *name;
{
  struct link_list *t;
  t = defines;
  while(t != NULL && strcmp(t->name,name))t = t->fwd;
  if(t != NULL)return(TRUE);
  return(FALSE);
}

/****************************************************************************/

private void usage()
{
   int i;

   fprintf(stderr,"RATTY: Version %s\n",VERSION_ID);
   fprintf(stderr,"Usage: \n");
   fprintf(stderr,"ratty [-s system] [-I incdir] [-D symbol] [-bglu] "
                  "[-n start inc] [in] [out]\n");
   fprintf(stderr,"-s system    target compiler/system (");
   for (i=1; i<NSYS; i++) fprintf(stderr," %s",systems[i].name);
   fprintf(stderr," )\n");
   fprintf(stderr,"-I incdir    add dir to include directory\n");
   fprintf(stderr,"-D symbol    set a symbol to be defined for #ifdef\n");
   fprintf(stderr,"-n start inc set generated label start and inc\n");
   fprintf(stderr,"-b           double slashes in quoted textstrings\n");
   fprintf(stderr,"-g           include # references for dbx\n");
   fprintf(stderr,"-l           convert program text to lower case\n");
   fprintf(stderr,"-u           convert program text to upper case\n");
   fprintf(stderr,"-h           help (this list)\n");
   fprintf(stderr,"-?           help (this list)\n");
   exit(0);
}

