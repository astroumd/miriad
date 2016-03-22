#define VERSION_ID "(version 3.1a [4-sep-2012])"

/* The following section will be extracted by the doc program into a         */
/* .doc file.  The Miriad package needs such files.                          */

/*= miriad - shell program to run miriad tasks */
/*& pjt */
/*: tools */
/*+
  Miriad is a command-line interface to run Miriad tasks.

  The directory MIRBIN contains all miriad tasks, whereas the directory
  MIRPDOC must contain the appropriate doc files (help files with
  directives on available keywords). The invocation 'miriad -h'
  will display all command line options.

  Syntax for the list of acceptable commands that follows:
      [x] : x is an optional argument.
      <x> : x is an identifier like a file name or a keyword.

    inp [<task>]            Show current values of keywords [for a task].
    set                     Show value of all keywords.
    set <key>               Show value of the <key> keyword.
    set <key> <value>       Set keyword <key> to <value>.
    <key>=<value>           Set keyword <key> to <value>.
    unset <key> [<key2>...] Unset value[s] of keyword[s].
    task [<task>]           Show [Set] default taskname.

    go [-b] [-r <run>] [<task>] Run [task].
        -b                      Run the task in background.
        -r <run>                Run as "<run> <task>".
    gob [<task>]            Run [task] in the background.

    help ?                  A list of programs to execute.
    help [<task>]           Help [on task].
    help miriad             This help.
    ?                       This help.

    er <key>                Line edit a keyword.
    view [<task>]           Edit the keyword file [for task].
    load/save [<file>]      Load/Save a global keyword file.
    tget/tput [-l] [<task>] Load/Save a keyword file [for a task].
        -l                      Local copy instead of in $DEFDIR.
    setenv <env> <value>    Set an environment variable.
    unsetenv <env>          Unset an environment variable.
    reset                   Reset (remove) all keywords.
    input <file>            Process commands from input file.
    source <file>           Process commands from input file.
    cd [dir]                Show [Set] the current directory.
    version                 Display how Miriad was compiled.
    exit/end                Exit program saving variables.
    quit                    Quit program but do not save variables.
    <task> [<par> ...]      Unknown commands are passed to the shell.

  Any unrecognized commands are passed on to the parent shell for
  execution.  Thus, the command "ls -l $HOME" will return a listing
  of the files in the user's home directory on UNIX.  UNIX aliases
  are also understood for a number of shells.  In VMS, the command
  "DIR SYS$LIBRARY" would work equally well.
 */
/*--                                                                    */
/************************************************************************/
/*  COMPILE DEFINE OPTIONS:                                             */
/*                                                                      */
/*  Use as:  -Doption (unix) or /DEFINE=(option=1) (VMS) in CC          */
/*                                                                      */
/*   <option>      <explanation>                                        */
/*   --------      -------------                                        */
/*  PATHSEARCH     If set, full $PATH is searched instead of $MIRBIN    */
/*                   (not applicable in VMS).                           */
/*  INTERRUPT      If set, interrupts like ^\, ^C, ^Y are caught.       */
/*  GETENV         Set this if your OS has no char *getenv().           */
/*  NEWENV         If variables can be added to **environ.              */
/*  EXECL          If foreign commands can use execl() to get an alias. */
/*  READLINE       Use the readline GNU command line editor.            */
/*		     This not only gives BASH command line editing,     */
/*		     but also file completion.                          */
/*  DOER           If set, use the cle_exe line editor.                 */
/*                                                                      */
/*  vms            Set if this is being compiled on VMS.                */
/*  sun            Set if this is being compiled on a Sun.              */
/*  convex         Set if this is being compiled on the Convex.         */
/*  hpux           Set if this is being compiled on a HP-UX machine.    */
/*  linux          Set is this is being compiled on a Linux machine.    */
/*                                                                      */
/************************************************************************/

#ifdef __convexc__
#ifndef convex
#define convex 1
#endif
#endif

#ifdef sun
#define PATHSEARCH 1
#define INTERRUPT  1
#define NEWENV     1
#define EXECL      1
#endif

#ifdef linux
#define PATHSEARCH 1
#define INTERRUPT  1
#define NEWENV     1
#define EXECL      1
#endif

#ifdef convex
#define PATHSEARCH 1
#define INTERRUPT  1
#define NEWENV     1
#define EXECL      1
#endif

#ifdef vms
#define INTERRUPT  1
#define NEWENV     1
#endif

#ifdef hpux
#define PATHSEARCH 1
#define INTERRUPT  1
#endif

/************************************************************************/
/*                                                                      */
/*  History:                                                            */
/*    rjs  Dark-ages Original version.                                  */
/*    pjt   4dec89   Warning when no write permission in save_vars.     */
/*    rjs  21feb90   Minor enhancements, suggested by Brian Glendenning.*/
/*    pjt  26feb90   Changed environment variables, more messages       */
/*    rjs   5mar90   Merged PJT and RJS versions.                       */
/*    pjt  12mar90   don't write keyfile when not needed                */
/*    pjt  15mar90   'gob' is same as 'go' with backgrounding           */
/*    pjt  16mar90   added save, and help with no options               */
/*    pjt   9apr90   some more help                                     */
/*    rjs  26apr90   Looks in local directory for .doc files. On VMS,   */
/*                   it checks for the foreign command definition,      */
/*                   before overwriting it with its own.                */
/*    pjt   6may90   compile option to search $PATH in Unix (execvp)    */
/*    pjt  13may90   -b BIN -d DEF -p PDOC options                      */
/*    pjt  15jun90   added TASK command - to set default task - setenv  */
/*    pjt  20jun90   quit/exit is now different - load/save have def    */
/*    pjt  10jul90   catch a few signals                                */
/*    pjt   6aug90   new INPUT command                                  */
/*    pjt  21aug90   Testing TCL - for Version 2.x                      */
/*                   added dounset to get_vars                          */
/*    pjt   6sep90   some TCL cleanup - lastexit with -s switch         */
/*                   reset keywords cleans ALL variables                */
/*    pjt  18sep90   cd command                                         */
/*    pjt  15nov90   local shell commands must use ! now                */
/*                   doset() can now have multiple values               */
/*    pjt  19dec90   removed complaint line when shell command used     */
/*    pjt  23jan91   introduced MIRPAGER env.var. (needed for doc)      */
/*    pjt  22feb91   4.1c fixed erroneous switchings of taskname -      */
/*         27feb91   4.1d ALIAS command - added to SET command          */
/*          5apr91   4.2 merged Sanjay's code (unreleased)              */
/*          6may91       -d implemented                                 */
/*    rjs  22may91   Fixed bug in doset()                               */
/*    pjt  22may91   Fixed new VMS problems - set interrupt on in VMS   */
/*         26may91   child signalling from Sanjay added                 */
/*    pjt  28may91   V1.6 added BLANK code for setting variables        */
/*         12jun91   V1.7 added optional GNU's READLINE library         */
/*	   21jun91        renamed environ to menviron for cray		*/
/*    pjt  16jan92   V1.8 history in readline.                          */
/*    pjt  11feb92   V1.9 Fixed bug in filename() when 'name' starts    */
/*                   with an '/'.  Also, merged in Bob Saults work:     */
/***                                                                    */
/***    rjs  13aug90   Different pager for help command.                */
/***    rjs  21mar91   The "er" command.                                */
/***    rjs  22may91   Fixed the "er" command!                          */
/***    rjs  22may91   Stole various things from pjt's version.         */
/***    rjs  20jun91   Various mods to the help command.                */
/***    rjs  29aug91   Auto TPUT on "go" to $MIRDEF, TGET from $MIRDEF, */
/***    rjs  16sep91   Better error message.                            */
/***    rjs   9oct91   -l flag for tget and tput.                       */
/***                                                                    */
/*    jm   24mar92   V2.0 Cleaned up code to ANSI level, removed        */
/*                   MULTISET option, and added hasharg function.       */
/*                   Removed TCL support and ifdef'd the "er" command.  */
/*    pjt  28jul92   removed declaration problems sun vs. convex        */
/*    pjt  20dec92   fixed bug in tget -> extra parameter to get_vars   */
/***    rjs   1may92   Wait for subprocess to finish, in docommand.     */
/***    rjs  21may92   Warn when unrecognised variables are set.        */
/***    rjs   4jun92   Increased some buffers. Better bounds checking.  */
/***                   Removed much pjt bs.                             */
/***    rjs  11sep92   View puts files in MIRDEF.                       */
/***    rjs  19dec92   -Dhpux. csh -cf when shedding a command.         */
/***    rjs  05dec92   -Dhpux is the only thing to shed with csh -cf.   */
/***                                                                    */
/*    jm   20jul93   V3.0 Merged Bob and Peter's versions of this code. */
/*                   Also added path control for bin and doc environs.  */
/*           05aug93  Ooooooooops, the 256 is now 512                   */
/***    mjs  31aug93  add trivial explicit casts for Solaris            */
/*    jm   13aug97   Changed getline() to properly handle quotes        */
/*                   (both single and double quotes). Also changed      */
/*                   string terminator from NULL to Null ('\0').        */
/*                   Also undef'd TRUE/FALSE if previously defined.     */
/*   pjt   14feb00   preset compile defaults for linux			*/
/*   pjt    4sep2012 also report the $MIR/VERSION contents              */
/*                                                                      */
/*    ToDo anyhow:                                                      */
/*      check earlier if lastexit can be written, otherwise complain    */
/*      aliases do not support strings with blanks - they are tokenized */
/*    PJT's ideas:                                                      */
/*      - redirect stdout/stderr to something useful, or:               */
/*      - tee stdout/stderr to a general miriad.log like lastexit       */
/*        [some work just before the execv(P) is needed?                */
/*      - cursor history                                                */
/*      - allow 'go histo in=newfile' and                               */
/*        'go in=newfile' if histo was already the default????          */
/*      - allow a PATH in -d, -b, -p etc.  (NEMO findpath)              */
/*     Sanjay Bhatnagar idea's                                          */
/*      - expand any regular expression in key values                   */
/*        (for e.g.in=~sanjay/test/test.dat instead of in=/usr2/sanjay  */
/*         /test/test.dat)                                              */
/*                                                                      */
/************************************************************************/

