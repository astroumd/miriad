/*= imcalc - MIRIAD Image Calculator and Programming Language	 */
/*& rjs                                                          */
/*: Utility, Map Combination, Map Analysis			 */
/*+	TEST PROGRAM - retention of this program within MIRIAD
	depends on its utility to MIRIAD users.

	IMCALC is an image calculator and analysis tool. It reads
	commands and assignment statements from the user, and
	executes them. Commands generally consist of one or more
	arguments, each argument separated by a space. Spaces are
	not permitted within an argument (except within a quoted
	string). The arguments to a command are generally either
	variable names, or expressions, or several expressions
	separated by commas. Some arguments can be omitted. In
	this case a default value will be used.

	There are no on-line instructions for using this program.
	See the separate paper documentation, or make your own
	documentation by copying MIRIAD's LaTex file to your own
	work area and printing it out.  At Illinois, this can be
	done using the following commands:

	     cp -p $MIR/src/spec/imcalc/imcalc.latex myfile.latex
	     latex myfile.latex
	     dvitps myfile.dvi > myfile.ps
	     lpr myfile.ps

	Once you have done this, type ``ls -lt myfile.*'' to see
	all the files that you've just created.  Remove any of
	them that you don't want to keep.

	LIMITATIONS:

	The parser cannot handle functions with zero arguments.

	The convolve function does not work for complex data.

	The fft function does not work for real data.
/*--*/
/* BUGS: The parser cannot handle functions with zero arguments.
 	 better plotting functionality.
The following do not work for cmplex data: convolve function,
The following do not work for real data:   fft function.
*/
/************************************************************************/
/*									*/
#include <ctype.h>
#include <math.h>
#include <stdio.h>
#include "header.h"
#define MAXSTACK 256

#define OP_OPER		0x0001
#define OP_NOPER	0x0002
#define OP_ROUT		0x0004
#define OP_FUNC		0x0008

#define COM_CONTROL 0x0001
typedef struct { char *name;
		 int (*com_routine)(),flags;
		 char *args,*text;
		} COMMAND;

#define CTRLTYPE_DO	1
#define CTRLTYPE_IF	2
#define CTRLTYPE_SOURCE	3
#define CTRLTYPE_WHILE	4
typedef struct ctrl {	int type,taken;
		FILE *previous;
		long seek;
		char *varname;
		FLOAT curval,limit,increment;
		struct ctrl *fwd; } CTRL;

typedef struct operator { char *name;
		 int flags,narg,prec;
		 VARIABLE *(*x_routine)();
		 double (*r_routine)();
		 int (*c_routine)();
		 struct operator *fwd;
		} OPERATOR;

typedef struct token {	 OPERATOR *op;
			 VARIABLE *v;
			 int ncomma;
			 struct token *fwd; } TOKEN;

/* void contour(); */
void imfft_r(),imfft_c(),convl(),fitclose(),fitread(),fitwrite();
char *fitopen();

private void tokdelete(),hashinit(),varput(),summary(),save_image();
private char *skip_arg(),*skip_real(),*skip_logical(),*skip_cmplx(),*getopts();
private char *real_value(),*string_value(),*coord_value(),*cmplx_value();
private TOKEN *parse(),*tokget(),*pushop();
private VARIABLE *varget();
VARIABLE *evaluate(),*varmake(),*varcopy();
void vardelete();
char *Malloc();
private VARIABLE *multi_evaluate();
private VARIABLE *coord_op1(),*real_op1(),*cmplx_op1(),*real_op2();
private int tokpush();

VARIABLE *add_x(),*sub_x(),*mult_x(),*div_x();
VARIABLE *shift_x(),*coord_x(),*concat_x(),*convolve_x();
VARIABLE *extract_x(),*fft_x(),*dims_x();
VARIABLE *ismax_x(),*ismin_x(),*load_x(),*read_x(),*sum_x();
VARIABLE *push_x(),*loadr_x(),*loadc_x(),*cmplx_x();

double gt_r(),ge_r(),lt_r(),le_r(),eq_r(),ne_r();
double not_r(),and_r(),or_r(),eqv_r(),neqv_r();
double uminus_r(),abs_r(),aint_r(),anint_r();
double max_r(),min_r(),sign_r(),dim_r(),exp_r();

int abs_c(),aimag_c(),arg_c(),real_c();
int uminus_c(),conjg_c(),log_c(),exp_c();

/* The following table gives the list of possible commands. This table
   MUST be in alphabetic order. */

private int dump_com(); 
/* private int contour_com(); */
private int store_com(),insert_com();
private int set_com(),quit_com(),summary_com(),standard_com(),write_com();
private int histogram_com(),do_com(),while_com(),if_com(),end_com();
private int spawn_com(),source_com(),elif_com(),else_com(),null_com();
private int save_com(),help_com();

COMMAND commands[] = {
/*	{"contour",contour_com,0,"image-exp [contour-levels,....]",
				 "Contour plotting"}, */
	{"do",do_com,COM_CONTROL,"varname exp1,exp2[,exp3]",
				 "Do loop start"},
	{"dump",dump_com,0,	 "image-exp",
				 "Dump the contents of an image"},
	{"else",else_com,COM_CONTROL,"","If-Elif-Else-End loop control"},
	{"elif",elif_com,COM_CONTROL,"exp","If-Elif-Else-End loop control"},
	{"end",end_com,COM_CONTROL,"","Terminate If/Do/While structures"},
	{"help",help_com,0,"","Help command"},
	{"histogram",histogram_com,0,"image-exp [lo-val,hi-val]",
				     "Histogram"},
	{"if",if_com,COM_CONTROL,"exp","If-Elif-Else-End loop control"},
	{"insert",insert_com,0,"image value coord","Insert pixel value"},
	{"null",null_com,0,"",""},
	{"quit",quit_com,COM_CONTROL,"","Quit or exit imcalc"},
	{"save",save_com,0,"filename","Save values in a script file"},
	{"store",store_com,0,"filename image-exp","Store image in a file"},
	{"set",set_com,0,"varname exp","Set a variable equal to an expression"},
	{"source",source_com,0,"filename","Execute commands from a script file"},
	{"spawn",spawn_com,0,"command","Execute a shell command"},
	{"standard",standard_com,0,"coord","Generate images i,j and zero"},
	{"summary",summary_com,0,"exp","Give information about the expression"},
	{"while",while_com,0,"exp","While-End loop control"},
	{"write",write_com,0,"exp[,exp[,exp...]]","Write out values"}};

#define NCOMMANDS (sizeof(commands)/sizeof(COMMAND))

OPERATOR operators[] ={
	{"$push",OP_NOPER,0,11,push_x,NULL,NULL,NULL},
	{"$shift",0,2,9,shift_x,NULL,NULL,NULL},
	{"$extract",0,2,9,extract_x,NULL,NULL,NULL},
	{"$coord",0,2,10,coord_x,NULL,NULL,NULL},
	{"**",OP_OPER,2,9,NULL,pow,NULL,NULL},
	{"$uminus",0,1,7,NULL,uminus_r,uminus_c,NULL},
	{"+",OP_OPER,2,6,add_x,NULL,NULL,NULL},
	{"-",OP_OPER,2,6,sub_x,NULL,NULL,NULL},
	{"*",OP_OPER,2,8,mult_x,NULL,NULL,NULL},
	{"/",OP_OPER,2,8,div_x,NULL,NULL,NULL},
	{"$uminus",0,1,7,NULL,uminus_r,uminus_c,NULL},
	{"//",OP_OPER,2,6,concat_x,NULL,NULL,NULL},
	{".gt.",OP_OPER,2,5,NULL,gt_r,NULL,NULL},
	{".ge.",OP_OPER,2,5,NULL,ge_r,NULL,NULL},
	{".lt.",OP_OPER,2,5,NULL,lt_r,NULL,NULL},
	{".le.",OP_OPER,2,5,NULL,le_r,NULL,NULL},
	{".eq.",OP_OPER,2,5,NULL,eq_r,NULL,NULL},
	{".ne.",OP_OPER,2,5,NULL,ne_r,NULL,NULL},
	{".not.",0,1,4,NULL,not_r,NULL,NULL},
	{".and.",OP_OPER,2,3,NULL,and_r,NULL,NULL},
	{".or.",OP_OPER,2,2,NULL,or_r,NULL,NULL},
	{".eqv.",OP_OPER,2,1,NULL,eqv_r,NULL,NULL},
	{".neqv.",OP_OPER,2,1,NULL,neqv_r,NULL,NULL},
	{")",OP_OPER|OP_NOPER,0,0,NULL,NULL,NULL,NULL},
	{"(",0,0,-1,NULL,NULL,NULL,NULL},
	{"[",0,0,-1,NULL,NULL,NULL,NULL},
	{"]",OP_OPER|OP_NOPER,0,0,NULL,NULL,NULL,NULL},
	{",",OP_OPER,0,0,NULL,NULL,NULL,NULL},
	{"abs",OP_FUNC|OP_ROUT,1,10,NULL,abs_r,abs_c,NULL},
	{"acos",OP_FUNC,1,10,NULL,acos,NULL,NULL},
	{"aimag",OP_FUNC|OP_ROUT,1,10,NULL,NULL,aimag_c,NULL},
	{"aint",OP_FUNC,1,10,NULL,aint_r,NULL,NULL},
	{"anint",OP_FUNC,1,10,NULL,anint_r,NULL,NULL},
	{"arg",OP_FUNC|OP_ROUT,1,10,NULL,NULL,arg_c,NULL},
	{"asin",OP_FUNC,1,10,NULL,asin,NULL,NULL},
	{"atan",OP_FUNC,1,10,NULL,atan,NULL,NULL},
	{"atan2",OP_FUNC,2,10,NULL,atan2,NULL,NULL},
	{"ceil",OP_FUNC,1,10,NULL,ceil,NULL,NULL},
	{"cmplx",OP_FUNC,2,10,cmplx_x,NULL,NULL,NULL},
	{"conjg",OP_FUNC,1,10,NULL,NULL,conjg_c,NULL},
	{"convolve",OP_FUNC,2,10,convolve_x,NULL,NULL,NULL},
	{"cos",OP_FUNC,1,10,NULL,cos,NULL,NULL},
	{"cosh",OP_FUNC,1,10,NULL,cosh,NULL,NULL},
	{"dim",OP_FUNC,2,10,NULL,dim_r,NULL,NULL},
	{"dims",OP_FUNC,1,10,dims_x,NULL,NULL,NULL},
/*
	{"erf",OP_FUNC,1,10,NULL,erf,NULL,NULL},
	{"erfc",OP_FUNC,1,10,NULL,erfc,NULL,NULL},
*/
	{"exp",OP_FUNC,1,10,NULL,exp_r,exp_c,NULL},
	{"extract",OP_FUNC,2,10,extract_x,NULL,NULL,NULL},
	{"fft",OP_FUNC,2,10,fft_x,NULL,NULL,NULL},
	{"floor",OP_FUNC,1,10,NULL,floor,NULL,NULL},
#ifndef linux
	{"gamma",OP_FUNC,1,10,NULL,gamma,NULL,NULL},
#endif
	{"ismax",OP_FUNC,1,10,ismax_x,NULL,NULL,NULL},
	{"ismin",OP_FUNC,1,10,ismin_x,NULL,NULL,NULL},
	{"j0",OP_FUNC,1,10,NULL,j0,NULL,NULL},
	{"j1",OP_FUNC,1,10,NULL,j1,NULL,NULL},
	{"load",OP_FUNC,1,10,load_x,NULL,NULL,NULL},
	{"loadc",OP_FUNC,2,10,loadc_x,NULL,NULL,NULL},
	{"loadr",OP_FUNC,2,10,loadr_x,NULL,NULL,NULL},
	{"log",OP_FUNC,1,10,NULL,log,log_c,NULL},
	{"log10",OP_FUNC,1,10,NULL,log10,NULL,NULL},
	{"max",OP_FUNC,2,10,NULL,max_r,NULL,NULL},
	{"min",OP_FUNC,2,10,NULL,min_r,NULL,NULL},
	{"mod",OP_FUNC,2,10,NULL,fmod,NULL,NULL},
	{"read",OP_FUNC,1,10,read_x,NULL,NULL,NULL},
	{"real",OP_FUNC|OP_ROUT,1,10,NULL,NULL,real_c,NULL},
	{"shift",OP_FUNC,2,10,shift_x,NULL,NULL,NULL},
	{"sign",OP_FUNC,2,10,NULL,sign_r,NULL,NULL},
	{"sin",OP_FUNC,1,10,NULL,sin,NULL,NULL},
	{"sinh",OP_FUNC,1,10,NULL,sinh,NULL,NULL},
	{"sqrt",OP_FUNC,1,10,NULL,sqrt,NULL,NULL},
	{"sum",OP_FUNC,1,10,sum_x,NULL,NULL,NULL},
	{"tan",OP_FUNC,1,10,NULL,tan,NULL,NULL},
	{"tanh",OP_FUNC,1,10,NULL,tanh,NULL,NULL},
	{"y0",OP_FUNC,1,10,NULL,y0,NULL,NULL},
	{"y1",OP_FUNC,1,10,NULL,y1,NULL,NULL}};

