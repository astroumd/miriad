/*----------------------------------------------------------------------------
-- mosaic_key.c --
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/* <<< KEYWORD ROUTINES >>>                            403 +   35 =  438 USERIO
/******************************************************************************/
/*
   The following routines are included in this file, but are actually
   rewritten-in-C replacements for routines from the miriad library.

     keyini_c, keyfin_c, dexpand
      keys_c, keyd_c, keya_c, keyf_c, keyr_c, keyi_c, keyl_c
     mkeyd_c, mkeyr_c, mkeyi_c

   The following routines must be available elsewhere
     index_c, AtoF, DBGVAL

   For some cases: change Abort() to exit(1)
                   change #define DBGVAL(s,m)
*/
/******************************************************************************/

#if defined(sun) || defined(mips)
#define private static
#else
#define private
#endif

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#if defined(convex) || defined(cm5) || defined(mips)
#include <stdlib.h>
#else
#include <malloc.h>
#endif

#define StrCpy(a,b)   (void)strcpy((a),(b))
#define StrEq(a,b)    (!memcmp((a),(b),strlen((b))))
#define Fprintf       (void)fprintf
#define Sprintf       (void)sprintf
#define logical int
#define FALSE 0
#define TRUE  1
#define MAXKEYS 32
#define MAXPATH 128
#define OUTSTRLEN 128
/*#define DBGVAL(s,m)*/ void DBGVAL();
void Abort();

private char KeyErrorMessage[80];
private void KeyAssert(  condition, message ) logical condition; char *message;
{ if( !condition ) { Fprintf(stderr,message); Fprintf(stderr,"\n"); Abort(); } }
private void KeyWarning( condition, message )  logical condition; char *message;
{ if(  condition ) { Fprintf(stderr,message); Fprintf(stderr,"\n");          } }

#define KeyAlloc(s,NB) \
        KeyAssert( ( (s) = (char *)malloc((unsigned)(NB)) ) !=  NULL, \
                   "Failed allocation of space for keyword" )

private struct { char *Key; char *Value; logical WildExp; } KeyWords[MAXKEYS];
private int nkeys=0;

void keyini_c(version,argc,argv)
char *version;
int   argc;
char *argv[];
{
   private void    hiskeylist_c();
   private int     flen();
   private logical readkey();
   private void    keyput();
   char   *key;
   FILE   *fd;
   int i;

   hiskeylist_c( version );

   for( i=1; i<argc; i++ ) {
     if( StrEq( argv[i], "-f" ) ) {
         i++; KeyAssert( i<argc, "No parameter file given for -f option" );
         Sprintf(KeyErrorMessage,"Failed to open parameter file %s",argv[i]);
         KeyAssert( (fd=fopen(argv[i],"r")) != NULL, KeyErrorMessage );
         KeyAlloc( key, flen(fd) );
         while( readkey( fd, key ) ) keyput( key, nkeys );
         (void)fclose( fd );
      } else {
         keyput( argv[i], nkeys );
      }
   }
}

private int flen(fd) FILE *fd;
{
  register int n=1; while( getc(fd) != EOF ) n++;
  KeyAssert( fseek(fd,(long)0,0)==0, "Error repositioning file" );
  return n;
}

#ifdef mips
#undef EOF
#define EOF 255
#endif

private logical readkey( fd, key )
FILE *fd;
char *key;
{
   register char c;
   int      stage=1;
   while( (c=getc(fd)) != EOF ) {
      switch( stage ) {
      /* search for keyword */
      case 1: if(      c=='#'      ) {            stage=10; }
              else if( !isspace(c) ) { *key++=c;  stage=2;  } break;
      /* copy keyword */
      case 2: if(      c=='\n'     ) { goto done;           }
              else if( isspace(c)  ) {            stage=3;  }
              else if( c=='='      ) { *key++=c;  stage=4;  }
              else                   { *key++=c;            } break;
      /* search for '=' */
      case 3: if(      c=='\n'     ) { goto done;           }
              else if( c=='='      ) { *key++=c;  stage=4;  }
              else if( !isspace(c) ) { goto done;           } break;
      /* search for value */
      case 4: if(      c=='\n'     ) { goto done;           }
              else if( !isspace(c) ) { *key++=c;  stage=5;  } break;
      /* copy value */
      case 5: if(      c=='\\'     ) { c=getc(fd);          }
              else if( isspace(c)  ) { goto done;           }
              else                   { *key++=c;            } break;
      /* comment line */
      case 10: if( c=='\n' ) stage=1; break;
      }
   }
   done:
   *key='\0';
   return( c!=EOF );
}