#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <errno.h>
/* I have moved <errno.h> up to the standard library section. */
/* Is there any site still not conforming to this?? [20jul93 jm] */

#if (INTERRUPT == 1)
#include <signal.h>
#endif

#ifdef sun
#include <malloc.h>
#endif

#ifdef sun
/* Are there any other machines that can also call this??? [20jul93 jm] */
#include <unistd.h>
#endif

/*   These come from SYS5 versions which do not always have them def'd. */
/*   I need them for 3b1 (mx68k).                                       */
/*   This is for access(2) - enventually POSIX will solve this kludge.  */
#ifndef R_OK
#define R_OK 4
#endif
#ifndef X_OK
#define X_OK 1
#endif

#define MAXARGS   64
#define MAXBUF   512
#define HASHSIZE 127
#define MAXINPUT  10
#define MAXPATHS  20

#ifdef TRUE
#undef TRUE
#endif
#define TRUE       1

#ifdef FALSE
#undef FALSE
#endif
#define FALSE      0

/* Define a Null character if it is missing. */
#ifndef Null
#define Null '\0'
#endif

typedef struct variable {       /* Structure definition for variables. */
    char *name;
    char *value;
    int user;
    int taught;
    struct variable *fwd;
} VARIABLE;

static VARIABLE *hashtable[HASHSIZE];

static struct {
    char *name;
    char *value;
} args[MAXARGS];

static char taskname[MAXBUF];         /* The current default taskname. */
static char *lastexit="lastexit";    /* Default name of lastexit file. */

static int debug_level = 0;           /* Debug output written when >0. */
static int input_level = 0;         /* Nesting level of INPUT command. */
static FILE *fpinput[MAXINPUT];       /* Open files for INPUT command. */

static char *binpath[MAXPATHS];          /* -b: specifies binary path. */
static char *docpath[MAXPATHS];   /* -d: specifies documentation path. */
static char binstring[MAXBUF];         /* Storage for bin path string. */
static char docstring[MAXBUF];         /* Storage for doc path string. */

static char *defdir;                  /* -p: specifies save directory. */

/* forward references to make (ansi) compilers happy. */

#if (GETENV == 1)
char *localgetenv();                /* Handle the local getenv() case. */
#define getenv localgetenv
#endif

void ini_miriad();
int do_miriad(), end_miriad();

void dohelp(), doq(), doversion();
void doinput(), doreset();
void get_vars(), save_vars(), doset(), dounset(), doinp(), dogo();
void dosetenv(), dounsetenv(), dotask();
void doload(), dosave(), docommand(), doview();
void dotput(), dotget();
void motd(), filename(), bug(), docd();
void set_defaults();
void newenv();
char *expand();
int my_getline();
int task_args();
int findname();

#if (DOER == 1)
  void doer();
#endif /* DOER */

#if (READLINE == 1)
  char *readline();
  static void ini_readline();
  static void end_readline();
  static void stripwhite();
#endif /* READLINE */

#ifdef unicos
  void unicos_check();
#endif

#if (INTERRUPT == 1)
  void review();
#endif /* INTERRUPT */

char **menviron;  /* point to environment - not used in vms */

/************************************************************************/
int main(ac, av, ep)
int ac;         /* number of arguments + 1 */
char *av[];     /* progname + arguments */
char *ep[];     /* environment strings ENV=val */
{
  int more = 1;
  int argc;
  char buffer[MAXBUF];
  char *argv[MAXARGS];

  (void)printf("Miriad shell %s\n", VERSION_ID);
  system("echo MIRIAD VERSION:;cat $MIR/VERSION");

  ini_miriad(ac, av, ep);                /* Initialize lot's of stuff. */

#if (READLINE == 1)
  ini_readline();
#endif /* READLINE */

  while (more > 0) {
    /* Get a token list. */
    argc = my_getline(buffer, MAXBUF, argv, MAXARGS, (char *)NULL);
    if (argc > 0)                     /* If there are any arguments... */
      more = do_miriad(argc, argv); /* ... call dispatcher to execute. */
  }

#if (READLINE == 1)
  end_readline();
#endif /* READLINE */

  return(0);
} /* main */

/************************************************************************/
void ini_miriad(ac, av, ep)
int ac;
char *av[];
char *ep[];
{
  register int i;
  char name[MAXBUF];
  char *startup[2];

  menviron = ep;                 /* Set environment for global access. */
  set_defaults(ac, av);            /* (Re)Set defaults from arguments. */

#if (INTERRUPT == 1)
  if (debug_level) (void)printf("Catching signals SIGTERM, SIGQUIT, SIGINT\n");
  signal(SIGTERM, review);                         /* Catch interrupts */
  signal(SIGQUIT, review);                              /* for review; */
  signal(SIGINT,  review);                             /* and ^C also. */ 
#endif /* INTERRUPT */

  taskname[0] = Null;          /* Make sure this is Null at the start. */

  for (i = 0; i < HASHSIZE; i++)         /* Initialize the hash table. */
    hashtable[i] = (VARIABLE *)NULL;

  filename(name, defdir, lastexit, "");
  get_vars(name);                         /* Read the "lastexit" file. */
  motd();                         /* Print out the message of the day. */

                               /* Set name for Miriad startup aliases. */
#ifdef vms
  filename(name, "SYS$LOGIN", "miriad", ".rc");
#else
  filename(name, "HOME", "", ".miriadrc");
#endif

  if (access(name, R_OK) == 0) {      /* If startup file indeed found. */
    (void)printf("[Reading %s]\n", name);
    startup[0] = "input";                /* Build do_miriad arguments. */
    startup[1] = name;
    (void)do_miriad(2, startup);               /* Execute the command. */
  }

  return;
} /* ini_miriad */

/************************************************************************/
/* general miriad command dispatcher */
int do_miriad(argc, argv)
int argc;
char **argv;
{
    int more = 1;
    static int Qkeys = 0;    /* 1/0 if keys have/haven't been updated. */

    if (argc == 0);               /* Do nothing if no args were given. */
    else if(!strcmp(argv[0],"set"))      {doset(argc,argv); Qkeys=1; }
    else if(!strcmp(argv[0],"unset"))    {dounset(argc,argv); Qkeys=1; }
    else if(!strcmp(argv[0],"inp"))      {doinp(argc,argv); }
    else if(!strcmp(argv[0],"go"))       {dogo(0,argc,argv); }
    else if(!strcmp(argv[0],"gob"))      {dogo(1,argc,argv); }
#if (DOER == 1)
    else if(!strcmp(argv[0],"er"))       {doer(argc, argv); Qkeys=1; }
#endif /* DOER */
    else if(!strcmp(argv[0],"setenv"))   {dosetenv(argc,argv); }
    else if(!strcmp(argv[0],"unsetenv")) {dounsetenv(argc,argv); }
    else if(!strcmp(argv[0],"help"))     {dohelp(argc,argv); }
    else if(!strcmp(argv[0],"view"))     {doview(argc,argv); Qkeys=1; }
    else if(!strcmp(argv[0],"save"))     {dosave(argc,argv); }
    else if(!strcmp(argv[0],"load"))     {doload(argc,argv); }
    else if(!strcmp(argv[0],"tget"))     {dotget(argc,argv); }
    else if(!strcmp(argv[0],"tput"))     {dotput(argc,argv); }
    else if(!strcmp(argv[0],"input"))    {doinput(argc,argv); }
    else if(!strcmp(argv[0],"source"))   {doinput(argc,argv); }
    else if(!strcmp(argv[0],"reset"))    {doreset(argc,argv); }
    else if(!strcmp(argv[0],"cd"))       {docd(argc,argv); }
    else if(!strcmp(argv[0],"?"))        {doq(); }
    else if(!strcmp(argv[0],"version"))  {doversion(); }
    else if(!strcmp(argv[0],"task"))     {dotask(argc,argv); }
    else if(!strcmp(argv[0],"exit"))     {more = 0; }
    else if(!strcmp(argv[0],"quit"))     {more = 0; Qkeys = 0; }
    else if(!strcmp(argv[0],"end"))      {more = 0; }
    else                                 {docommand(argc,argv); }

    if (more == 0)
      more = end_miriad(Qkeys);

    return(more);
} /* do_miriad */

/************************************************************************/
int end_miriad(Qkeys)
int Qkeys;
{
  char path[MAXBUF];

  if (input_level > 0) {            /* If exit was from an input file, */
    input_level--;         /* decrease the stack count of input files, */
    (void)fclose(fpinput[input_level]);            /* close that file, */
    return(1);                       /* and continue processing input. */
  }

  filename(path, defdir, lastexit, "");
  if (Qkeys > 0)   /* Set to 1 if keyword save requested; 0 otherwise. */
    save_vars(path);           /* Save all the parameters in lastexit. */
  else
    (void)fprintf(stderr, "### Warning: Variables not saved in %s\n", path);

  return(0);
} /* end_miriad */