#define NOPERS (sizeof(operators)/sizeof(OPERATOR))

#define NHASH 57
OPERATOR *operhash[NHASH];
VARIABLE *varhash[NHASH];


CTRL *ctrlhead;
long seekpos;
int doprompt,skip_level;
FILE *stream;
/**********************************************************************/
main(argc,argv)
int argc;
char *argv[];
/*
  The main routine. First this initialises the hash tables. Then it goes
  into a loop, reading the input, breaking it into tokens, and passing
  it to the appropriate routine to execute that command.

  Command line arguments are ignored.
----------------------------------------------------------------------*/
{
  TOKEN *toklist,*token;
  VARIABLE *v;
  CTRL *p,*next;
  int narg,errflag,i,i0,length;
  char *arg[MAXARG],line[MAXLINE],*s;

/* Initialise the hash table of legitimate operators. */

  hashinit();

/* Other initialisations, mainly to do with handling control patterns. */

  if(argc > 2)fprintf(stderr,"### Only one command line argument allowed\n");
  if(argc == 2){
    stream = fopen(argv[1],"r");
    if(stream == NULL){
      fprintf(stderr,"### Failed to open input file %s. Aborting ...\n");
      exit(1);
    }
  } else {
    stream = stdin;
  }
  skip_level = 0;
  ctrlhead = NULL;
  doprompt = isatty(fileno(stream));

/* Loop forever. */

  while(TRUE){
    if(doprompt)printf("* ");
    seekpos = ftell(stream);
    if(fgets(line,MAXLINE,stream) == NULL) strcpy(line,"quit\n");
    length = strlen(line);
    if(line[length-1] == '\n') line[length-1] = 0;

/* Get the command token. */

    errflag = FALSE;
    s = line;
    SKIP_WHITE(s);
    narg = 0;
    if(*s == 0 || *s == '#'){
      arg[0] = "null";
      narg = 1;
    } else if( *s == '!'){
      arg[0] = "spawn";
      arg[1] = s + 1;
      narg = 2;
    } else if( ! isalpha(*s)){
      fprintf(stderr,"### Badly formed command ignored\n");
      errflag = TRUE;
    } else {
      arg[narg++] = s;
      while(isalnum(*s)) s++;
      if(*s == ' ' || *s == '\t'){
	*s++ = 0;
	SKIP_WHITE(s);
      }
      if(*s == '='){
	*s++ = 0;
	arg[narg++] = arg[0];
	arg[0] = "set";
	SKIP_WHITE(s);
      }

/* Break the string into arguments. */

      while( *s != 0){
        arg[narg++] = s;
        s = skip_arg(s);
        if(*s != 0){
	  *s++ = 0;
	  SKIP_WHITE(s);
        }
      }
    }
/* Determine which command to process. */

    if(!errflag){
      length = strlen(arg[0]);
      i0 = -1;
      for(i=0; i < NCOMMANDS; i++)
	if(!strncmp(commands[i].name,arg[0],length))
	  if(strlen(commands[i].name) >= length)
	    i0 = (i0 == -1 ? i : -2);
      errflag = TRUE;
      if(i0 >= 0){
        if( skip_level == 0 || commands[i0].flags & COM_CONTROL)
	  errflag = (*(commands[i0].com_routine))(narg,arg);
	else
	  errflag = FALSE;
      } else if(i0 == -1)fprintf(stderr,"### Unrecognised command \'%s\'\n",arg[0]);
      else fprintf(stderr,"### Ambiguous command \'%s\'\n",arg[0]);
    }   

/* Do some error processing. */

    if(errflag){
      for(p=ctrlhead; p!= NULL; p = next){
	next = p->fwd;
	if(p->type == CTRLTYPE_SOURCE){
	  if(stream != stdin)fclose(stream);
	  stream = p->previous;
	}
	if(p->varname != NULL)free(p->varname);
	free((char *)p);
      }
      ctrlhead = NULL;
      doprompt = isatty(fileno(stream));
      if(!doprompt)exit(1);
      skip_level = 0;
    }
  }
}
/**********************************************************************/
private int help_com(narg,arg)
int narg;
char *arg[];
/*
  This gives help on imcalc commands.
----------------------------------------------------------------------*/
{
  int i;
  char *text,*args,*name,line[MAXLINE];
  printf("Available commands are:\n\n");
  for(i=0; i < NCOMMANDS; i++){
    name = commands[i].name;
    text = commands[i].text;
    args = commands[i].args;
    if(*text != 0){
      strcpy(line,name);
      strcat(line," ");
      strcat(line,args);
      printf("%-36s %s\n",line,text);
    }
  }
  return(FALSE);
}
/**********************************************************************/
private int save_com(narg,arg)
int narg;
char *arg[];
/*
   This saves all the defined variables in a text file.
----------------------------------------------------------------------*/
{
  FILE *f;
  VARIABLE *v;
  int i;
  char name[MAXLINE],*s;

  if(narg != 2)
    ERR_RETURN("### There must be only one argument to \'save\'\n",TRUE);
  if((s=string_value(arg[1],name)) == NULL)return(TRUE);
  if(*s != 0)
    ERR_RETURN("### There must be only one argument to \'save\'\n",TRUE);
  f = fopen(name,"w");
  if(f == NULL){
    fprintf(stderr,"### Error opening %s\n",name);
    return(TRUE);
  }

/* A simple header. */

  fprintf(f,"\n# This is a script saving imcalc variables\n\n");

/* Now go through all the variables. */

  for(i=0; i < NHASH; i++){
    for(v=varhash[i]; v != NULL; v=v->fwd)switch(v->type){
      case TYPE_STRING:
	fprintf(f,"%s = \'%s\'\n",v->name,v->value);
      case TYPE_COORD:
	fprintf(f,"%s = [%g,%g]\n",v->name,v->val[0],v->val[1]);
      case TYPE_REAL:
	if(v->xdim*v->ydim != 0) save_image(f,v);
	else fprintf(f,"%s = %g\n",v->name,v->val[0]);
	break;
      case TYPE_CMPLX:
	if(v->xdim*v->ydim != 0) save_image(f,v);
	else fprintf(f,"%s = (%g,%g)\n",v->name,v->val[0],v->val[1]);
	break;
    }
  }

  fclose(f);
  return(FALSE);
}
/**********************************************************************/
private void save_image(f,v)
FILE *f;
VARIABLE *v;
/*
  This saves an image.
----------------------------------------------------------------------*/
{
  int nsize[3],j,k,naxis;
  char name[MAXLINE],*fit;
  FLOAT *data;

  if(v->type == TYPE_REAL){
    nsize[0] = v->xdim; nsize[1] = v->ydim; nsize[2] = 1;
    naxis = 2;
  } else {
    nsize[0] = 2; nsize[1] = v->xdim; nsize[2] = v->ydim;
    naxis = 3;
  }
  sprintf(name,"%s.miriad",v->name);
  if(!access(name,0)){
    fprintf(stderr,"### Warning: File %s already exists, not overwritten\n",name);
    fprintf(f,"# Assuming file %s corresponds to %s\n",name,v->name);
    fprintf(f,"%s = load(\'%s\')\n",v->name,name);
  } else {
    fit = fitopen(name,"new",naxis,nsize);
    if(fit == NULL){
      fprintf(f,"### Unable to store %s in file %s\n",v->name,name);
    } else {
      fprintf(f,"%s = load(\'%s\')\n",v->name,name);
      data = (FLOAT *)(v->value);
      for(k = 0; k < nsize[2]; k++){
        fitsetpl(fit,1,&k);
        for(j = 0; j < nsize[1]; j++){
	  fitwrite(fit,j,data);
	  data += nsize[0];
        }
      }
      fitclose(fit);
    }
  }
}
/**********************************************************************/
private int store_com(narg,arg)
int narg;
char *arg[];
/*
  This saves an image as a FITS file.
----------------------------------------------------------------------*/
{
  VARIABLE *b;
  char *s,*f,name[MAXLINE];
  int j,k,naxis,nsize[3];
  FLOAT *dat;

  if(narg != 3)
    ERR_RETURN("### The \'save\' command must have two arguments\n",TRUE);
  if((s = string_value(arg[1],name)) == NULL)return(TRUE);
  if(*s != 0)ERR_RETURN("### First argument to \'store\' must be a string\n",TRUE);
  b = evaluate(arg[2]);
  if(b == NULL) return(TRUE);
  if((b->type != TYPE_REAL && b->type != TYPE_CMPLX) || b->xdim * b->ydim <= 0){
    vardelete(b);
    ERR_RETURN("### The second argument to the \'save\' command must be a real image\n",TRUE);
  }
  if(b->type == TYPE_CMPLX){
    nsize[0] = 2; nsize[1] = b->xdim; nsize[2] = b->ydim;
    naxis = 3;
  } else {
    nsize[0] = b->xdim; nsize[1] = b->ydim; nsize[2] = 1;
    naxis = 2;
  }
  f = fitopen(name,"new",naxis,nsize);
  if(f == NULL){
    vardelete(b); return(TRUE);
  }
  dat = (FLOAT *)(b->value);
  for(k = 0; k < nsize[2]; k++){
    fitsetpl(f,1,&k);
    for(j = 0; j < nsize[1]; j++){
      fitwrite(f,j,dat);
      dat += nsize[0];
    }
  }
  fitclose(f);
  vardelete(b);
  return(FALSE);
}
/**********************************************************************/
private int set_com(narg,arg)
int narg;
char *arg[];
/*
  This assigns the value to a variable.
----------------------------------------------------------------------*/
{
  VARIABLE *v;
  char *s;

/* Check that things look good. */

  if(narg != 3) ERR_RETURN("### Bad assignment statement\n",TRUE);
  s = arg[1];
  if(! isalpha(*s)) ERR_RETURN("### Bad variable name\n",TRUE);
  for(s = arg[1]; *s != NULL; s++) if(!isalnum(*s)) ERR_RETURN("### Bad variable name\n",TRUE);

/* Parse the expression, and echo back to the user whats what. */

  v = evaluate(arg[2]);
  if(v == NULL) return(TRUE);
  if(v->temporary){
    v->name = Malloc(sizeof(char)*(strlen(arg[1])+1));
    strcpy(v->name,arg[1]);
  } else v = varcopy(arg[1],v);
  v->temporary = FALSE;
  varput(v);
  return(FALSE);
}
/**********************************************************************/
private int spawn_com(narg,arg)
int narg;
char *arg[];
/*
  This spawns a host command, and returns status.
----------------------------------------------------------------------*/
{
  system(arg[1]);
  return(FALSE);
}
/**********************************************************************/
private int null_com(narg,arg)
int narg;
char *arg[];
/*
  This does nothing. It is a command that gets executed as the result
  of a blank or comment line in the input.
----------------------------------------------------------------------*/
{
  return(FALSE);
}
/**********************************************************************/
private int do_com(narg,arg)
int narg;
char *arg[];
/*
  This starts a do-loop.
----------------------------------------------------------------------*/
{
  CTRL *p;
  VARIABLE *v;
  char *s;
  int n;

/* Check that the statement and the expression is well formed. */

  if(narg != 3)
    ERR_RETURN("### Bad \'while\' statement\n",TRUE);
  s = arg[1];
  if(! isalpha(*s)) ERR_RETURN("### Bad variable name in do-loop\n",TRUE);
  for(s = arg[1]; *s != NULL; s++)
    if(!isalnum(*s)) ERR_RETURN("### Bad variable name in do-loop\n",TRUE);

/* Allocate the control structure to remember that we are in an if-
block.  Determine if we are to execute the if-block or to skip it. */

  p = (CTRL *)Malloc(sizeof(CTRL));
  p->fwd = ctrlhead;
  ctrlhead = p;
  p->type = CTRLTYPE_DO;
  p->varname = NULL;

/* Check if we are to do this if-block or not. */

  if(skip_level != 0) skip_level++;
  else {
    s = arg[2];
    if((s = real_value(s,&(p->curval))) == NULL) return(TRUE);
    if((s = real_value(s,&(p->limit))) == NULL) return(TRUE);
    if(*s == 0) p->increment = 1;
    else if(real_value(s,&(p->increment)) == NULL) return(TRUE);
    if(p->increment == 0)
      ERR_RETURN("### Zero increment for do-loop\n",TRUE);
    n = (p->limit - p->curval)/p->increment + 1;
    if(n <= 0) skip_level++;
    else {
      p->seek = ftell(stream);
      v = varmake(TYPE_REAL,0,0);
      v->temporary = FALSE;
      v->name = Malloc(strlen(arg[1])+1);
      p->varname = Malloc(strlen(arg[1])+1);
      strcpy(v->name,arg[1]);
      strcpy(p->varname,arg[1]);
      v->val[0] = p->curval;
      varput(v);
    }
  }

  return(FALSE);
}
/**********************************************************************/
private int while_com(narg,arg)
int narg;
char *arg[];
/*
  This starts execution of a "while" loop.
----------------------------------------------------------------------*/
{
  CTRL *p;
  FLOAT value;
  char *s;

/* Check that the statement and the expression is well formed. */

  if(narg != 2)
    ERR_RETURN("### Bad \'while\' statement\n",TRUE);

/* Allocate the control structure to remember that we are in an if-
block.  Determine if we are to execute the if-block or to skip it. */

  p = (CTRL *)Malloc(sizeof(CTRL));
  p->fwd = ctrlhead;
  ctrlhead = p;
  p->type = CTRLTYPE_WHILE;
  p->varname = NULL;
  p->seek = seekpos;

/* Check if we are to do this if-block or not. */

  if(skip_level != 0) skip_level++;
  else {
    if((s = real_value(arg[1],&value)) == NULL)return(TRUE);
    if(*s != 0)
      ERR_RETURN("### While expression is not a real expression\n",TRUE);
    if(value == 0) skip_level++;
  }

  return(FALSE);
}
/**********************************************************************/
private int if_com(narg,arg)
int narg;
char *arg[];
/*
  This starts execution of a "while" loop.
----------------------------------------------------------------------*/
{
  CTRL *p;
  FLOAT value;
  char *s;

/* Check that the statement and the expression is well formed. */

  if(narg != 2)
    ERR_RETURN("### Bad \'if\' statement\n",TRUE);

/* Allocate the control structure to remember that we are in an if-
block.  Determine if we are to execute the if-block or to skip it. */

  p = (CTRL *)Malloc(sizeof(CTRL));
  p->fwd = ctrlhead;
  ctrlhead = p;
  p->type = CTRLTYPE_IF;
  p->varname = NULL;
  p->taken = FALSE;

/* Check if we are to do this if-block or not. */

  if(skip_level != 0) skip_level++;
  else {
    if((s = real_value(arg[1],&value)) == NULL) return(TRUE);
    if(*s != 0)
      ERR_RETURN("### If expression is not a real expression\n",TRUE);
    if(value == 0) skip_level++;
  }

  return(FALSE);
}
/**********************************************************************/
private int elif_com(narg,arg)
int narg;
char *arg[];
/*
  This starts execution of a "while" loop.
----------------------------------------------------------------------*/
{
  CTRL *p;
  char *s;
  FLOAT value;

/* Check that the statement and the expression is well formed. */

  if(narg != 2)
    ERR_RETURN("### Bad \'elif\' statement\n",TRUE);
  p = ctrlhead;
  if(p == NULL)
    ERR_RETURN("### Elif without corresponding if statement\n",TRUE);
  if(p->type != CTRLTYPE_IF)
    ERR_RETURN("### Elif without corresponding if statement\n",TRUE);
  if(skip_level == 0){
    p->taken = TRUE;
    skip_level++;
  } else if(skip_level == 1 && !p->taken){
    if((s = real_value(arg[1],&value)) == NULL) return(TRUE);
    if(*s != 0)
      ERR_RETURN("### Elif expression is not a real expression\n",TRUE);
    if(value != 0) skip_level = 0;
  }

  return(FALSE);
}
/**********************************************************************/
private int else_com(narg,arg)
int narg;
char *arg[];
/*
  This starts execution of a "while" loop.
----------------------------------------------------------------------*/
{
  CTRL *p;

/* Check that the statement and the expression is well formed. */

  if(narg != 1)
    ERR_RETURN("### Bad \'else\' statement\n",TRUE);
  p = ctrlhead;
  if(p == NULL)
    ERR_RETURN("### Else without corresponding if statement\n",TRUE);
  if(p->type != CTRLTYPE_IF)
    ERR_RETURN("### Else without corresponding if statement\n",TRUE);
  if(skip_level == 0){
    p->taken = TRUE;
    skip_level++;
  } else if(skip_level == 1 && !p->taken){
    skip_level = 0;
  }

  return(FALSE);
}
/**********************************************************************/
private int end_com(narg,arg)
int narg;
char *arg[];
/*
  This starts execution of a "while" loop.
----------------------------------------------------------------------*/
{
  CTRL *p;
  VARIABLE *v;

/* Check that everything looks OK. */

  p = ctrlhead;
  if(p == NULL)ERR_RETURN("### Unexpected \'end\' command\n",TRUE);
  if(p->type == CTRLTYPE_SOURCE)
    ERR_RETURN("### Unexpected \'end\' command\n",TRUE);

/* If we are processing this (something)-end structure (i.e. we are not
   skipping it), then if its a while loop, rewind to the start of the
   loop, otherwise if its a do-loop, check for end of loop, then rewind
   to the start of the loop. */

  if(skip_level == 0){
    if(p->type == CTRLTYPE_WHILE){
      if(fseek(stream,p->seek,0) != 0)
        ERR_RETURN("### Failed to seek to the begining of a while-loop\n",TRUE);
    } else if(p->type == CTRLTYPE_DO){
      p->curval += p->increment;
      if(p->curval > p->limit)skip_level++;
      else{
        v = varget(p->varname);
	if(v == NULL) ERR_RETURN("### Do-loop variable does not exist\n",TRUE);
	if(v->type != TYPE_REAL || v->xdim*v->ydim != 0)
	  ERR_RETURN("### Do-loop variable is not real valued\n",TRUE);
	v->val[0] = p->curval;
	if(fseek(stream,p->seek,0) != 0)
	  ERR_RETURN("### Failed to seek to the begining of a do-loop\n",TRUE);
      }
    }
  }
  if(skip_level > 0 || p->type != CTRLTYPE_DO){
    ctrlhead = p->fwd;
    if(p->varname != NULL) free(p->varname);
    free((char *)p);
    if(skip_level > 0)skip_level--;
  }
  return(FALSE);
}
/**********************************************************************/
private int source_com(narg,arg)
int narg;
char *arg[];
/*
  This starts execution of a "while" loop.
----------------------------------------------------------------------*/
{
  char *s,name[MAXLINE];
  CTRL *p;
  FILE *file;

  if(narg != 2)
    ERR_RETURN("### The \'source\' command takes two arguments\n",TRUE);
  if((s = string_value(arg[1],name)) == NULL)return(TRUE);
  if(*s != 0)
    ERR_RETURN("### The arg of the \'source\' command is a filename only\n",TRUE);
  file = fopen(name,"r");
  if(file == NULL){
    fprintf(stderr,"### Error opening file %s\n",name);
    return(TRUE);
  }

  p = (CTRL *)Malloc(sizeof(CTRL));
  p->fwd = ctrlhead;
  ctrlhead = p;
  p->type = CTRLTYPE_SOURCE;
  p->varname = NULL;

  p->previous = stream;
  stream = file;
  doprompt = isatty(fileno(stream));
  return(FALSE);
}
/**********************************************************************/
private int quit_com(narg,arg)
int narg;
char *arg[];
/*
  This simply exits.
----------------------------------------------------------------------*/
{
  CTRL *p;

  p = ctrlhead;
  if(p == NULL) exit(0);
  if(p->type != CTRLTYPE_SOURCE)
    ERR_RETURN("### Unclosed do-loop, while-loop or if-block\n",TRUE);
  if(stream != stdin) fclose(stream);
  stream = p->previous;
  doprompt = isatty(fileno(stream));
  ctrlhead = p->fwd;
  if(p->varname != NULL) free(p->varname);
  free((char *)p);
  return(FALSE);
}
/**********************************************************************/
private int standard_com(narg,arg)
int narg;
char *arg[];
/*
  This generates three "standard" images, namely "zero", "i" and "j".
  Image "zero" is just that -- an array of zeros. Image "i" varies
  linearly in the x direction and image "j" varies linearly in the
  y direction.

  Command parameters:
    arg[1]	A integer pair giving the size of the images to be
		created. No default.
  Example:
    To create 256x256 standard images, use:

    * standard [256,256]
----------------------------------------------------------------------*/
{
  VARIABLE *v,*i_image,*j_image,*z_image;
  FLOAT *ival,*jval,*zval;
  int type,xdim,ydim,i,j;

  if(narg != 2) ERR_RETURN("### Bad number of parameters to the \'standard\' command\n",TRUE);
  if((v = evaluate(arg[1])) == NULL) return(TRUE);
  type = v->type;
  xdim = v->val[0];
  ydim = v->val[1];
  vardelete(v);
  if(type != TYPE_COORD)
    ERR_RETURN("### The argument to \'standard\' must be an integer pair\n",TRUE);
  if( xdim <= 0 || ydim <= 0)
    ERR_RETURN("### Image dimensions in \'standard\' are not positive\n",TRUE);

/* Generate the images. */

  i_image = varmake(TYPE_REAL,xdim,ydim);
  i_image->name = Malloc(2*sizeof(char));
  i_image->temporary = FALSE;
  ival = (FLOAT *)(i_image->value);
  strcpy(i_image->name,"i");

  j_image = varmake(TYPE_REAL,xdim,ydim);
  j_image->name = Malloc(2*sizeof(char));
  j_image->temporary = FALSE;
  jval = (FLOAT *)(j_image->value);
  strcpy(j_image->name,"j");

  z_image = varmake(TYPE_REAL,xdim,ydim);
  z_image->name = Malloc(5*sizeof(char));
  z_image->temporary = FALSE;
  zval = (FLOAT *)(z_image->value);
  strcpy(z_image->name,"zero");

/* Fill in the values of the images. */

  for(j=0; j < ydim; j++)for(i=0; i < xdim; i++){
    *ival++ = i + 1;
    *jval++ = j + 1;
    *zval++ = 0;
  }

/* Save the values now. */

  varput(i_image);
  varput(j_image);
  varput(z_image);

  return(FALSE);
}
/**********************************************************************/
/* private int contour_com(narg,arg)
int narg;
char *arg[]; */
/*
  This uses the standard UNIX plotting package, and a simple contouring
  algorithm to draw a contour plot of an image.

  Arguments:
    arg[1]	The image to be contoured.
    arg[2]	Several contouring levels.
----------------------------------------------------------------------*/
/* {
  FLOAT levels[MAXARG],delta,xscale,yscale,maxv,minv,*f;
  int nlev,i;
  VARIABLE *v;
  char *s;

  if(narg < 2 || narg > 3)
    ERR_RETURN("### Incorrect number of arguments for the \'contour\' command\n",TRUE);
  if((v = evaluate(arg[1])) == NULL)return(TRUE);
  if(v->type != TYPE_REAL || v->xdim * v->ydim == 0){
    vardelete(v);
    ERR_RETURN("### First arg to \'contour\' must be a real image\n",TRUE);
  }
*/
/* Determine the default contour levels, if needed. */
/*
  if(narg == 2){
*/
/* Determine the max and min values, and the default levels (10%). */
/*
    f = (FLOAT *)(v->value);
    maxv = minv = *f;
    for(i=0; i < v->xdim * v->ydim; i++){
      if(*f > maxv) maxv = *f;
      else if(*f < minv) minv = *f;
      f++;
    }
    delta = 0.1 * max(abs(maxv),abs(minv));
    nlev = 0;
    for(i=1; i < 10; i++){
      if(minv <  i*delta &&  i*delta < maxv) levels[nlev++] =  i*delta;
      if(minv < -i*delta && -i*delta < maxv) levels[nlev++] = -i*delta;
    }
*/
/* Use the user-specified contour levels. */
/*
  } else {
    s = arg[2];
    nlev = 0;
    while(*s != 0){
      if((s = real_value(s,levels + nlev++)) == NULL){
	vardelete(v); return(TRUE);
      }
    }
  }
*/
/* Determine scale factors, initialise the plotter, then do the plotting. */
/*
  xscale = 3120./(v->xdim-1);
  yscale = 3120./(v->ydim-1);
  openpl();
  space(0,0,3120,3120);
  erase();
  move(0,0); cont(0,3120); cont(3120,3120); cont(3120,0); cont(0,0);
  contour((FLOAT *)(v->value),v->xdim,v->ydim,levels,nlev,xscale,yscale);
  closepl();
  vardelete(v);
  return(FALSE);
}
*/
/**********************************************************************/
private int dump_com(narg,arg)
int  narg;
char *arg[];
/*
  This dumps out a real image. This does not perform any sub-imaging
  nor scaling (the numbers are rounded to the nearest integer on
  output).
----------------------------------------------------------------------*/
{
  VARIABLE *v;
  int i,j,val,logmaxv;
  FLOAT *f,maxv,minv;
  char fmt[5];

  if(narg != 2)ERR_RETURN("### Bad \'dump\' command\n",TRUE);
  v = evaluate(arg[1]);
  if(v == NULL) return(TRUE);
  if(v->type != TYPE_REAL || v->xdim * v->ydim == 0) summary(v);
  else{
    f = (FLOAT *)(v->value);
    maxv = minv = *f;
    for(i=0; i < v->xdim * v->ydim; i++){
      maxv = max(maxv,*f); minv = min(minv,*f);
      f++;
    }
    maxv = max(maxv,abs(minv));
    logmaxv = (minv <= -1 ? 2 : 1);
    while(maxv >= 1){
      maxv *= 0.1;
      logmaxv++;
    }
    if(logmaxv > 8){
      fprintf(stderr,"### The image values are too large to print\n");
      return(TRUE);
    }
    sprintf(fmt,"%%%dd",logmaxv);
    f = (FLOAT *)(v->value);
    for(j=0; j < v->ydim; j++){
      for(i=0; i < v->xdim; i++){
	val = *f++;
	printf(fmt,val);
      }
      printf("\n");
    }
  }
  vardelete(v);
  return(FALSE);
}
/**********************************************************************/
private int histogram_com(narg,arg)
int  narg;
char *arg[];
/*
  This histograms a real image. This does not perform any sub-imaging.

  Parameters:
    arg[1]	A real image expression.
    arg[2]	Optional. The min and max values to use in determining
		the histogram. Default is the image min and max.
----------------------------------------------------------------------*/
{
#define NBIN 16
  VARIABLE *v;
  int i,j,val,bins[NBIN],maxbin,underflow,overflow;
  FLOAT *f,t,scale,maxv,minv;
  char *s,line[33];

  if(narg > 3 || narg < 2)ERR_RETURN("### Bad \'histogram\' command\n",TRUE);
  v = evaluate(arg[1]);
  if(v == NULL) return(TRUE);
  if(v->type != TYPE_REAL || v->xdim * v->ydim == 0){
    vardelete(v);
    ERR_RETURN("### First arg to \'histogram\' must be a real image\n",TRUE);
  }

/* Determine the default contour range, if needed. */

  if(narg == 2){
    f = (FLOAT *)(v->value);
    maxv = minv = *f;
    for(i=0; i < v->xdim * v->ydim; i++){
      if(*f > maxv) maxv = *f;
      else if(*f < minv) minv = *f;
      f++;
    }

/* Use the user-specified limits. */

  } else {
    s = arg[2];
    if((s = real_value(s,&maxv)) == NULL){ vardelete(v); return(TRUE);}
    if((s = real_value(s,&minv)) == NULL){ vardelete(v); return(TRUE);}
    if(*s != 0){
      vardelete(v);
      ERR_RETURN("### Bad high and low levels for histogramming\n",TRUE);
    }
    if(maxv < minv){ t = maxv; maxv = minv; minv = t; }
  }

  if(maxv == minv){
    printf("The min and max range values are %g\n",maxv);

/* All appears OK. Calculate the histogram. */

  } else {
    for(j=0; j < NBIN; j++) bins[j] = 0;
    underflow = overflow = 0;

    f = (FLOAT *)(v->value);
    scale = NBIN/(maxv - minv);
    for(i=0; i < v->xdim * v->ydim; i++){
      if(*f < minv) underflow++;
      else if(*f > maxv) overflow++;
      else {
        j = scale * (*f - minv);
        j = min(max(j,0),NBIN-1);
        bins[j]++;
      }
      f++;
    }
    vardelete(v);

/* Now output the histogram. */

    maxbin = 0;
    for(j=0; j < NBIN; j++) if(bins[j] > maxbin) maxbin = bins[j];
    scale = 32.0 / maxbin;
    printf("Underflow  %8d\n",underflow);
    for(j=0; j < NBIN; j++){
      i = (32 * bins[j]) / maxbin;
      strncpy(line,"********************************",i);
      line[i] = 0;
      scale = j*(maxv-minv)/NBIN + minv;
      printf("%10.3g %8d %s\n",scale,bins[j],line);
    }
    printf("Overflow   %8d\n",overflow);
  }
  vardelete(v);
  return(FALSE);
}
/**********************************************************************/
private int write_com(narg,arg)
int narg;
char *arg[];
/*
  This writes out the value of non-image expressions.
----------------------------------------------------------------------*/
{
  char *s;
  int i,j;
  VARIABLE *v;

  if(narg != 2)ERR_RETURN("### Bad \'write\' command\n",TRUE);
  s = arg[1];
  while(*s != 0){
    v = multi_evaluate(&s);
    if(v == NULL) return(TRUE);
    else if(v->xdim * v->ydim != 0) {
      vardelete(v);
      ERR_RETURN("### Cannot \'write\' images\n",TRUE);
    }
    switch(v->type){
      case TYPE_STRING:
	printf("%s",v->value);
	break;
      case TYPE_COORD:
	i = v->val[0]; j = v->val[1];
	printf("[%d,%d]",i,j);
	break;
      case TYPE_REAL:
	printf("%g",v->val[0]);
	break;
      case TYPE_CMPLX:
	printf("(%g,%g)",v->val[0],v->val[1]);
	break;
    }
    vardelete(v);
  }
  printf("\n");
  return(FALSE);
}
/**********************************************************************/
private int insert_com(narg,arg)
int narg;
char *arg[];
/*
  This inserts a value into an image.
  Arguments:
    arg[1]  The name of the image.
    arg[2]  The value to insert. Can be real or complex.
    arg[3]  A coordinate giving the place to insert the pixel.
----------------------------------------------------------------------*/
{
  FLOAT *f,value[2];
  int coord[2];
  char *s;
  VARIABLE *v;

  if(narg != 4)ERR_RETURN("### Bad \'insert\' command\n",TRUE);
  if((v = varget(arg[1])) == NULL)
    ERR_RETURN("### Did not find the image, given by the first arg\n",TRUE);
  if(v->type != TYPE_REAL && v->type != TYPE_CMPLX)
    ERR_RETURN("### First arg of \'insert\' must be an image\n",TRUE);
  if(v->xdim * v->ydim == 0)
    ERR_RETURN("### First arg of \'insert\' must be a real image\n",TRUE);

  if((s = coord_value(arg[3],coord)) == NULL) return(TRUE);
  if(*s != 0)ERR_RETURN("### Third arg to \'insert\' must be an integer pair\n",TRUE);
  if(coord[0] <= 0 || coord[0] > v->xdim || coord[1] <= 0 || coord[1] > v->ydim)
    ERR_RETURN("### Pixel location is outside the image\n",TRUE);
  coord[0]--; coord[1]--;
  f = (FLOAT *)(v->value);

  if(v->type == TYPE_REAL){
    if((s = real_value(arg[2],value)) == NULL)return(TRUE);
    if(*s != 0)ERR_RETURN("### Second arg to \'insert\' must be a single value\n",TRUE);
    f += coord[1]*v->xdim + coord[0];
    *f++ = value[0];
  }else {
    if((s=cmplx_value(arg[2],value)) == NULL)return(TRUE);
    if(*s != 0)ERR_RETURN("### Second arg to \'insert\' must be a single value\n",TRUE);
    f += 2*coord[1]*v->xdim + 2*coord[0];
    *f++ = value[0];
    *f++ = value[1];
  }
  return(FALSE);
}
/**********************************************************************/
private int summary_com(narg,arg)
int narg;
char *arg[];
/*
  This gives a brief description of an expression. 
----------------------------------------------------------------------*/
{
  VARIABLE *v;

  if(narg != 2)ERR_RETURN("### Bad \'summary\' command\n",TRUE);
  v = evaluate(arg[1]);
  if(v == NULL) return(TRUE);
  summary(v);
  vardelete(v);
  return(FALSE);
}
/**********************************************************************/
private void summary(a)
VARIABLE *a;
/*
  This writes a summary of the value of a variable to the standard
  output.

  Input:
    a		The variable to give a summary about.
----------------------------------------------------------------------*/
{
  int i,j;
  char *name,*ntype,line[MAXLINE];

  if(a->name == NULL) name = "The expression";
  else {
    sprintf(line,"The variable %s",a->name);
    name = line;
  }
  if(a->xdim * a->ydim == 0)switch(a->type){
    case TYPE_STRING:
      printf("%s is a string: \'%s\'\n",name,a->value);
      break;
    case TYPE_COORD:
      i = a->val[0]; j = a->val[1];
      printf("%s is a integer pair: [%d,%d]\n",name,i,j);
      break;
    case TYPE_REAL:
      printf("%s is a real number: %g\n",name,a->val[0]);
      break;
    case TYPE_CMPLX:
      printf("%s is a complex number: (%g,%g)\n",
			name,a->val[0],a->val[1]);
      break;
  } else {
    ntype = (a->type == TYPE_REAL ? "real" : "complex");
    printf("%s is a %s image of size: %d x %d\n",
					name,ntype,a->xdim,a->ydim);
  }
}
/**********************************************************************/
VARIABLE *push_x(token)
TOKEN *token;
/*
  This is the routine responsible for "pushing" a value onto the output
  stack. In reality, all it does it pass back the VARIABLE structure,
  which is already contained within the TOKEN structure.

  Input:
    token	The TOKEN structure.
  Output:
    push_x	The corresponding VARIABLE structure.
----------------------------------------------------------------------*/
{
  return(token->v);
}
/**********************************************************************/
private void hashinit()
/*
  This initialises the operator and variable hash table.
----------------------------------------------------------------------*/
{
  int i,j;
  OPERATOR *op;
  char *s;

  for(i=0; i < NHASH; i++){
    varhash[i] = NULL;
    operhash[i] = NULL;
  }
  for(i=0; i < NOPERS; i++){
    op = operators + i;
    j = 0;
    for(s = op->name; *s != 0; s++) j += *s;
    j %= NHASH;
    op->fwd = operhash[j];
    operhash[j] = op;
  }
}
/**********************************************************************/
private char *real_value(exp,val)
char *exp;
FLOAT *val;
/*
  This decodes a real value, and returns the pointer in the input
  expression, to the next expression.
----------------------------------------------------------------------*/
{
  VARIABLE *v;
  v = multi_evaluate(&exp);
  if(v == NULL)exp = NULL;
  else if(v->type != TYPE_REAL || v->xdim*v->ydim != 0){
    fprintf(stderr,"### Expression is not real-valued\n");
    exp = NULL;
  } else *val = v->val[0];
  if(v != NULL)vardelete(v);
  return(exp);
}
/**********************************************************************/
private char *cmplx_value(exp,val)
char *exp;
FLOAT val[2];
/*
  This decodes a complex value, and returns the pointer in the input
  expression, to the next expression.
----------------------------------------------------------------------*/
{
  VARIABLE *v;
  v = multi_evaluate(&exp);
  if(v == NULL)exp = NULL;
  else if(v->type != TYPE_REAL || v->xdim*v->ydim != 0){
    fprintf(stderr,"### Expression is not real-valued\n");
    exp = NULL;
  } else {
    val[0] = v->val[0];
    val[1] = v->val[1];
  }
  if(v != NULL)vardelete(v);
  return(exp);
}
/**********************************************************************/
private char *coord_value(exp,val)
char *exp;
int val[2];
/*
  This decodes an integer-pair value, and returns the pointer in the input
  expression, to the next expression.
----------------------------------------------------------------------*/
{
  VARIABLE *v;
  v = multi_evaluate(&exp);
  if(v == NULL)exp = NULL;
  else if(v->type != TYPE_COORD || v->xdim*v->ydim != 0){
    fprintf(stderr,"### Expression is not an integer-pair\n");
    exp = NULL;
  } else {
    val[0] = v->val[0];
    val[1] = v->val[1];
  }
  if(v != NULL)vardelete(v);
  return(exp);
}
/**********************************************************************/
private char *string_value(exp,val)
char *exp;
char *val;
/*
  This decodes a string value, and returns the pointer in the input
  expression, to the next expression.
----------------------------------------------------------------------*/
{
  VARIABLE *v;
  v = multi_evaluate(&exp);
  if(v == NULL)exp = NULL;
  else if(v->type != TYPE_STRING){
    fprintf(stderr,"### Expression is not string-valued\n");
    exp = NULL;
  } else strcpy(val,v->value);
  if(v != NULL)vardelete(v);
  return(exp);
}
/**********************************************************************/
private VARIABLE *multi_evaluate(mexp)
char **mexp;
/*
  This is used to evaluate a number of expressions separated by commas.

  Input/Output:
    mexp	A pointer to a pointer to the expressions to evaluate.
		On return, this is updated to point to the next
		expression.
  Output:
    multi_evaluate A pointer to a VARIABLE structure which is the result
		of the expression just analysed.
----------------------------------------------------------------------*/
{
  char expression[MAXLINE],*s,*t;
  int instring,more,bracketting;

  s = *mexp;
  t = expression;
  instring = FALSE; more = TRUE;
  bracketting = 0;
  while(more){
    if(*s == 0) more = FALSE;
    else if(instring)instring = *s != '\'';
    else if(*s == '\'') instring = TRUE;
    else if(*s == ',' && bracketting == 0) more = FALSE;
    else if(*s == '(' || *s == '[') bracketting ++;
    else if(*s == ')' || *s == ']') bracketting --;
    if(more) *t++ = *s++;
  }
  *t = 0;
  if(*s == ',')s++;
  *mexp = s;
  return(evaluate(expression));
}
/**********************************************************************/
VARIABLE *evaluate(expression)
char *expression;
/*
  This executes the actual calculations.

  Input:
    expression	A string in a FORTRAN-like syntax giving the expression to
		be evaluated.
  Output:
    evaluate	A variable structure, giving the result of the calculation.
		If there is an error, or if there is no output, a NULL is
		returned.
----------------------------------------------------------------------*/
{
  TOKEN *token,*tokenlist;
  VARIABLE *v,*arg1,*arg2,*stack[MAXSTACK];
  int nstack,i;
  OPERATOR *op;

/* Parse the expression. */

  tokenlist = parse(expression);
  if(tokenlist == NULL) return(NULL);

  nstack = 0;
  do{
    arg1 = arg2 = NULL;
    token = tokenlist;
    op = token->op;
    v = NULL;
    switch(op->narg){
      case 0:
	v = (*(op->x_routine))(token);
	break;
      case 1:
 	arg1 = stack[--nstack];
	if(op->x_routine != NULL) v = (*(op->x_routine))(arg1);
	else if(arg1->type == TYPE_STRING)
	  fprintf(stderr,"### Cannot do operation %s on strings\n",op->name);
	else if(arg1->type == TYPE_COORD) 
	  v = coord_op1(op,arg1);
	else if(arg1->type == TYPE_REAL)
	  v = real_op1(op,arg1);
	else if(arg1->type == TYPE_CMPLX)
	  v = cmplx_op1(op,arg1);
	break;
      case 2:
	arg2 = stack[--nstack]; arg1 = stack[--nstack];
	if(op->x_routine != NULL)
	  v = (*(op->x_routine))(arg1,arg2);
	else if(arg1->type != TYPE_REAL || arg2->type != TYPE_REAL)
	  fprintf(stderr,"### Cannot do operation %s on this data\n",op->name);
	else if(arg1->xdim * arg1->ydim != 0 && arg2->xdim * arg2->ydim != 0
		&& (arg1->xdim != arg2->xdim || arg1->ydim != arg2->ydim) )
	  fprintf(stderr,"### Cannot use operator %s on images of differing sizes\n",op->name);
	else
	  v = real_op2(op,arg1,arg2);
	break;
      default:
	fprintf(stderr,"Should never get here, in execute\n");
	exit(1);
    }

/* Delete any unwanted variables, and link in the resultant variable. */

    if(arg1 != NULL) vardelete(arg1);
    if(arg2 != NULL) vardelete(arg2);
    if(v != NULL) stack[nstack++] = v;
    tokenlist = token->fwd;
    token->fwd = NULL; token->v = NULL; tokdelete(token);
  }while(v != NULL && tokenlist != NULL);

/* Check for a possible internal error. */

  if(nstack != 1 && v != NULL){
    fprintf(stderr,"### Still %d values on the stack, in evaluate\n",nstack);
    exit(1);
  }

/* If an error has occurred, then there may be variables left on the
   stack, and TOKENs still to be executed. Delete these. */

  if(v == NULL){
    for(i=0; i < nstack; i++)vardelete(stack[i]);
    if(tokenlist != NULL) tokdelete(tokenlist);
  }

/* Return with the results. */

  return(v);
}
/**********************************************************************/
private VARIABLE *coord_op1(op,v)
OPERATOR *op;
VARIABLE *v;
/*
  This performs a unary operation on a coordinate, returning the result
  as a VARIABLE structure.

  Inputs:
    op		The OPERATOR structure, giving the operation to be
		performed.
    v		The VARIABLE structure, containing the coordinate to
		operate on.
  Output:
    coord_op1	A VARIABLE structure, with the result.
----------------------------------------------------------------------*/
{
  VARIABLE *var;
  if(op->r_routine == NULL) {
    var = NULL;
    fprintf(stderr,"### Cannot use operator %s on coordinates\n",op->name);
  } else {
    var = varmake(TYPE_COORD,0,0);
    var->val[0] = (*(op->r_routine))((double)(v->val[0]));
    var->val[1] = (*(op->r_routine))((double)(v->val[1]));
  }
  return(var);
}
/**********************************************************************/
private VARIABLE *real_op1(op,v)
OPERATOR *op;
VARIABLE *v;
/*
  This performs a unary operation on a real, returning the result
  as a VARIABLE structure.

  Inputs:
    op		The OPERATOR structure, giving the operation to be
		performed.
    v		The VARIABLE structure, containing the real to
		operate on.
  Output:
    real_op1	A VARIABLE structure, with the result.
----------------------------------------------------------------------*/
{
  VARIABLE *var;
  int nval,i;
  FLOAT *in,*out;

  if(op->r_routine == NULL) {
    var = NULL;
    fprintf(stderr,"### Cannot use operator %s on reals\n",op->name);
  } else {
    nval = v->xdim * v->ydim;
    var = varmake(TYPE_REAL,v->xdim,v->ydim);
    if(nval == 0)
      var->val[0] = (*(op->r_routine))((double)(v->val[0]));
    else{
      in = (FLOAT *)(v->value);
      out = (FLOAT *)(var->value);
      for(i=0; i < nval; i++) *out++ = (*(op->r_routine))((double)(*in++));
    }
  }
  return(var);
}
/**********************************************************************/
private VARIABLE *cmplx_op1(op,v)
OPERATOR *op;
VARIABLE *v;
/*
  This performs a unary operation on a complex value, returning the result
  as a VARIABLE structure.

  Inputs:
    op		The OPERATOR structure, giving the operation to be
		performed.
    v		The VARIABLE structure, containing the complex value to
		operate on.
  Output:
    cmplx_op1	A VARIABLE structure, with the result.
----------------------------------------------------------------------*/
{
  VARIABLE *var;
  int nval,i,inc;
  FLOAT *in,*out;

  if(op->c_routine == NULL) {
    var = NULL;
    fprintf(stderr,"### Cannot use operator %s on complex values\n",op->name);
  } else {
    if(op->flags & OP_ROUT){
      var = varmake(TYPE_REAL,v->xdim,v->ydim);
      inc = 1;
    } else {
      var = varmake(TYPE_CMPLX,v->xdim,v->ydim);
      inc = 2;
    }
    nval = v->xdim * v->ydim;
    if(nval == 0){
      (void)(*(op->c_routine))(v->val,var->val);
    }else{
      in = (FLOAT *)(v->value);
      out = (FLOAT *)(var->value);
      for(i=0; i < nval; i++){
	(void)(*(op->c_routine))(in,out);
	in += 2; out += inc;
      }
    }
  }
  return(var);
}
/**********************************************************************/
private VARIABLE *real_op2(op,v1,v2)
OPERATOR *op;
VARIABLE *v1,*v2;
/*
  This performs a binary operation on reals, returning the result
  as a VARIABLE structure.

  Inputs:
    op		The OPERATOR structure, giving the operation to be
		performed.
    v1		The VARIABLE structure, containing the first real.
    v2		The VARIABLE structure, containing the second real.
  Output:
    real_op2	A VARIABLE structure, with the result.
----------------------------------------------------------------------*/
{
  VARIABLE *var;
  int nval1,nval2,i;
  FLOAT *in1,*in2,*out;

  if(op->r_routine == NULL) {
    var = NULL;
    fprintf(stderr,"### Cannot use operator %s on real values\n",op->name);
  } else {
    var = varmake(TYPE_REAL,
			max(v1->xdim,v2->xdim),max(v1->ydim,v2->ydim));
    nval1 = v1->xdim * v1->ydim;
    nval2 = v2->xdim * v2->ydim;
    in1 = (FLOAT *)(v1->value);
    in2 = (FLOAT *)(v2->value);
    out = (FLOAT *)(var->value);

/* Case of both scalar arguments. */

    if(nval1 == 0 && nval2 == 0){
      var->val[0] = (*(op->r_routine))((double)(v1->val[0]),(double)(v2->val[0]));

/* Case of the second argument being an image. */

    } else if(nval1 == 0){
      for(i=0; i < nval2; i++)
	*out++ = (*(op->r_routine))((double)(v1->val[0]),(double)(*in2++));

/* Case of the first argument being an image. */

    } else if(nval2 == 0) {
      for(i=0; i < nval1; i++)
	*out++ = (*(op->r_routine))((double)(*in1++),(double)(v2->val[0]));

/* Case of both arguments being images. */

    } else {
      for(i=0; i < nval2; i++)
	*out++ = (*(op->r_routine))((double)(*in1++),(double)(*in2++));
    }
  }
  return(var);
}
/**********************************************************************/
private TOKEN *parse(exp)
char *exp;
/*
  This parses an expression, and returns a sequence of operations to
  be performed. The sequence is in reverse polish.

  Input:
    exp		The expression to be parsed.
  Output:
    parse	A pointer to a linked list of operations that are
		called for in the expression.
-----------------------------------------------------------------------*/
{
  TOKEN *head,*stack,*token;
  char opername[MAXLINE],*s;
  int expect_oper,opertype,bad,docmplx,ncomma;

  head = stack = NULL;
  expect_oper = bad = FALSE;
  ncomma = 0; docmplx = TRUE;

  bad = tokpush(&head,&stack,tokget("("),0);
  while( *exp != 0 && !bad ){
    s = getopts(exp,opername,docmplx,&opertype);
    bad = (s == exp);
    if(bad) break;
    if(opertype != TYPE_OTHER) token = pushop(opername,opertype);
    else if(!expect_oper && opername[0] == '-') token = tokget("$uminus");
    else if(opername[0] == '('){
      if(expect_oper)
        if(bad = tokpush(&head,&stack,tokget("$extract"),0))break;
      token = tokget("(");
      expect_oper = FALSE;
    } else if(opername[0] == '['){
      if(expect_oper)
	if(bad = tokpush(&head,&stack,tokget("$shift"),0))break;
      expect_oper = FALSE;
      if(bad = tokpush(&head,&stack,tokget("$coord"),0))break;
      token = tokget("["); ncomma = 1;
    } else  token = tokget(opername);

/* Check that we got something. */

    if(token == NULL){
      bad = TRUE;
      fprintf(stderr,"### Unknown variable or function %s\n",opername);
      break;
    }

/* Check that we got an operator or value (which ever one we were expecting. */

    if((expect_oper && !(token->op->flags & OP_OPER)) || 
       (!expect_oper && (token->op->flags & OP_OPER))){
      bad = TRUE;
      fprintf(stderr,"### Expression was not made of 'val op val'\n");
      break;
    }

/* Set whether we are expecting an operator or value next. */

    expect_oper = token->op->flags & OP_NOPER;
    bad = tokpush(&head,&stack,token,ncomma);

/* If this was a function call, remember the number of commas that
   we are to expect. */

    if(token->op->flags & OP_FUNC){
      ncomma = token->op->narg - 1;
      docmplx = FALSE;
    } else {
      ncomma = 0;
      docmplx = TRUE;
    }
    exp = s;
  }

/* We have finished with the expression (possibly we found a parsing
   error). Make various extra checks, and finish up. */

  if(!bad && !expect_oper){
    bad = TRUE;
    fprintf(stderr,"### Expecting a value at the end of the expression\n");
  }
  if(!bad) bad = tokpush(&head,&stack,tokget(")"),0);
  if(!bad && stack != NULL){
    bad = TRUE;
    fprintf(stderr,"### Incomplete expression\n");
  }

/* Delete things that were left on the top of the stack. */

  tokdelete(stack);

/* If things went wrong, delete all the things on the list to be evaluated. */

  if(bad){
    tokdelete(head);
    head = NULL;
  }

/* Return the result of this all. */

  return(head);
}
/**********************************************************************/
VARIABLE *varcopy(name,var)
char *name;
VARIABLE *var;
/*
  This makes a copy of a variable, giving it a new name.

  Input:
    name	The name to be given to the variable.
    var		The VARIABLE structure giving the variable to copy.
  Output:
    varcopy	A copy of the variable.
----------------------------------------------------------------------*/
{
  VARIABLE *v;
  int ndim;
  v = varmake(var->type,var->xdim,var->ydim);

/* Copy the name and the value across. */

  if(name != NULL){
    v->name = Malloc(strlen(name)+1);
    strcpy(v->name,name);
  }
  ndim = v->xdim * v->ydim;
  switch(v->type){
    case TYPE_COORD:
      v->val[0] = var->val[0];
      v->val[1] = var->val[1];
      break;
    case TYPE_STRING:
      v->value = Malloc(strlen(var->value)+1);
      strcpy(v->value,var->value);
      break;
    case TYPE_REAL:
      if(ndim == 0) v->val[0] = var->val[0];
      else memcpy(v->value,var->value,sizeof(FLOAT) * ndim);
      break;
    case TYPE_CMPLX:
      if(ndim == 0){v->val[0] = var->val[0]; v->val[1] = var->val[1];}
      else memcpy(v->value,var->value,2 * sizeof(FLOAT) * ndim);
      break;
    default:
      fprintf(stderr,"### Should never get here, in varcopy\n");
      exit(1);
  }
  return(v);
}
/**********************************************************************/
void vardelete(var)
VARIABLE *var;
/*
  This deletes a variable.

  Input:
    var		The VARIABLE structure to be deleted.
----------------------------------------------------------------------*/
{
  if(! var->temporary) return;
  if(var->name != NULL) free(var->name);
  if(var->value != NULL) free(var->value);
  free((char *)var);
}
/***********************************************************************/
private void varput(var)
VARIABLE *var;
/*
  This adds a variable to the variable hash table. It first checks with
  a variable with the same name exists. If so, it replaces the old value
  and deletes anything necessary.

  Input:
    var		The VARIABLE structure containing the variable.
----------------------------------------------------------------------*/
{
  int j;
  char *s;
  VARIABLE *prev,*v;

/* Search for the variable in the hash table (remember to keep a link to
   the previous structure. */

  j = 0;
  for(s=var->name; *s != 0; s++) j += *s;
  prev = NULL;
  for(v=varhash[j%NHASH]; v != NULL; v=v->fwd){
    if(!strcmp(v->name,var->name))break;
    prev = v;
  }

/* If we found the variable, unlink it and delete it. */

  if(v != NULL){
    if(prev != NULL) prev->fwd = v->fwd;
    else	     varhash[j%NHASH] = v->fwd;
    if(v->xdim * v->ydim > 0)free(v->value);
    free(v->name);
    free((char *)v);
  }

/* Link in the new value. */

  var->fwd = varhash[j%NHASH];
  varhash[j%NHASH] = var;
}
/**********************************************************************/
char *Malloc(size)
int size;
{
  char *s;
  char *malloc();

  if (NULL == (s = malloc(size)))
     {fprintf(stderr,"### Ran out of memory. Aborting ...\n");
      exit(1);
     }
  else;
  return(s);
}
/**********************************************************************/
VARIABLE *varmake(type,xdim,ydim)
int type,xdim,ydim;
/*
  This creates a new temporary variable, and returns it to the caller.
  For images, this also creates the array to contain the pixel data.

  Input:
    type	The type of the variable to be made. This can be
		  TYPE_REAL
		  TYPE_CMPLX
		  TYPE_STRING
		  TYPE_COORD
    xdim	The x dimension of an image.
    ydim	The y dimension of an image.
  Output:
    varmake	A pointer to a new VARIABLE structure.
----------------------------------------------------------------------*/
{
  VARIABLE *v;

  v = (VARIABLE *)Malloc(sizeof(VARIABLE));
  v->temporary = TRUE;
  v->xdim = xdim;
  v->ydim = ydim;
  v->value = v->name = NULL;
  v->fwd = NULL;
  v->type = type;
  if(xdim*ydim > 0)
    v->value = Malloc(xdim*ydim*sizeof(FLOAT)*(type == TYPE_REAL ? 1 : 2));
  return(v);
}
/***********************************************************************/
private VARIABLE *varget(varname)
char *varname;
/*
  This searches the variable hash table, and returns a pointer to the
  named variable.

  Input:
    varname	Name of the variable to search for.
  Output:
    varget	A pointer to the VARIABLE structure of the variable.
		If the variable was not found, a null is returned.
----------------------------------------------------------------------*/
{
  int j;
  char *s;
  VARIABLE *v;

  j = 0;
  for(s=varname; *s != 0; s++) j += *s;
  for(v=varhash[j%NHASH]; v != NULL; v=v->fwd)
    if(!strcmp(v->name,varname))break;
  return(v);
}
/***********************************************************************/
private TOKEN *tokget(opername)
char *opername;
/*
  This finds an operator in the operator hash table, and then creates
  a TOKEN structure to link this to.

  Inputs:
    opername	The name of the operator.
  Outputs:
    tokget	A TOKEN struct linked with the appropriate OPERATOR struct.
-------------------------------------------------------------------------*/
{
  int j;
  char *s;
  OPERATOR *op;
  TOKEN *token;

  j = 0;
  for(s = opername; *s != 0; s++) j += *s;
  for(op = operhash[j % NHASH]; op != NULL; op = op->fwd)
    if(!strcmp(op->name,opername))break;

  if(op == NULL) return(NULL);
  token = (TOKEN *)Malloc(sizeof(TOKEN));
  token->op = op;
  token->v = NULL;
  token->fwd = NULL;
  return(token);
}
/************************************************************************/
private void tokdelete(tokenlist)
TOKEN *tokenlist;
/*
  This deletes a linked list of tokens. It also deletes any temporary
  variables associated with the token.

  Input:
    tokenlist	A linked list of tokens.
------------------------------------------------------------------------*/
{
  TOKEN *next;

  while(tokenlist != NULL){
    next = tokenlist->fwd;
    if(tokenlist->v != NULL) vardelete(tokenlist->v);
    free((char *)tokenlist);
    tokenlist = next;
  }
}
/************************************************************************/
private int tokpush(head,stack,token,ncomma)
int ncomma;
TOKEN **head,**stack;
TOKEN *token;
/*
  This is the routine responsible for converting a sequence of tokens,
  in algebraic order, into reverse polish order.

  Input:
    token	A TOKEN struct describing the operator to do.
    ncomma	If the token is '(' or '[', this gives the number of
		commas to expect before the closing ')' or ']'.
  Input/Output:
    head	The head of the output list.
    stack	The head of an intermediate stack.
  Output:
    tokpush	Either FALSE or TRUE, indicating success or failure
		respectively.
------------------------------------------------------------------------*/
{
  OPERATOR *op;
  TOKEN *out;
  char c;

  c = *(token->op->name);

  out = NULL;
  if(c != '(' && c != '[')while(*stack != NULL){
    op = (*stack)->op;
    if( op->prec < token->op->prec) break;
    if(*head == NULL){
      *head = *stack;
      out = *head;
    } else {
      if(out == NULL)for(out = *head; out->fwd != NULL; out = out->fwd);
      out->fwd = *stack;
      out = *stack;
    }
    *stack = (*stack)->fwd;
    out->fwd = NULL;
  }
  if(c == ',' || c == ')' || c == ']'){
    tokdelete(token);
    if(*stack == NULL)ERR_RETURN("### Mismatching close bracket\n",TRUE);
    op = (*stack)->op;
    if(c == ','){
      if( --((*stack)->ncomma) < 0)
	ERR_RETURN("### Bad bracketting or unexpected comma in expression\n",TRUE);
    } else {
      if((c == ')' && *(op->name) != '(') ||
	 (c == ']' && *(op->name) != '[') )
	ERR_RETURN("### Incorrect bracket nesting\n",TRUE);
      if((*stack)->ncomma != 0)
	ERR_RETURN("### Incorrect number of function or integer pair args\n",TRUE);
      token = *stack;
      *stack = token->fwd;
      token->fwd = NULL;
      tokdelete(token);
    }
  } else {
    token->fwd = *stack;
    token->ncomma = ncomma;
    *stack = token;
  } 
  return(FALSE);
}
/***********************************************************************/
private char *getopts(exp,token,docmplx,toktype)
int *toktype,docmplx;
char *exp,*token;
/*
  This extracts the next token from the input expression, and returns
  it to the caller.

  Inputs:
    exp		The input character string.
    docmplx	If true, then the token could be a complex value.
  Outputs:
    token	The next token found.
    gettoken	The remaining part of the character string.
    toktype	The type of the token. This can be one of
		  TYPE_REAL
		  TYPE_CMPLX
		  TYPE_VAR
		  TYPE_OTHER
-----------------------------------------------------------------------*/
{
  char *s,c,var[MAXLINE];
  VARIABLE *v;

/*  Determine the token type, and the extent of the token. */

  *toktype = TYPE_OTHER;
  if(docmplx && (s = skip_cmplx(exp)) != exp) *toktype = TYPE_CMPLX;
  else if(*exp == '(' || *exp == ')' || *exp == ',' || *exp == '[' || 
          *exp == ']' || *exp == '-' || *exp == '+'){
    s = exp + 1;
  } else if(*exp == '*' || *exp == '/'){
    c = *exp;
    for( s = exp; *s == c ; s++) ;
  } else if((s = skip_real(exp)) != exp) *toktype = TYPE_REAL;
  else if((s = skip_logical(exp)) != exp) ;
  else if(*exp == '\''){
    for(s = exp+1; *s != '\'' ; s++)if(*s == 0){
      fprintf(stderr,"### String constant not terminated by a quote\n");
      return(exp);
    }
    s ++;
    *toktype = TYPE_STRING;

/* A function or a variable. */
  } else if(isalpha(*exp)){
    for(s = exp; isalnum(*s); s++) ;
    if(*s != '(') *toktype = TYPE_VAR;
    else{
      strncpy(var,exp,s-exp); var[s-exp] = 0;
      v = varget(var);
      if(v != NULL)
	if((v->type == TYPE_REAL || v->type == TYPE_CMPLX) &&
	    v->xdim * v->ydim != 0) *toktype = TYPE_VAR;
    }
  } else {
    s = exp;
    fprintf(stderr,"### Cannot understand expression: %s\n",exp);
  }

/* Copy the token to the output, and return. */

  if(s != exp){
    strncpy(token,exp,s-exp);
    *(token+(s-exp)) = 0;
  }
  return(s);
}
/**********************************************************************/
private TOKEN *pushop(name,type)
char *name;
int type;
/*
  This sets up the TOKEN structure for one of the push operations.

  Input:
    name	A variable name, a string, a real or complex number.
    type	One of TYPE_VAR,TYPE_STRING,TYPE_REAL,TYPE_CMPLX.
  Output:
    pushop	Pointer to a TOKEN structure.
----------------------------------------------------------------------*/
{
  TOKEN *tok;
  VARIABLE *v;
  int length;
  double d1,d2;

  if(type != TYPE_VAR) v = varmake(type,0,0);
  switch(type){
    case TYPE_VAR:   v = varget(name);			   break;
    case TYPE_STRING:
      length = strlen(name) - 2;
      v->value = Malloc(length+1);
      strncpy(v->value,name+1,length);
      *(v->value + length) = 0;				   break;
    case TYPE_REAL:  sscanf(name,"%lg",&d1);
		     v->val[0] = d1;
		     break;
    case TYPE_CMPLX: sscanf(name,"(%lg,%lg)",&d1,&d2);
		     v->val[0] = d1;
		     v->val[1] = d2;
		     break;
    default:	fprintf(stderr,"Should never get here, in pushop\n");
		exit(1);
  }
  if(v == NULL) return(NULL);
  tok = tokget("$push");
  tok->v = v;
  return(tok);
}
/**********************************************************************/
private char *skip_cmplx(s)
char *s;
/*
  This skips over a complex value.

  Input:
    s		The string containing the complex value.
  Output:
    skip_cmplx	This points just beyond the complex value. If a valid
		complex value was not found, then this returns with the
		original value of s.
------------------------------------------------------------------------*/
{
  char *s1,*s2;
  if(*s != '(')				return(s);
  if((s1 = skip_real(s+1)) == s+1)	return(s);
  if(*s1 != ',')			return(s);
  if((s2 = skip_real(s1+1)) == s1+1)	return(s);
  if(*s2++ != ')')			return(s);
  return(s2);
}
/**********************************************************************/
private char *skip_arg(s)
char *s;
/*
  This skips over characters unti we hit a blank or tab outside quotes.

  Input:
    s		Pointer to the string of interest.
  Output:
    skip_arg	Points to the first blank, tab or \0 after the arg.
----------------------------------------------------------------------*/
{
  int nquote;

  nquote = 0;
  while(*s != 0 && ( (nquote % 2) != 0 || (*s != ' ' && *s != '\t'))) 
    if(*s++ == '\'') nquote++;
  return(s);
}
/**********************************************************************/
private char *skip_real(s)
char *s;
/*
  This skips over a real value, and points at the first character after
  the real value. There is a problem determining the end of a real value
  and the start of a logical operator, so this has to explicitly look
  for the start of a logical operator.

  Input:
    s		The string to parse.
  Output:
    skip_real	This points to one character beyond the end of the real
		value. If the input string does not start with a real
		value, this returns the input pointer.
------------------------------------------------------------------------*/
{
  char *s0,*s1,*s2;
  int have_expo,have_whole,have_frac;
  have_expo = have_whole = have_frac = FALSE;

/* Skip through the whole part of the number. */

  s0 = s;
  if(*s0 == '-')s0++;
  for(s1 = s0; isdigit(*s1); s1++) ;
  have_whole = s0 != s1;

/* If we have a whole part, and the remainder is a logical op., return
   successfully with the whole part. */

  if(have_whole && *s1 == '.' && skip_logical(s1) != s1) return(s1);

/* Handle the fractional part if there is one. */

  if( *s1 == '.'){
    for(s2 = s1 + 1; isdigit(*s2); s2++) ;
    have_frac = s2 > s1 + 1;
    s1 = s2;
  }
  if( !have_whole && !have_frac) return(s);

/* Handle the exponent if there is one. Make sure its a well formed exponent. */

  if( *s1 == 'e'){
    s1++;
    if(*s1 == '+' || *s1 == '-') s1++;
    s2 = s1;
    while(isdigit(*s1)) s1++;
    if(s1 == s2) return(s);
  }

/* All looks well. Return with the pointer to it. */

  return(s1);
}
/************************************************************************/
private char *skip_logical(s)
char *s;
/*
  This skips over a logical or relational operator. These operators are
  FORTRAN-like, and this checks that they start and end with periods,
  and contain only alphabetic characters in between. There must be at
  least two alphabetic characters.

  Inputs:
    s		The input string.
  Output:
    skip_logical This points to the character beyond the logical or relational
		operator. If the string is not a logical or relational
		operator, this returns the input.
------------------------------------------------------------------------*/
{
  char *s1;
  if( *s != '.') return(s);
  for( s1 = s + 1; isalpha(*s1); s1++) ;
  if( *s1++ != '.') return(s);
  if( s1 - s < 4 ) return(s);
  return(s1);
}
