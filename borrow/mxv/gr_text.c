/*
 *	File:		gr_text.c
 *	Contents:	Text manipulation routines
 */

#include "gr_com.h"

long	gr_textBuffLength;


/*
 *	Initialize text buffer
 */
void
gr_TextInitBuff(len)
long len;
{
	gr_textBuffLength = len;
}


/*
 *	Write message out to text file
 */
void
gr_TextMsgOut(strng)
char *strng;
{
	gr_TextReplace(gr_topWin.msgWin,gr_textBuffLength,gr_textBuffLength,strng);
	gr_textBuffLength += (long)strlen(strng);
	gr_TextSetInsertionPoint(gr_topWin.msgWin,gr_textBuffLength);
}