/************************************************************************/
int my_getline(outbuf, maxbuf, argv, maxargs, cmdnow)
char *outbuf;
int maxbuf;
char *argv[];
int maxargs;
char *cmdnow;
/*
  This prompts and reads a line from STDIN or the most recently opened
  input file.  It breaks the line into tokens.  If the second token is
  an equals sign, then this prepends the "set" command to the list of
  returned tokens.

  outbuf is a character string large enough to hold the input command
  line (although no size checking is done); maxbuf is the declared
  maximum number of characters in the string outbuf; argv[] is an array
  of pointers to strings representing the returned tokens; maxargs is
  the declared maximum array size of argv[]; and if cmdnow is not a
  NULL pointer, then it is taken as a command to be parsed (tokenized)
  and returned.

  Returns the number of elements of argv[] filled; 0 if the command
  line was empty.
------------------------------------------------------------------------*/
{
  char *s;
  char quote;
  char prompt[40];
  char buffer[MAXBUF];
  int n, inter, doset, i;

  if (cmdnow != (char *)NULL) { /* Input is from a passed in argument. */
    (void)printf("[Executing: %s]\n", cmdnow);
    (void)strcpy(buffer, cmdnow);
  } else if (input_level > 0) {      /* Input reading from input file. */
    if (fgets(buffer, maxbuf, fpinput[input_level-1]) == (char *)NULL)
      (void)strcpy(buffer, "exit");
  } else {                     /* otherwise, the input is interactive. */
    (void)sprintf(prompt, "%s%% ", (*taskname ? taskname : "Miriad"));

#if (READLINE == 1)
    for (;;) {                     /* Read until something is present. */
      if ((s = readline(prompt)) != (char *)NULL) {
        stripwhite(s);      /* Get rid of leading and trailing blanks. */ 
        if (*s != Null) {
           (void)strcpy(buffer, s);
           free(s);
           s = (char *)NULL;
           break;
        }
      }
      if (s != (char *)NULL) free(s);
    }
#else
    (void)printf("%s", prompt);
    clearerr(stdin);             /* Clears junk from the input buffer. */
    if (fgets(buffer, maxbuf, stdin) == (char *)NULL) 
      (void)strcpy(buffer,"exit");
#endif /* READLINE */
  }

  if (buffer[strlen(buffer)-1] == '\n')     /* Need to overwrite '\n'? */
      buffer[strlen(buffer)-1] = Null;               /* ...then do it. */

#if (READLINE == 1)
  add_history(buffer);
#endif  

  /* Expand any symbols. */
  s = expand(outbuf, buffer);
  if (s == (char *)NULL)                         /* Nothing to expand. */
    (void)strcpy(outbuf, "");
  else                            /* Terminate the string with a NULL. */
    *s = Null;
  s = outbuf;                 /* s now points to the expanded command. */

  /* Break the string into individual tokens. */
  inter = 1;
  n = 0;
  doset = 0;
  quote = Null;
  while (*s != Null) {
    if (quote == Null) {              /* Not currently within a quote. */
      if (isspace(*s)) {
        inter = 1;
        *s = Null;
      } else if ((*s == '=') && (n == 1)) {
        doset = 1;
        inter = 1;
        *s = Null;
      } else if (inter) {
        if ((n + 1) >= maxargs) {
          (void)fprintf(stderr,
            "### Warning: Number of inputs exceeds internal storage space.\n");
          break;
        }
        argv[n++] = s;
        inter = 0;
      }
      if ((*s == '"') || (*s == '\'')) {
        quote = *s;       /* Set this to the char that ends the quote. */
      }
    } else if (*s == quote) {    /* Inside a quote; read till matched. */
      quote = Null;              /* Reset this to mean not in a quote. */
    }
    s++;
  }
/*
 *  If it was a set command, shift everything down by one,
 *  add the "set" to the top of the list, and increase the count.
 */
  if (doset) {
    for (i = n; i > 0; i--) argv[i] = argv[i-1];
    argv[0] = "set";
    n++;
  }

  return(n);
} /* getline */

/************************************************************************/
/* Compute the hash table value of STRING. */
static int hasharg(string)
char *string;
{
  char *t;
  int hashval;

  if ((t = string) == (char *)NULL)
    return(0);

  hashval = 0;
  while (*t != Null)
    hashval += *t++;

  return(hashval % HASHSIZE);
}

/************************************************************************/
static char *translate(var)
char *var;
/*
    Return the value of a symbol or environment variable.
------------------------------------------------------------------------*/
{
  char *t;
  VARIABLE *v;

  if ((var == (char *)NULL) || (*var == Null))
    return((char *)NULL);

  /* Find the "local" variable. */

  for (v = hashtable[hasharg(var)]; v != (VARIABLE *)NULL; v = v->fwd)
    if (strcmp(var, v->name) == 0)
      break;

  if (v != (VARIABLE *)NULL)
    return(v->value);

  /* If this failed, check for an environment variable. */

#ifdef vms
  t = (char *)NULL;
#else
  t = getenv(var);
#endif

  if (t == (char *)NULL)
    (void)fprintf(stderr,"### No such variable: [%s].\n", var);

  return(t);
}

/************************************************************************/
char *expand(s, t)
char *s, *t;
/*
   Expand any $ characters into the equivalent text or
   environment variables.
------------------------------------------------------------------------*/
{
  char *u;
  char var[MAXBUF];

  if ((t == (char *)NULL) || (*t == Null))
    return((char *)NULL);

  while ((s != (char *)NULL) && (*t != Null)) {
    if (*t == '$') {
      t++;
      u = var;
      while (isalnum(*t) || *t == '_' ) *u++ = *t++;
      *u = Null;
      u = translate(var);
      s = expand(s, u);
    } else *s++ = *t++;
  }

  return(s);
}

/************************************************************************/
void doset(argc, argv)
int argc;
char *argv[];
{
  char *s, *t;
  char prev;
  char cat[MAXBUF]; 
  int hashval, i;
  VARIABLE *v;

  /* Check the arguments. */

  if (argc == 1) {                   /* Print all values - and return. */
    for (i = 0; i < HASHSIZE; i++) {
      for (v = hashtable[i]; v != (VARIABLE *)NULL; v = v->fwd) {
        if (v->value != (char *)NULL)
          (void)printf("%8s = %s\n", v->name, v->value);
      }
    }
    return;
  } 

  /* Find the value of the parameter stored in the hash table. */

  hashval = hasharg(argv[1]);
  for (v = hashtable[hashval]; v != (VARIABLE *)NULL; v = v->fwd) {
    if (strcmp(argv[1],v->name) == 0)
      break;
  }

  if (argc == 2) {    /* Print the value of one variable - and return. */
    if ((v != (VARIABLE *)NULL) && (v->value != (char *)NULL))
      (void)printf("%8s = %s\n",v->name, v->value);
    else
      (void)printf("Variable [%s] not been set yet.\n", argv[1]);
    return;
  }

  /* Create the variable if needed and fill in the value. */

  if (v == (VARIABLE *)NULL) {
    if ((v = (VARIABLE *)malloc(sizeof(VARIABLE))) == (VARIABLE *)NULL) {
      (void)fprintf(stderr,
        "### Warning: Out of memory trying to allocate a variable.\n");
      return;
    }
    if ((v->name = (char *)malloc(strlen(argv[1]) + 1)) == (char *)NULL) {
      (void)fprintf(stderr,
        "### Warning: Out of memory trying to allocate a string.\n");
      (void)free((char *)v);
      return;
    }
    (void)strcpy(v->name, argv[1]);
    v->user = FALSE;
    v->taught = FALSE;
    v->value = (char *)NULL;
    v->fwd = hashtable[hashval];
    hashtable[hashval] = v;
  }

  if (!v->user && !v->taught && (input_level == 0))
    (void)printf("[Creating new variable %s]\n", argv[1]);
  v->user = TRUE;

  if (v->value != (char *)NULL)
    (void)free(v->value);
  v->value = (char *)NULL;

  /* Assemble all remaining arguments into the string cat. */
  (void)strcpy(cat, argv[2]);
  for (i = 3; i < argc; i++) {
    (void)strcat(cat, ",");
    (void)strcat(cat, argv[i]);
  }

  /* Remove any repeated commas. */
  prev = ',';
  for (t = s = cat; *t != Null; prev = *t++)
    if ((*t != ',') || (prev != ','))
      *s++ = *t;
  *s = Null;

  v->value = (char *)malloc(strlen(cat) + 1);  /* Get space for value. */
  if (v->value == (char *)NULL) {
    (void)fprintf(stderr,
      "### Warning: Out of memory trying to allocate a value.\n");
    return;
  }

  (void)strcpy(v->value, cat);               /* Copy the value string. */
  return;
} /* doset */

/************************************************************************/
void doreset(argc,argv)
int argc;
char *argv[];
/*
 * This routine needs to be upgraded: when the argument is 'all' it can
 * reset the whole hashtable, but when no argument is given, or the
 * name of an existing executable, it should only clear the variables
 * for that executable...
------------------------------------------------------------------------*/
{
  char path[MAXBUF];
  int i;
  VARIABLE *v, *next;

  filename(path, defdir, lastexit, ".bck");
  save_vars(path);
  (void)printf("[All keywords have been blanked - backup in file %s]\n", path);
  (void)printf("[Use 'load %s' to load them back]\n", path);

  for (i = 0; i < HASHSIZE; i++) {            /* Reset the HASH table. */
    for (v = hashtable[i]; v != (VARIABLE *)NULL; v = next){
      next = v->fwd;
      if (v->value) (void)free(v->value);
      (void)free(v->name);
      (void)free((char *)v);
    }
    hashtable[i] = (VARIABLE *)NULL;
  }
  return;
} /* doreset */

