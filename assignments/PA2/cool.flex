/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

int comment_depth = 0;

int str_len;

void setErr(char* msg) {
  cool_yylval.error_msg = msg;
}

bool isTooLong() {
  if (str_len + 1 >= MAX_STR_CONST) return true;
  else return false;
}

int strLenErr() {
  string_buf[0] = '\0';
  setErr("String constant too long");
  return ERROR;
}

%}

%x COMMENT
%x LINECOMMENT
%x STRING
%x STRING_ERR

/*
 * Define names for regular expressions here.
 */


/* integers, identifiers, and special notation */
DIGIT           [0-9]
INTEGER         {DIGIT}+
IDENTIFIER      [A-Za-z0-9_]
UPPERCHAR       [A-Z]
LOWERCHAR       [a-z]
TYPEID          {UPPERCHAR}{IDENTIFIER}*
OBJECTID        {LOWERCHAR}{IDENTIFIER}*

/* strings */
NEWLINE         \n
WHITESPACE       [ \f\r\t\v]
DOUBLEQUOTE     \"

/* keywords */
CLASS           (?i:class)
ELSE            (?i:else)
FI              (?i:fi)
IF              (?i:if)
INHERITS        (?i:inherits)
IN              (?i:in)
ISVOID          (?i:isvoid)
LET             (?i:let)
LOOP            (?i:loop)
POOL            (?i:pool)
THEN            (?i:then)
WHILE           (?i:while)
CASE            (?i:case)
ESAC            (?i:esac)
NEW             (?i:new)
OF              (?i:of)
NOT             (?i:not)

TRUE            t(?i:rue)
FALSE           f(?i:alse)

/* others */
DARROW            =>
LE                <=
ASSIGN            <-

START_COMMENT     "(*"
END_COMMENT       "*)"
ONE_LINE_COMMENT  "--"

SINGLE_RETURN [\{\}\(\)\;\:\.\,\=\+\-\<\~\*\/\@]

%%

{START_COMMENT}    { comment_depth++; BEGIN(COMMENT); }

<COMMENT>{START_COMMENT} { comment_depth++; }

<COMMENT>{NEWLINE} { curr_lineno++; }

<COMMENT>{END_COMMENT} { comment_depth--; if ( comment_depth == 0 ) { BEGIN(INITIAL); } }

<COMMENT><<EOF>> { setErr("EOF in comment"); 
                   BEGIN(INITIAL);
                   return ERROR; }

<COMMENT>. { }

{END_COMMENT} { setErr("Unmatched *)");
                BEGIN(INITIAL);
                return ERROR; }

{ONE_LINE_COMMENT} { BEGIN(LINECOMMENT); }

<LINECOMMENT>{NEWLINE} { curr_lineno++;
                         BEGIN(INITIAL); }

<LINECOMMENT>.  { }

{INTEGER}       { cool_yylval.symbol = inttable.add_string(yytext);
                  return INT_CONST; }

{DARROW}		{ return (DARROW); }
{LE}            { return (LE); }
{ASSIGN}        { return (ASSIGN); }

{SINGLE_RETURN} { return (yytext[0]); }

{CLASS}         { return (CLASS); }
{ELSE}          { return (ELSE); }
{FI}            { return (FI); }
{IF}            { return (IF); }
{IN}            { return (IN); }
{INHERITS}      { return (INHERITS); }
{LET}           { return (LET); }
{LOOP}          { return (LOOP); }
{POOL}          { return (POOL); }
{THEN}          { return (THEN); }
{WHILE}         { return (WHILE); }
{CASE}          { return (CASE); }
{ESAC}          { return (ESAC); }
{OF}            { return (OF); }
{NEW}           { return (NEW); }
{NOT}           { return (NOT); }
{ISVOID}        { return (ISVOID); }
{TRUE}          { cool_yylval.boolean = true;
                  return (BOOL_CONST); }
{FALSE}         { cool_yylval.boolean = false;
                  return (BOOL_CONST); }

{TYPEID}        { cool_yylval.symbol = stringtable.add_string(yytext);
                  return (TYPEID); }
{OBJECTID}      { cool_yylval.symbol = stringtable.add_string(yytext);
                  return (OBJECTID); }

{DOUBLEQUOTE} { BEGIN(STRING); str_len = 0; }

<STRING>{DOUBLEQUOTE} { cool_yylval.symbol = stringtable.add_string(string_buf);
                        string_buf[0] = '\0';
                        BEGIN(INITIAL);
                        return (STR_CONST); }

<STRING>\0 { setErr("String contains null character");
             string_buf[0] = '\0';
             BEGIN(STRING_ERR);
             return ERROR; }

<STRING>\\\0 { setErr("String contains escaped null character");
               string_buf[0] = '\0';
               BEGIN(STRING_ERR);
               return ERROR; }

<STRING>{NEWLINE} { setErr("Unterminated string constant");
                    string_buf[0] = '\0';
                    curr_lineno++;
                    BEGIN(INITIAL);
                    return ERROR; }

<STRING>\\n { if(isTooLong()) { BEGIN(STRING_ERR); return strLenErr(); }
              str_len++;
              strcat(string_buf, "\n"); }

<STRING>\\{NEWLINE} { if(isTooLong()) { BEGIN(STRING_ERR); return strLenErr(); }
                      str_len++;
                      curr_lineno++;
                      strcat(string_buf, "\n"); }

<STRING>\\t { if(isTooLong()) { BEGIN(STRING_ERR); return strLenErr(); }
              str_len++;
              strcat(string_buf, "\t"); }

<STRING>\\v { if(isTooLong()) { BEGIN(STRING_ERR); return strLenErr(); }
              str_len++;
              strcat(string_buf, "\v"); }

<STRING>\\b { if(isTooLong()) { BEGIN(STRING_ERR); return strLenErr(); }
              str_len++;
              strcat(string_buf, "\b"); }

<STRING>\\f { if(isTooLong()) { BEGIN(STRING_ERR); return strLenErr(); }
              str_len++;
              strcat(string_buf, "\f"); }

<STRING>\\. { if(isTooLong()) { BEGIN(STRING_ERR); return strLenErr(); }
              str_len++;
              strcat(string_buf, &strdup(yytext)[1]); }

<STRING><<EOF>> { setErr("EOF in string constant");
                  curr_lineno++;
                  BEGIN(INITIAL);
                  return ERROR; }

<STRING>. { if(isTooLong()) { BEGIN(STRING_ERR); return strLenErr(); }
            str_len++;
            strcat(string_buf, yytext); }

<STRING_ERR>{DOUBLEQUOTE} { BEGIN(INITIAL); }

<STRING_ERR>\\\n { curr_lineno++;
                   BEGIN(INITIAL); }

<STRING_ERR>\n { curr_lineno++;
                 BEGIN(INITIAL); }

<STRING_ERR>. { }

{NEWLINE} { curr_lineno++; }
{WHITESPACE} { }

. { setErr(yytext);
    return ERROR; }

%%