void keywrite( keyword, string )
char *keyword, *string;
{  private void keyput();
   char *key;
   KeyAlloc( key, strlen(keyword)+1+strlen(string)+1 );
   Sprintf(  key, "%s=%s", keyword, string );
   keyput(   key, nkeys );
}

private void keyput( key, i )
char *key;
int   i;
{
   private void hiskeylist_c();
   int          index_c();
   private void Read_AtFile();
   register int lkey, lval;
   char         c;

   lkey = index_c( '=', key );
   lval = strlen(key) -lkey-1;
   c=key[45]; key[45]='\0';
   Sprintf( KeyErrorMessage, "No '=' in keyword %s, ignored", key );
   KeyWarning( lkey == -1, KeyErrorMessage );
   Sprintf( KeyErrorMessage, "Missing keyword in %s, ignored", key );
   KeyWarning( lkey ==  0, KeyErrorMessage );
   if( lkey == -1 ) return;
   Sprintf( KeyErrorMessage, "Zero length value in argument of %s", key );
   KeyWarning( lval ==  0, KeyErrorMessage );
   key[45]=c;

   hiskeylist_c( key );

   KeyAlloc( KeyWords[i].Key, lkey+1 );
   *(key+lkey) = '\0';
   StrCpy( KeyWords[i].Key, key );

   KeyAlloc( KeyWords[i].Value, lval+1 );
   key += lkey+1;
   if( *key == '@' ) Read_AtFile( &KeyWords[i].Value, key );
   else              StrCpy(       KeyWords[i].Value, key );

   KeyWords[i].WildExp = FALSE;

   nkeys++;
}

private void Read_AtFile( key, name )
char **key;
char  *name;
{
   private int flen();
   FILE *fd;
   char *c;
   name++;
   Sprintf( KeyErrorMessage, "Failed to open @ file %s",name );
   KeyAssert( (fd=fopen(name,"r")) != NULL, KeyErrorMessage );
   KeyAlloc( *key, flen(fd) ); c= *key;
   while( (**key=getc(fd)) != EOF ) { if(**key=='\n') **key=' '; *key+=1; }
   **key = '\0'; *key = c;
   (void)fclose( fd );
}

void keyfin_c()
{
   register int i;
   for( i=0; i<nkeys; i++ ) {
      if( KeyWords[i].Value != NULL  ) {
      Sprintf( KeyErrorMessage, "Keyword %s not used or not exhausted",
               KeyWords[i].Key );
      KeyWarning( TRUE, KeyErrorMessage );
      }
   }
}

logical keyprsnt_c( KeyWord )
char *KeyWord;
{
   private  int FindKey();
   register int k;
   k = FindKey(KeyWord);
   if( k == -1 ) return FALSE;
   return( KeyWords[k].Value != NULL );
}