/************************************************************************/
void dounset(argc,argv)
int argc;
char *argv[];
{
  int i, hashval;
  VARIABLE *v;

  /* Handle all arguments as keywords to be unset. */
  for (i = 1; i < argc; i++) {
    hashval = hasharg(argv[i]);
    for (v = hashtable[hashval]; v != (VARIABLE *)NULL; v = v->fwd)
      if (strcmp(argv[i], v->name) == 0)
        break;

    if (v == (VARIABLE *)NULL) {
      (void)fprintf(stderr, "### %s: symbol [%s] was not found.\n",
        argv[0], argv[i]);
    } else {
      (void)printf("[%s %s]\n", argv[0], argv[i]);
      if (v->value != (char *)NULL)
        (void)free(v->value);
      v->value = (char *)NULL;
      v->user = FALSE;
    }
  }
  return;
} /* dounset */

#if (DOER == 1)
/************************************************************************/
void doer(argc, argv)
int argc;
char *argv[];
/*
  A quick edit of various keywords.
------------------------------------------------------------------------*/
{
  char outpath[MAXBUF], inpath[MAXBUF];
  int hashval;
  FILE *fd;
  VARIABLE *v;

  /* Check the arguments. */

  if (argc != 2) {
    (void)fprintf(stderr, "### %s: Incorrect number arguments.\n", argv[0]);
    return;
  }

  /* Find the variable. */

  hashval = hasharg(argv[1]);
  for (v = hashtable[hashval]; v != (VARIABLE *)NULL; v = v->fwd)
    if (strcmp(argv[1], v->name) == 0)
      break;

  /* If the variable was not found, give an error message. */

  if ((v == (VARIABLE *)NULL) || (v->value == (char *)NULL)) {
    (void)fprintf(stderr, "### %s: Variable [%s] was not found.\n",
      argv[0], argv[1]);
    return;
  }

  /* Write the variable to the line-editors file. */

  filename(inpath, "HOME", "cle_in", "");
  filename(outpath, "HOME", "cle_out", "");
  if ((fd = fopen(inpath,"w")) == (FILE *)NULL) {
    (void)fprintf(stderr,
      "### %s: Could not write to the (needed) file [%s].\n", argv[0], inpath);
  }

  (void)fprintf(fd, "     1 %s=%s\n", v->name, v->value);
  (void)fclose(fd);

  /* Spawn the line editor. */

  (void)system("cle_exe");

  /* Retrieve the variable. */

  get_vars(outpath);

  unlink(inpath);
  unlink(outpath);

  return;
} /* doer */
#endif /* DOER */

/************************************************************************/
void doinp(argc, argv)
int argc;
char *argv[];
{
  char *testname;
  int i, n;

  if (argc > 2)
    (void)fprintf(stderr, "### %s: Extra arguments on line ignored.\n",
      argv[0]);

  testname = ((argc > 1) ? argv[1] : taskname);

  if ((n = task_args(testname)) < 0){
    (void)fprintf(stderr, "### %s: Found no documentation on task [%s].\n",
      argv[0], testname);
  } else if(n == 0){
    if (argc > 1)
      (void)strcpy(taskname, argv[1]);
    (void)fprintf(stderr,"### %s: There are no parameters for task [%s].\n",
      argv[0], taskname);
  } else {
    if (argc > 1)
      (void)strcpy(taskname, argv[1]);
    (void)printf("  Task:   %s\n", taskname);
    for (i = 0; i < n; i++)
      (void)printf("  %-9s= %s\n", args[i].name,
        (args[i].value == (char *)NULL ? " " : args[i].value));
  }
  return;
} /* doinp */

/************************************************************************/
void doinput(argc, argv)
int argc;
char *argv[];
{
  if (argc > 2)
    (void)fprintf(stderr, "### %s: Extra arguments on line ignored.\n",
      argv[0]);

  if (argc == 1) {
    (void)fprintf(stderr, "### %s: no filename supplied.\n", argv[0]);
    return;
  }

  if ((input_level + 1) > MAXINPUT) {
    (void)fprintf(stderr, "### %s: Too many nested inputs in [%s].\n",
      argv[0], argv[1]);
    return;
  }

  fpinput[input_level] = fopen(argv[1], "r");
  if (fpinput[input_level] == (FILE *)NULL) {
    (void)fprintf(stderr, "### %s: file [%s] not found.\n", argv[0], argv[1]);
    return;
  }
  input_level++;
  return;
} /* doinput */

/************************************************************************/
void doview(argc, argv)
int argc;
char *argv[];
{
  char *viewer, *testname;
  char name[MAXBUF], command[MAXBUF];
  int i, n;
  FILE *fd;

  if (argc > 2)
    (void)fprintf(stderr, "### %s: Extra arguments on line ignored.\n",
      argv[0]);

  testname = (argc > 1 ? argv[1] : taskname);

  if ((n = task_args(testname)) < 0) {
    (void)fprintf(stderr, "### %s: Found no documenation on task [%s].\n",
      argv[0], testname);
  } else if (n == 0) {
    if (argc > 1)
      (void)strcpy(taskname, argv[1]);
    (void)fprintf(stderr, "### %s: There are no parameters for task [%s].\n",
      argv[0], taskname);
  } else {
    if (argc > 1)
      (void)strcpy(taskname, argv[1]);
    filename(name, defdir, taskname, ".def");
    if ((fd = fopen(name, "w")) == (FILE *)NULL) {
      (void)fprintf(stderr, "### %s: Failed to open [%s].\n", argv[0], name);
      return;
    }

    for (i = 0; i < n; i++)
      (void)fprintf(fd, "%-9s= %s\n", args[i].name,
        (args[i].value == (char *)NULL ? "" : args[i].value));
    (void)fclose(fd);

#ifdef vms
    viewer = "edit";
#else
    if ((viewer = getenv("VISUAL")) == (char *)NULL)
      if ((viewer = getenv("EDITOR")) == (char *)NULL)
        viewer = "vi";
#endif

    (void)sprintf(command, "%s %s", viewer, name);
    (void)system(command);
    get_vars(name);
  }
  return;
} /* doview */

/************************************************************************/
void dotput(argc, argv)
int argc;
char *argv[];
/*
------------------------------------------------------------------------*/
{
  char *task, *s;
  char path[MAXBUF];
  int i, n, dolocal;
  FILE *fd;

  task = (char *)NULL;
  dolocal = FALSE;
  for (i = 1; i < argc; i++) {
    s = argv[i];
    if (*s == '-')
      while (*++s != Null)
        switch (*s) {
          case 'l': case 'L':
            dolocal = TRUE;
            break;
          default:
            (void)fprintf(stderr,
              "### %s: Unrecognized flag [%c] ignored.\n", argv[0], *s);
        }
    else if (task == (char *)NULL) task = s;
    else (void)fprintf(stderr,"### %s: Ignoring argument: %s.\n", argv[0], s);
  }

  if (task == (char *)NULL) task = taskname;
  if (dolocal) filename(path, "", task, ".def");
  else         filename(path, defdir, task, ".def");

  n = task_args(task);
  if (n < 0) {
    (void)fprintf(stderr, "### %s: Found no documenation on task [%s].\n",
      argv[0], task);
    return;
  } else if (n == 0) {
    (void)fprintf(stderr, "### %s: There are no parameters for task [%s].\n",
      argv[0], task);
  } else {
    if ((fd = fopen(path, "w")) == (FILE *)NULL) {
      (void)fprintf(stderr, "### %s: Failed to open [%s].\n", argv[0], path);
      return;
    }

    for (i = 0; i < n; i++)
      if (args[i].value != (char *)NULL)
        (void)fprintf(fd, "%-9s= %s\n", args[i].name, args[i].value);
    (void)fclose(fd);
  }

  if (task != taskname)
    (void)strcpy(taskname, task);

  return;
} /* dotput */

/************************************************************************/
void dotget(argc, argv)
int argc;
char *argv[];
/*
------------------------------------------------------------------------*/
{
  char *task, *s;
  char path[MAXBUF];
  char *vals[MAXARGS];
  int n, narg, i, dolocal;

  task = (char *)NULL;
  dolocal = FALSE;
  for (i = 1; i < argc; i++) {
    s = argv[i];
    if (*s == '-')
      while (*++s != Null)
        switch (*s) {
          case 'l': case 'L':
            dolocal = TRUE;
            break;
          default:
            (void)fprintf(stderr,
              "### %s: Unrecognized flag [%c] ignored.\n", argv[0], *s);
        }
    else if (task == (char *)NULL) task = s;
    else (void)fprintf(stderr, "### %s: Ignoring argument %s.\n", argv[0], s);
  }
  if (task == (char *)NULL) task = taskname;
  if (dolocal) filename(path, "", task, ".def");
  else         filename(path, defdir, task, ".def");

  if (access(path,R_OK)) {
    (void)fprintf(stderr,"### %s: Could not access file: %s.\n", argv[0], path);
  } else {
    n = task_args(task);
    if (n < 0) {
      (void)fprintf(stderr,"### %s: Found no documentation on task %s.\n",
        argv[0], task);
      return;
    } else {
      narg = 1;
      vals[0] = "unset";
      for (i = 0; i < n; i++)
        if (args[i].value != (char *)NULL)
          vals[narg++] = args[i].name;
      if (narg > 1)
        dounset(narg, vals);
    }

    get_vars(path);
    if (task != taskname)
      (void)strcpy(taskname, task);
    doinp(1, argv);                  /* Display the key=val`s to user. */
  }
  return;
} /* dotget */

#ifdef vms
/************************************************************************/
void dogo(bg,argc,argv)                          /* GO command in VMS. */
int bg;                                          /* bg ignored in VMS. */
int argc;
char *argv[];
/*  VMS version (no backgrounding/spawning yet)
------------------------------------------------------------------------*/
{
  char *testname;
  char line[MAXBUF], parameter[MAXBUF];
  int i, n, table;
  struct {int length; char *pnt;} name, value;

#define LIB$K_CLI_GLOBAL_SYM 2
#define assign(descriptor,string) descriptor.length = strlen(string);\
                                  descriptor.pnt    = string

  if (bg) (void)fprintf(stderr,"### Warning: SPAWNing ignored.\n");
  if (argc < 1) return;
  if (argc > 2) (void)fprintf(stderr,
    "### %s: Extra arguments on line ignored.\n", argv[0]);

  testname = (argc > 1 ? argv[1] : taskname);
  n = task_args(argv[1]);
  if (n < 0) {
    (void)fprintf(stderr, "### %s: Found no documentation on task [%s].\n",
      argv[0], testname);
  } else {
    if (argc > 1)
      (void)strcpy(taskname, argv[1]);

    dotput(1, argv);            /* Write out the task definition file. */

    /* Check if the foreign command is defined. If not, define it. */
    assign(name, taskname);
    value.length = MAXBUF; value.pnt = line;
    if (lib$get_symbol(&name,&value) != 1) {
      table = LIB$K_CLI_GLOBAL_SYM;
      (void)sprintf(line, "$MIRBIN:%s.exe", taskname);
      assign(name, taskname); assign(value, line);
      lib$set_symbol(&name, &value, &table);
    }

/* Build up the command line. */

    (void)strcpy(line, taskname);
    for (i = 0; i < n; i++) { /* CHECK IF THIS STILL WORKS 15-jun-90 PJT */
      if (args[i].value != (char *)NULL) {
        (void)sprintf(parameter, " %s=%s", args[i].name, args[i].value);
        (void)strcat(line, parameter);
      }
    }
    (void)system(line);
  }
  return;

#undef LIB$K_CLI_GLOBAL_SYM
#undef assign

} /* dogo (VMS) */
#else
/************************************************************************/
void dogo(bg, argc, argv)                       /* GO command in UNIX. */
int bg;
int argc;
char *argv[];
/*      Unix version
------------------------------------------------------------------------*/
{
  char *s, *task, *runner;
  char **t;
  char path[MAXBUF], parameter[MAXBUF];
  char *arg[MAXARGS + 3];
  int i, n, pid, length;
  int back;

  if (argc < 1) return;

  back = bg;
  runner = (char *)NULL;
  task = taskname;
  for (i = 1; i < argc; i++) {
    s = argv[i];
    if (*s == '-')
      while (*++s)
        switch (*s) {
          case 'b': case 'B':
            back = 1;
            break;
          case 'r': case 'R':
            if (++i < argc) runner = argv[i];
            break;
          default:
            (void)fprintf(stderr,
              "### %s: Unrecognized flag [%c] ignored.\n", argv[0], *s);
        }
    else if (task == taskname) task = s;
    else (void)fprintf(stderr, "### %s: Ignoring argument %s.\n", argv[0], s);
  }

  n = task_args(task);
  if (n < 0) {
    (void)fprintf(stderr,"### %s: Found no documentation on task [%s].\n",
      argv[0], task);
  } else {
    if (taskname != task) /* without this guard, we can crash on OS X */
      (void)strcpy(taskname, task);

    dotput(1, argv);            /* Write out the task definition file. */

    t = arg;		     /* Pointer to the start of the arguments. */
    if (runner != (char *)NULL) {
      *t++ = runner;
      (void)strcpy(path, runner);
    } else {
#if (PATHSEARCH == 1)
      (void)strcpy(path, taskname);    /* Shell searches for exe file. */
#else
      if (findname(path, binpath, taskname, "", X_OK)) {
        (void)fprintf(stderr, "### %s: Failed to find executable [%s].\n",
          argv[0], taskname);
        return;
      }
#endif
    }
    *t++ = taskname;

    /* Build up the argument list. */

    length = 0;
    for (i = 0; i < n; i++) {
      if (args[i].value != (char *)NULL) {
        s = parameter + length;
        length += strlen(args[i].name) + strlen(args[i].value) + 2;
        if (length > MAXBUF) {
          (void)fprintf(stderr,
            "### %s: Out of argument space to execute command\n", argv[0]);
          return;
        }
        (void)sprintf(s, "%s=%s", args[i].name, args[i].value);
        *t++ = s;
      }
    }
    *t = (char *)NULL;               /* Terminate arg[] list properly. */

    if (debug_level) {
      (void)printf("Command:\n");
      for (t = arg; *t != (char *)NULL; t++)
        (void)printf(" %s", *t);
      (void)printf("\n");
    }

#ifdef unicos
    unicos_check(taskname);
#endif

/* Spawn off the command. */

    pid = fork();
    if (pid < 0)
      bug("### go: Failed to fork a child process.");
    if (pid == 0) {                               /* Inside child now. */
      if (back > 0)
        (void)fprintf(stdout, "[Job %s running in background]\n", taskname);

#if (PATHSEARCH == 1)
      execvp(path, arg);                    /* Let shell look for exe. */
#else
      execv(path, arg);             /* Path contains full name of exe. */
#endif

      (void)fprintf(stderr, "### %s: Errno = %d.\n", argv[0], errno);
      perror("### go");
      bug("go: Failed to exec the subprocess.");
    } else {                                        /* Parent process. */
      if (debug_level)
        (void)fprintf(stdout, "[Parent jobid = %d : bg=%d]\n", pid, back);

      if (back == 0)
        while(pid != wait((int *)NULL))
          /* NULL */ ;  /* Wait for the proper (this) child to finish. */
    }
  }
  return;
} /* dogo (non-VMS) */
#endif

#ifdef unicos
/************************************************************************/
void unicos_check(task)
char *task;
/*
  Check if the executable of the task is in the executable directory. If
  not, get it from the appropriate CFS directory.
------------------------------------------------------------------------*/
{
  char path[MAXBUF], cfs[MAXBUF], command[MAXBUF];

  filename(path, "MIRBIN", task, "");
  if (access(path, X_OK)) {
    filename(cfs, "BINCFS", task, "");
    (void)sprintf(command, "cfs get %s:%s", path, cfs);
    (void)system(command);
  }
  return;
} /* unicos_check */
#endif

/************************************************************************/
static void showbin()
/*
------------------------------------------------------------------------*/
{
    char *s, *pager;
    char path[MAXBUF], command[MAXBUF];
    int j;

    if ((pager = getenv("PAGER")) == (char *)NULL)
      pager = "more";

#ifdef vms
    (void)strcpy(command, "dir");
#else
    (void)strcpy(command, "ls -C");
#endif        

    j = 0;
    while ((s = binpath[j++]) != (char *)NULL) {
      filename(path, s, "", "");
      (void)strcat(command, " ");
      (void)strcat(command, path);
    }

#ifndef vms
    (void)strcat(command, " | ");
    (void)strcat(command, pager);
#endif        

    (void)printf("%s\n", command);
    (void)system(command);
    return;
} /* showbin */

/************************************************************************/
void dohelp(argc, argv)
int argc;
char *argv[];
/*
------------------------------------------------------------------------*/
{
  char *pager, *mirpager, *hp;
  char path[MAXBUF], command[MAXBUF];
  int j, k;

/* Determine the thing we want help on. */

  k = 0;
  hp = taskname;
  if (argc > 1) {
    if (*(argv[1]) != '-') {
      k = 1;
      hp = argv[1];
    }
  }
  if (*hp == Null)
    hp = "miriad";

/* Determine the pathname of the help file. */

  if (findname(path, docpath, hp, ".doc", R_OK))
    path[0] = Null;

  if (strcmp("?", hp) == 0) {
    (void)printf("Try 'help miriad' for general help\n");
    (void)printf("Otherwise try 'help <task>'\n");
    (void)printf("The following are available tasks:\n\n");
    showbin();
  } else if (path[0] == Null) {
    if (strcmp("miriad", hp) == 0) {
      doq();
    } else {
      (void)fprintf(stderr,
        "### %s: Cannot find and/or read help for [%s].\n", argv[0], hp);
      (void)fprintf(stderr,
        "### %s: Try: '?' or '%s ?' for other types of help.\n",
        argv[0], argv[0]);
    }
  } else {

#ifdef vms

    pager = "type/page";
    (void)sprintf(command, "%s %s", pager, path);

#else

    if ((pager = getenv("PAGER")) == (char *)NULL)
      pager = "more";
    if ((mirpager = getenv("MIRPAGER")) == (char *)NULL)
      mirpager = "cat";

    (void)sprintf(command, "%s %s", mirpager, path);
    for (j = k + 1; j < argc; j++) {
      (void)strcat(command, " ");
      (void)strcat(command, argv[j]);
    }
    (void)strcat(command, " | ");
    (void)strcat(command, pager);

#endif

    (void)system(command);
  }
  return;
} /* dohelp */