private char *keyget( KeyWord, Wild_Expand )
char   *KeyWord;
logical Wild_Expand;
{
   private int   FindKey();
   private char *NextSeparator();
   private void  Expand_WildCards();
           char *c;
   register int   k;
   private  char *KeyVal;

   DBGVAL( ".. Search for keyword %10s --", KeyWord );
   k = FindKey(KeyWord);
   if( k == -1 || KeyWords[k].Value == NULL ){DBGVAL("%s","\n");return NULL;}

   if(Wild_Expand) Expand_WildCards( &KeyWords[k].Value, &KeyWords[k].WildExp );

   KeyVal = KeyWords[k].Value;
   c = NextSeparator( KeyVal );
   if( *c != '\0' ) { *c = '\0'; KeyWords[k].Value = c+1;  }
   else             {            KeyWords[k].Value = NULL; }

   DBGVAL( "Decode value %s\n", KeyVal );
   if( *KeyVal == '\0' ) return NULL;
   return KeyVal;
}
private int FindKey( KeyWord )
char *KeyWord;
{
   register int k;
   for( k=0; k<nkeys; k++ ) {
      if( StrEq( KeyWords[k].Key, KeyWord ) &&
          strlen(KeyWords[k].Key) == strlen(KeyWord) ) return k;
   }
   return( -1 );
}
private void Expand_WildCards( Value, Wild_Expanded )
char    **Value;
logical  *Wild_Expanded;
{
   private  logical dexpand();
   register int     alloc=0;
   private  char   *List;
   if( *Wild_Expanded ) return;

   /* %->* to satisfy xdbx */
   for( List= *Value; *List; List++ ) { if(*List=='%') *List='*'; }

   do { alloc+=256; KeyAlloc( List, alloc );
   } while( !dexpand( *Value, List, alloc )  );

   *Value         = List;
   *Wild_Expanded = TRUE;
}
private logical dexpand( template, output, length )
char *template;
char *output;
int   length;
#define MAXPATH 128
{
  FILE    *fd;
  char     line[MAXPATH];
  register char *s = output;
  register int  l;
  Sprintf( line, "echo %s", template );
  if(  (fd = popen(line,"r") ) == NULL  ) return( FALSE );
  while( fgets(s,length,fd) ) {
    l = strlen(s);
    if( length-l <= 1 ) { (void)pclose(fd); return( FALSE ); }
    *(s+l-1) = ','; s += l; length -= l;
  }
  if( s != output ) *--s = '\0';
  (void)pclose(fd);
  return( TRUE );
}
private char *NextSeparator( string )
char *string;
{
   register int     depth=0;
   register logical sQuoted=FALSE;
   register logical dQuoted=FALSE;
   private char    *c; c=string;
   while( *c ) {
      if( *c == '('  ) depth++;
      if( *c == ')'  ) depth--;
      if( *c == '\'' ) sQuoted = !sQuoted;
      if( *c == '"'  ) dQuoted = !dQuoted;
      if( depth==0 && !sQuoted && !dQuoted && ( *c==','||isspace(*c) ) ) break;
      c++;
   }
   return c;
}

void keys_c( KeyWord, Value, Default, wild )
char   *KeyWord, *Value, *Default;
logical wild;
{
   private char *keyget();
           char *KeyVal;
   KeyVal = keyget(KeyWord,wild);
   if( KeyVal != NULL ) { StrCpy( Value, KeyVal  ); }
   else                 { StrCpy( Value, Default ); }
}
void keyd_c( KeyWord, Value, Default )
char   *KeyWord;
double *Value, Default;
{
   private char *keyget();
           char *KeyVal;
   double AtoF();
   KeyVal = keyget(KeyWord,FALSE);
   if( KeyVal != NULL ) { *Value = AtoF(KeyVal); }
   else                 { *Value = Default;      }
}
void keya_c( KeyWord, Value,  Default )
char *KeyWord; char  *Value, *Default;
{ void keys_c();
  keys_c( KeyWord, Value, Default, FALSE );
}
void keyf_c( KeyWord, Value,  Default )
char *KeyWord; char  *Value, *Default;
{ void keys_c();
  keys_c( KeyWord, Value, Default, TRUE  );
}
void keyr_c( KeyWord, Value,  Default )
char *KeyWord; float *Value,  Default;
{  void keyd_c(); double dValue;
   keyd_c( KeyWord, &dValue, (double)Default ); *Value = (float)dValue;
}
void keyi_c( KeyWord, Value,  Default )
char *KeyWord; int   *Value,  Default;
{  void keyd_c(); double dValue;
   keyd_c( KeyWord, &dValue, (double)Default ); *Value = (int)dValue;
}