/************************************************************************/
void doq()
/*
------------------------------------------------------------------------*/
{

#define MESG(a,b) (void)printf("%-24s %s\n", a, b)

    (void)printf("Miriad is a very simple front end to run Miriad commands.\n");
    (void)printf("\nSyntax for list below:\n");
    (void)printf("\t[x] are optional arguments.\n");
    (void)printf("\t<x> are identifiers like file names or keywords.\n\n");

    MESG("inp [<task>]",       "Show current values of keywords [for a task].");
    MESG("set",                "Show value of all keywords.");
    MESG("set <key>",          "Show value of the <key> keyword.");
    MESG("set <key> <value>",  "Set keyword <key> to <value>.");
    MESG("<key>=<value>",      "Set keyword <key> to <value>.");
    MESG("unset <key> [<key2>...]", "Unset value[s] of keyword[s].");
    MESG("task [<task>]",      "Show [Set] default taskname.");

#ifdef vms
    MESG("go [<task>]",        "Run [task].");
#else
    MESG("go [-b] [-r <run>] [<task>]", "Run [task].");
    MESG("    -b",             "Run the task in background.");
    MESG("    -r <run>",       "Run the task as '<run> <task>'.");
    MESG("gob [<task>]",       "Run [task] in the background.");
#endif /* vms */

    MESG("help [<task> [-k <key>]]", "Help [on task['s keyword]].");
    MESG("?",                  "This help.");

#if (DOER == 1)
    MESG("er <key>",           "Line edit a keyword.");
#endif /* DOER */
    MESG("view [<task>]",      "Edit the keyword file [for task].");
    MESG("load/save [<file>]", "Load/Save a global keyword file.");
    MESG("tget/tput [-l] [<task>]", "Load/Save a keyword file [for a task].");
    MESG("    -l",             "Local copy instead of in $DEFDIR.");
    MESG("setenv <env> <value>", "Set an environment variable.");
    MESG("unsetenv <env>",     "Unset an environment variable.");
    MESG("reset",              "Reset (remove) all keywords.");
    MESG("input <file>",       "Process commands from input file.");
    MESG("source <file>",      "Process commands from input file.");
    MESG("cd [dir]",           "Show [Set] the current directory.");
    MESG("version",            "Display how Miriad was compiled.");
    MESG("exit/end",           "Exit program saving variables.");
    MESG("quit",               "Quit program but do not save variables.");
    MESG("<task> [<par> ...]", "Unknown commands are passed to the shell.");
    (void)printf("\n");
    return;

#undef MESG

} /* doq */

/************************************************************************/
void dosave(argc, argv)
int argc;
char *argv[];
/*
    If an argument is given, assume it is the name of the save file;
    otherwise, use the default task name.
------------------------------------------------------------------------*/
{
  char path[MAXBUF];

  if (argc > 1) {
    filename(path, defdir, argv[1], "");
  } else {
    filename(path, defdir, taskname, ".def");
  }

  save_vars(path);
  return;
} /* dosave */

/************************************************************************/
void doload(argc, argv)
int argc;
char *argv[];
/*
------------------------------------------------------------------------*/
{
  char path[MAXBUF];

  if (argc > 1) {
    filename(path, defdir, argv[1], "");
  } else {
    filename(path, defdir, taskname, ".def");
  }

  get_vars(path);
  return;
} /* doload */

/************************************************************************/
void docd(argc, argv)
int argc;
char *argv[];
/*
------------------------------------------------------------------------*/
{
    if (argc == 1) {  /* If only one argument, show current directory. */

#ifdef vms
      (void)system("show default");
#else
      (void)system("pwd");
#endif

    } else if (argc == 2) {                       /* Change directory. */
      if (chdir(argv[1]) != 0)
        (void)fprintf(stderr, "### %s: Failed to change to directory: %s.\n",
          argv[0], argv[1]);
    } else {                                                 /* Error! */
      (void)fprintf(stderr, "Usage: %s [<directory>]\n", argv[0]);
    }
    return;
} /* docd */

/************************************************************************/
void dotask(argc, argv)
int argc;
char *argv[];
/*
------------------------------------------------------------------------*/
{
  if(argc > 1)
    (void)strcpy(taskname, argv[1]);
  else
    (void)printf("Current default task is [%s].\n", taskname);
  return;
} /* dotask */

/************************************************************************/
void dosetenv(argc, argv)
int argc;
char *argv[];
/*
------------------------------------------------------------------------*/
{
    if (argc < 3)
      (void)fprintf(stderr, "### Usage: %s env_var value\n", argv[0]);
    else
      newenv(argv[1], argv[2]);
    return;
} /* dosetenv */

/************************************************************************/
void dounsetenv(argc, argv)
int argc;
char *argv[];
/*
------------------------------------------------------------------------*/
{
    if (argc < 2)
      (void)fprintf(stderr, "### Usage: %s env_var\n", argv[0]);
    else
      newenv(argv[1], "");
    return;
} /* dounsetenv */

/************************************************************************/
void docommand(argc, argv)
int argc;
char *argv[];
/*
------------------------------------------------------------------------*/
{
  char *s;
  char buffer[MAXBUF];
  int i, status;
  static char *shell = (char *)NULL;     /* Remember the user's shell. */

  (void)strcpy(buffer, "");
  for (i = 0; i < argc; i++) {      /* Put the arguements into buffer. */
    (void)strcat(buffer, argv[i]);
    (void)strcat(buffer, " ");
  }
  s = buffer;
  while (isspace(*s)) s++;                        /* Skip white space. */
  if ((*s == Null) || (*s == '#')) /* Ignore blank lines or comment... */
    return;                           /* ...lines starting with a '#'. */

#ifdef vms

  (void)system(buffer);    /* Execute it by the host cmd. interpreter. */

#else /* !vms */
#if (EXECL != 1)

  (void)system(buffer);    /* Execute it by the host cmd. interpreter. */

#else                 /* In UNIX: pass it such that aliases are known. */

  if ((i = fork()) < 0) {                                    /* Error! */
    (void)fprintf(stderr, "### Command: Failed to fork a child process.\n");
    return;
  } else if (i == 0) {                               /* Child process. */
    if (shell == (char *)NULL)    /* Get the user's shell (only once). */
      shell = getenv("SHELL");

#ifdef hpux

    execl("/bin/csh", "csh", "-c", buffer, (char *)NULL);

#else

    if (shell == (char *)NULL)                    /* No default shell? */
      execl("/bin/sh", "sh", "-c", buffer, (char *)NULL);
    else
      execl(shell, shell, "-c", buffer, (char *)NULL);

#endif /* hpux */

    (void)fprintf(stderr, "### Command: Errno = %d\n", errno);
    (void)perror("### Command");
    bug("### Command: Failed to exec the child subprocess");
  } else {                                          /* Parent process. */

#if (INTERRUPT == 1)
    signal(SIGTERM, SIG_IGN);       /* Ignore interrupts by the parent */
    signal(SIGQUIT, SIG_IGN);                 /* until the child dies. */
    signal(SIGINT,  SIG_IGN);
#endif /* INTERRUPT */

    while (i != wait(&status))           /* Wait for the proper child. */
      /* NULL */ ;

#if (INTERRUPT == 1)
    signal(SIGTERM, review);             /* Restore status of signals. */
    signal(SIGQUIT, review);
    signal(SIGINT,  review);
#endif /* INTERRUPT */

  }

#endif /* !EXECL */
#endif /* vms */

  return;
} /* docommand */

/************************************************************************/
void get_vars(name)
char *name;
/*
------------------------------------------------------------------------*/
{
  char *s;
  char *argv[3];
  char line[MAXBUF];
  FILE *fd;

  if ((fd = fopen(name, "r")) == (FILE *)NULL) {
    s = name + strlen(name) - 8;
    if (s < name) s = name;
    if (strcmp(s, "lastexit") != 0)
      (void)fprintf(stderr, "### File [%s] could not be opened.\n", name);
    return;
  }

  argv[0] = "set";
  (void)printf("[All variables retrieved from %s]\n", name);

  while (fgets(line, MAXBUF, fd) != (char *)NULL) {
    s = line;
    while (isspace(*s)) s++;                           /* Skip blanks. */
    argv[1] = s;                                         /* A keyword. */
    while (*s != Null && !isspace(*s) && *s != '=') s++;
    while (*s != Null && (isspace(*s) || *s == '='))  /* Terminate it. */
      *s++ = Null;
    argv[2] = s;                             /* Point to the argument. */
    while (*s != Null && !isspace(*s) && *s != '\n') s++;
    *s = Null;                                    /* End the argument. */

    if(*argv[2] != Null) 
      doset(3, argv);
    else
      dounset(2, argv);
  }

  (void)fclose(fd);
  return;
} /* get_vars */

/************************************************************************/
void save_vars(name)
char *name;
/*
------------------------------------------------------------------------*/
{
  char line[MAXBUF];
  int i, nkeys;
  FILE *fd;
  VARIABLE *v;

  nkeys = 0;
  for (i = 0; i < HASHSIZE; i++)    /* Search to see if any are there. */
    for (v = hashtable[i]; v != (VARIABLE *)NULL; v = v->fwd)
      if (v->value != (char *)NULL)
        nkeys++;

  if (nkeys == 0) {                     /* If no keywords are found... */
    (void)printf("[Variables not saved - no changes were made]\n");
    return;                          /* ... then don't write them out. */
  }

  /* First a check if writing the file is OK; we don't want to overwrite
   * a file that doesn't seem to look like a keyword file..., surely. */

  if ((fd = fopen(name, "r")) != (FILE *)NULL) {  /* Check that file! */
    while (fgets(line, MAXBUF, fd) != (char *)NULL) {
        if ((int)strlen(line) > 0) {
          if (strchr(line, '=') != (char *)NULL) {
            break;   /* OK, found an '=', assume it's OK to overwrite. */
          } else {
            for (i = 0; (line[i] != Null && isspace(line[i])); i++)
              /* NULL */ ;
            if ((line[i] != Null) && (line[i] != '#')) {
              (void)fprintf(stderr,
                "[Will not overwrite keywords to the file [%s];\n", name);
              (void)fprintf(stderr, "it doesn't look like a keyword file.]\n");
              return;
            }
          }
        }
    }
    (void)fclose(fd);                         /* Close the file again. */
  } 
    
  if ((fd = fopen(name, "w")) == (FILE *)NULL) {
    (void)fprintf(stderr,
      "### Warning: Could not write to file [%s].\n", name);
    return;            /* Perhaps we should allow a y/n type-question? */
  }

  for (i = 0; i < HASHSIZE; i++)
    for (v = hashtable[i]; v != (VARIABLE *)NULL; v = v->fwd)
      if (v->value != (char *)NULL)
        (void)fprintf(fd, "%s=%s\n", v->name, v->value);

  (void)fclose(fd);
  (void)printf("[All variables saved in the file %s]\n", name);
  return;
} /* save_vars */

/************************************************************************/
int task_args(task)
char *task;
/*
  This gets the arguments, and their values, for a particular task.
  Returns -1 if the ".doc" file can not be opened; otherwise, it returns
  the number of keywords read.
------------------------------------------------------------------------*/
{
  char line[MAXBUF], keyword[MAXBUF];
  int n, hashval;
  FILE *fd;
  VARIABLE *v;

  if ((findname(line, docpath, task, ".doc", R_OK)) ||
      ((fd = fopen(line, "r")) == (FILE *)NULL)) {
    return(-1);
  }

  /* Scan the .doc file for the keywords. */
  n = 0;
  while (fgets(line, MAXBUF, fd) != (char *)NULL) {
    if (sscanf(line, "%%A %s", keyword) == 1) {

      /* Find the value of the parameter stored in the hash table. */
      hashval = hasharg(keyword);
      for (v = hashtable[hashval]; v != (VARIABLE *)NULL; v = v->fwd)
        if (strcmp(keyword, v->name) == 0)
          break;
      if (v == (VARIABLE *)NULL) {
        v = (VARIABLE *)malloc(sizeof(VARIABLE));
        if (v == (VARIABLE *)NULL) {
          (void)fprintf(stderr,
            "### Warning: Out of memory trying to allocate a variable.\n");
          return(-1);
        }
        if ((v->name = (char *)malloc(strlen(keyword) + 1)) == (char *)NULL) {
          (void)fprintf(stderr,
            "### Warning: Out of memory trying to allocate a string.\n");
          (void)free((char *)v);
          return(-1);
        }
        (void)strcpy(v->name, keyword);
        v->user = FALSE;
        v->value = (char *)NULL;
        v->fwd = hashtable[hashval];
        hashtable[hashval] = v;
      }
      v->taught = TRUE;

/* Save the name. */

      if (n >= MAXARGS) {
        (void)fprintf(stderr,
          "### Warning: Internal error: Too many arguments.\n");
        return(-1);
      }
      args[n].name = v->name;
      args[n].value = v->value;
      n++;
    }
  }
  (void)fclose(fd);

  return(n);
} /* task_args */

/************************************************************************/
void filename(out, envvar, name, type)
char *out, *envvar, *name, *type;
/*
  This makes a filename from the input components.
  In VMS 'envvar' is a logical, rest (Unix) treats it as an environment
  variable.  If the 'name' starts with an '/', then the environment
  variable is not prepended.
------------------------------------------------------------------------*/
{
  char *s;

#ifdef vms
  if ((envvar != (char *)NULL) && (*envvar != Null)) {
    if ((s = getenv(envvar)) == (char *)NULL) {
      (void)sprintf(out, "%s:%s%s", envvar, name, type);
    } else {                          /* but still allow an escape.... */
      (void)sprintf(out, "%s%s%s", s, name, type);
    }
  } else {
    (void)sprintf(out, "%s%s", name, type);
  }
#else
  if ((envvar != (char *)NULL) && (*envvar != Null) && (*name != '/')) {
    if ((s = getenv(envvar)) == (char *)NULL) {
      /* old way...; now, let it go through...
      (void)fprintf(stderr,
        "### Unable to find environment variable [%s].\n", envvar);
      (void)sprintf(out, "%s%s", name, type);
      */
      s = envvar;
      (void)sprintf(out, "%s/%s%s", s, name, type);
    } else {
      (void)sprintf(out, "%s/%s%s", s, name, type);
    }
  } else {
    (void)sprintf(out, "%s%s", name, type);
  }
#endif
  if (debug_level)
    (void)printf("[FILENAME: %s]\n", out);
  return;
} /* filename */

/************************************************************************/
int findname(out, envvar, name, type, mode)
char *out;
char *envvar[];
char *name, *type;
int mode;
/*
  Loop through the environment list until a file is found that matches
  the input MODE.  The input MODE is one of the acceptable inputs to the
  level 2 command access.
  This routine returns 0 on success (along with OUT filled with the
  expanded path); 1 on failure to match (OUT set to NULL).
------------------------------------------------------------------------*/
{
    char *s;
    int j;

    j = 0;
    while ((s = envvar[j++]) != (char *)NULL) {
      if (strcmp(s, ".") == 0) s = "";
#ifdef vms
      else if (strcmp(s, "HOME") == 0) s = "SYS$LOGIN";
#endif /* vms */

      filename(out, s, name, type);
      if (access(out, mode) == 0)
        return(0);
    }

    out[0] = Null; /* No match! */
    return(1);
} /* findname */

/************************************************************************/
void motd()
/*
  Give the message of the day.
------------------------------------------------------------------------*/
{
  char path[MAXBUF];
  static char *command[] = { "help", "motd" };

  if (findname(path, docpath, "motd", ".doc", R_OK) == 0)
    dohelp(2, command);
  return;
}

/************************************************************************/
void bug(message)
char *message;
/*
  This prints an error message and then exits with status 1.
------------------------------------------------------------------------*/
{
  (void)fprintf(stderr, "### %s\n", message);
  (void)exit(1);
} /* bug */

/************************************************************************/
static int buildPath(envname, maxsize, string)
char *envname[];
int maxsize;
char *string;
/*
  Parses an input string into words separated by the colon character
  and stores pointers to each string in the array.
------------------------------------------------------------------------*/
{
    int j;
    char *s;

    j = 0;
    if (((int)strlen(string) > 0) && (maxsize > 0)) {
      envname[j++] = s = string;
      while ((s = strchr(s, ':')) != (char *)NULL) {
        *s++ = Null;
        if ((j + 1) >= maxsize) {
          (void)fprintf(stderr,
            "### Number of elements in input path overflows internal array.\n");
          break;
        }
        envname[j++] = s;
      }
    }
    return(j);
} /* buildPath */

/************************************************************************/
static void usage(prog)
char *prog;
/*
  Prints command line options and then exits with value 0.
------------------------------------------------------------------------*/
{
#define USE(a,b) (void)fprintf(stderr, "\t%-11s %s\n", a, b);

    (void)fprintf(stderr, "Usage: %s %s\n",
      prog, "[-h] [-g] [-b binpath] [-p docpath] [-d defdir] [-s lastexit]");
    (void)fprintf(stderr, "Options:\n");

    USE("-h/?", "This help.");
    USE("-g",   "Turn debugging on (verbose).");
    USE("-b binpath", "Colon separated path used to search for commands.");
    USE("-p docpath", "Colon separated path used to find documentation files.");
    USE("-d defdir",  "Directory to use for I/O of lastexit/.def files.");
    USE("-s lastexit", "Name of default lastexit file.");

    (void)exit(0);

#undef USE
} /* usage */