void keyl_c( KeyWord, Value, Default )
char    *KeyWord;
logical *Value, Default;
{
   void keya_c();
   int  index_c();
   char val[10];
   if(  Default ) keya_c( KeyWord, val, ".TRUE."  );
   if( !Default ) keya_c( KeyWord, val, ".FALSE." );
   if(        index_c( val[0],"tTyY1" ) != -1  || StrEq(val,".TRUE." ) ) {
       *Value = TRUE;
   } else if( index_c( val[0],"fFnN0" ) != -1  || StrEq(val,".FALSE.") ) {
       *Value = FALSE;
   } else {
      Sprintf(KeyErrorMessage,"keyl: invalid Value for a logical: %s",KeyWord);
      KeyWarning( TRUE, KeyErrorMessage );
   }
}

void mkey_c( flag, KeyWord, DValues, RValues, IValues, MaxNum, nValues )
char   flag;
char  *KeyWord;
double DValues[];
float  RValues[];
int    IValues[];
int    MaxNum;
int   *nValues;
{
   logical keyprsnt_c();
   void    keyd_c(), keyr_c(), keyi_c();

   *nValues = 0;
   while( *nValues<MaxNum && keyprsnt_c(KeyWord) ) {
      if(flag=='d') keyd_c( KeyWord, &DValues[*nValues], 0.0 );
      if(flag=='r') keyr_c( KeyWord, &RValues[*nValues], 0.0 );
      if(flag=='i') keyi_c( KeyWord, &IValues[*nValues],  0  );
      nValues++;
   }
   Sprintf( KeyErrorMessage, "mkey: buffer overflow for %s", KeyWord );
   KeyAssert( !keyprsnt_c(KeyWord), KeyErrorMessage );
}
void mkeyd_c( KeyWord, Values, MaxNum, nValues )
char *KeyWord; double Values[]; int MaxNum, *nValues;
{ void mkey_c();
  mkey_c( 'd', KeyWord, Values,(float *)NULL,(int *)NULL, MaxNum, nValues ); }
void mkeyr_c( KeyWord, Values, MaxNum, nValues )
char *KeyWord; float Values[];  int MaxNum, *nValues;
{ void mkey_c();
  mkey_c( 'r', KeyWord, (double *)NULL,Values,(int *)NULL, MaxNum, nValues ); }
void mkeyi_c( KeyWord, Values, MaxNum, nValues )
char *KeyWord; int Values[];    int MaxNum, *nValues;
{ void mkey_c();
  mkey_c( 'i', KeyWord, (double *)NULL,(float *)NULL,Values,MaxNum, nValues ); }

/*

/******************************************************************************/
/*
  Copy the keywords (input parameters) to the history file.
  First in the list is the program version.
*/
/******************************************************************************/

private char *hist_keylist[MAXKEYS];
private int   hist_keynum=0;

private void hiskeylist_c( key )
char *key;
{
   int lkey;
   lkey = strlen(key);
   KeyAlloc( hist_keylist[hist_keynum], lkey+1 );
   StrCpy(   hist_keylist[hist_keynum], key    );
   hist_keynum++;
}

void hisinput_c( tinp, program )
int   tinp;
char *program;
{
   void  date();
   void  hiswrite_c();
   int   lp, i;
   char  line[OUTSTRLEN];
   char *version = hist_keylist[0];
   char  datestring[30];

   lp = strlen(program)+2;
   date( datestring );
   Sprintf( line,    "%s: version %s", program,version ); hiswrite_c(tinp,line);
   Sprintf( line+lp, "Executed on: %s", datestring );     hiswrite_c(tinp,line);
   Sprintf( line+lp, "Command line inputs follow:" );     hiswrite_c(tinp,line);
   *(line+lp) = *(line+lp+1)=' ';
   if( hist_keynum > 1 ) { for( i=1; i<hist_keynum; i++ ) {
   Sprintf( line+lp+2, "%s", hist_keylist[i] );           hiswrite_c(tinp,line);
   }}
}