/************************************************************************/
void set_defaults(ac, av)
int ac;
char *av[];
{
/*
    This gets any command line parameters and sets internal defaults.

    -b path     take this path as the binary path [default is MIRBIN].
    -p path     take this path as the documentation path [.:MIRPDOC].
    -d dir      save files in this dir [MIRDEF].
    -s lastexit default name for lastexit file.
    -g          debugging on.
    -?/h        inline help.
------------------------------------------------------------------------*/
    int i;
    char *cp;
    char *bindef, *docdef;

    bindef = "MIRBIN";
    docdef = ".:MIRPDOC";
    defdir = "MIRDEF";

    for (i = 1; i < ac; i++) {           /* Avoid using getopt() here. */
      cp = av[i];
      if (*cp == '-') {
        switch (*++cp) {
          case 'g': case 'G':
            debug_level = 1;
            (void)printf("Debug turned on.\n");
            break;
          case 'b': case 'B':
            if (++i >= ac) bug("Missing argument: -b name; try -h");
            bindef = av[i];
            if (debug_level) (void)printf("bindef: %s\n", bindef);
            break;
          case 'p': case 'P':
            if (++i >= ac) bug("Missing argument: -p name; try -h");
            docdef = av[i];
            if (debug_level) (void)printf("docdef: %s\n", docdef);
            break;
          case 'd': case 'D':
            if (++i >= ac) bug("Missing argument: -d name; try -h");
            defdir = av[i];
            if (debug_level) (void)printf("defdir: %s\n", defdir);
            break;
          case 's': case 'S':
            if (++i >= ac) bug("Missing argument: -s name; try -h");
            lastexit = av[i];
            if (debug_level) (void)printf("lastexit: %s\n", lastexit);
            break;
          case 'h': case 'H':
          case '?':
            usage(av[0]);                   /* Will also call exit(0). */
          default:
            (void)fprintf(stderr, "%s: Illegal option [%s].\n", av[0], cp);
        }
      } else {
        (void)fprintf(stderr, "%s: Illegal option [%s].\n", av[0], cp);
      }
    }

    (void)strcpy(binstring, bindef);
    if (buildPath(binpath, MAXPATHS, binstring) < 1) {
      (void)fprintf(stderr, "### %s: Illegal binary path [%s].\n",
        av[0], binstring);
      usage(av[0]);
    }

    /* Insure that "." is in user's path. */
    if (strchr(docdef, '.') == (char *)NULL) {
      (void)strcpy(docstring, ".:");
      (void)strcat(docstring, docdef);
    } else {
      (void)strcpy(docstring, docdef);
    }
    if (buildPath(docpath, MAXPATHS, docstring) < 1) {
      (void)fprintf(stderr, "### %s: Illegal documentation path [%s].\n",
        av[0], docstring);
      usage(av[0]);
    }

    return;
} /* set_defaults */

/************************************************************************/
void doversion()
{
    char *s;
    int j;

    (void)printf("Miriad Version=%s\n", VERSION_ID);
#ifdef __DATE__
    (void)printf("Compiled on %s\n", __DATE__);
#endif /* __DATE__ */
    (void)printf("Compile directives used were:\n");

    (void)printf("%-15s", "PATHSEARCH:");
#if (PATHSEARCH == 1)
    (void)printf("on; $PATH is searched instead of $MIRBIN.\n");
#else
    (void)printf("off; $MIRBIN is searched instead of $PATH.\n");
#endif

    (void)printf("%-15s", "INTERRUPT:");
#if (INTERRUPT == 1)
    (void)printf("on; interrupts like ^\\, ^C, and ^Y are caught.\n");
#else
    (void)printf("off; interrupts like ^\\, ^C, and ^Y are NOT caught.\n");
#endif

    (void)printf("%-15s", "READLINE:");
#if (READLINE == 1)
    (void)printf("on; using GNU command line editor and file completion.\n");
#else
    (void)printf("off.\n");
#endif

    (void)printf("%-15s", "NEWENV:");
#if (NEWENV == 1)
    (void)printf("on; environment variables may be added.\n");
#else
    (void)printf("off; environment variables may NOT be added.\n");
#endif

    (void)printf("%-15s", "EXECL:");
#if (EXECL == 1)
    (void)printf("on; foreign commands will permit the use of aliases.\n");
#else
    (void)printf("off.\n");
#endif

    (void)printf("%-15s", "GETENV:");
#if (GETENV == 1)
    (void)printf("on; local version of getenv() used.\n");
#else
    (void)printf("off; system version of getenv() used.\n");
#endif

    (void)printf("%-15s", "DOER:");
#if (DOER == 1)
    (void)printf("on; local version of cle_exe in use.\n");
#else
    (void)printf("off; no local version of cle_exe available.\n");
#endif

    (void)printf("\nRun-time directives used are:\n");
    (void)printf("%-15s%s.\n", "Debug mode:", ((debug_level) ? "on" : "off"));

    j = 0;
    (void)printf("%-15s", "BINPATH:");
    while ((s = binpath[j++]) != (char *)NULL)
      (void)printf("%s ", s);
    (void)printf("\n");

    j = 0;
    (void)printf("%-15s", "DOCPATH:");
    while ((s = docpath[j++]) != (char *)NULL)
      (void)printf("%s ", s);
    (void)printf("\n");

    if (defdir != (char *)NULL)
        (void)printf("%-15s%s\n", "DEFDIR:", defdir);
    return;
} /* doversion */

/************************************************************************/
void newenv(var, value)
char *var, *value;
/*
   Enter a new environment variable. If 'value' is NULL, erase it.
   Some OS's have putenv(), the opposite to getenv(), but they 
   typically do not work with the third parameter to main().

   Input:  var         The name of the environment variable.
           value       The value of the environment variable.
------------------------------------------------------------------------*/
{

#if (NEWENV == 1)

    char *cp;
    char **ep, **newep, **epfrom, **epto;
    int elen, vlen, nev, i;

    vlen = strlen(var);
    for (nev = 0, ep = menviron; *ep != (char *)NULL; ep++) {
      nev++;                         /* Count the number of variables. */
      elen = strlen(*ep);           /* String length of this variable. */
      if ((cp = strchr(*ep, '=')) != (char *)NULL) {  /* Look for '='. */
        if (((int)(cp - *ep) == vlen) && (strncmp(*ep, var, vlen) == 0)) {
          if ((vlen + (int)strlen(value) + 2) > elen) {  /* Need to resize? */
            cp = (char *)malloc(vlen + strlen(value) + 2);
            if (cp == (char *)NULL) {
              (void)fprintf(stderr,
                "### %s: Trouble allocating space to expand variable [%s].\n",
                "newenv", var);
              return;
            }
            *ep = cp;
          }
          (void)sprintf(*ep, "%s=%s", var, value);
          return;                         /* Now return to the caller. */
        }
      }
    }

    /* If this point is reached, then "var" is a new environment variable. */

    if (debug_level)
      (void)printf("### (%d) Adding %s=%s to environment.\n", nev, var, value);

    newep = (char **)malloc((nev + 2) * sizeof(char *));
    if (newep == (char **)NULL) {
      (void)fprintf(stderr,
        "### %s: Trouble allocating memory to add to the environment %s=%s.\n",
        "newenv", var, value);
      return;
    }

    for (i = 0, epfrom = menviron, epto = newep; i < nev; i++)
      *epto++ = *epfrom++;   /* Copy the old stuff into the new array. */

    cp = (char *)malloc(vlen + strlen(value) + 2);
    if (cp == (char *)NULL) {
      (void)fprintf(stderr,
        "### %s: Trouble allocating memory to add the env. variable: %s=%s.\n",
        "newenv", var, value);
      (void)free(newep);
      return;
    }

    (void)sprintf(cp, "%s=%s", var, value);
    *epto++ = cp;                   /* Put the new thing in the array. */
    *epto = (char *)NULL;                      /* Terminate the array. */
    menviron = newep;                    /* Reset the new environment. */

#else

    (void)fprintf(stderr, "### newenv disabled; can not set %s=%s.\n",
      var, value);

#endif /* NEWENV */

    return;
} /* newenv */

#if (GETENV == 1)
/************************************************************************/
char *localgetenv(var)
char *var;
/*
   This is a local version in case *getenv() is not supplied by your OS.
------------------------------------------------------------------------*/
{
    char *cp;
    char **ep;
    int vlen;

    vlen = strlen(var);
    for (ep = menviron; *ep != (char *)NULL; ep++) {
      if ((cp = strchr(*ep, '=')) != (char *)NULL) {  /* Look for '='. */
        if (((int)(cp - *ep) == vlen) && (strncmp(*ep, var, vlen) == 0)) {
          if (debug_level) (void)printf("Found %s\n", *ep);
          cp++;
          return(cp);
        }
      }
    }
    return((char *)NULL);
} /* localgetenv */
#endif /* GETENV */

#if (INTERRUPT == 1)
/************************************************************************/
void review()
{
    (void)fprintf(stderr,
      "Miriad shell cannot be interrupted, type 'help miriad' for help.\n");
    return;
} /* review */
#endif /* INTERRUPT */

#if (READLINE == 1)
/************************************************************************/
static void ini_readline()
/*
   The following pages are dedicated to some GNU READLINE experiments.
   They are typically not used in your active version of miriad.c
   unless, as can be seen with the 'version' command, you compiled
   this code with the READLINE macro defined.
------------------------------------------------------------------------*/
{
    char name[MAXBUF];

    (void)printf("*** Experimental GNU READLINE installed. ***\n");
    (void)printf("A command history file is maintained in $%s/%s.\n",
      defdir, ".miriadhis");

    filename(name, defdir, "", ".miriadhis");
    read_history(name);

    return;
} /* ini_readline */

/************************************************************************/
static void end_readline()
{
    char name[MAXBUF];

    filename(name, defdir, "", ".miriadhis");
    write_history(name);
    return;
} /* end_readline */

/************************************************************************/
static void stripwhite(string)
char *string; 
/*
     Strip white space from the beginning and the end of "string".
     The first non-white character is moved to the beginning of "string"
     and all white space shifted to the end.  Then, all trailing white
     space is replaced with Nulls.
------------------------------------------------------------------------*/
{
    register int i, j;

    for (i = 0; isspace(string[i]); i++)
      /* NULL */ ;

    if (i > 0) /* Do not use strcpy() here! */
      for (j = 0; string[j] = string[i]; j++)
        i++;

    for (i = strlen(string) - 1; ((i > 0) && (isspace(string[i]))); i--)
      string[i] = Null;

    return;
} /* stripwhite */
#endif /* READLINE */
