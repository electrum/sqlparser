grammar Query;

options {
	output=AST;
	ASTLabelType=CommonTree;
	backtrack=true;
	memoize=true;
}

@members {
protected void mismatch(IntStream input, int ttype, BitSet follow)
throws RecognitionException
{ throw new MismatchedTokenException(ttype, input); }
public void recoverFromMismatchedSet(
IntStream input, RecognitionException e, BitSet follow)
throws RecognitionException { throw e; }
}
@rulecatch {
catch (RecognitionException re) { reportError(re); throw re; }
}

prog	:	query* EOF ;

query	:	selectStmt ';'
	;

selectStmt
	:	SELECT selectExpr
		FROM tableList
		(WHERE searchCond)?
		(GROUP BY groupBy (HAVING searchCond)?)?
		(ORDER BY orderBy)?
	;

selectExpr
	:	(ALL | DISTINCT)? ('*' | columnList)
	;

columnList
	:	columnExpr (',' columnExpr)*
	;

columnExpr
	:	rowVal (AS? ident)?
	;

tableList
	:	tableExpr (',' tableExpr)*
	;

tableExpr
	:	(ident | subquery) (AS? ident)?
	;

searchCond
	:	booleanTerm (OR booleanTerm)*
	;

booleanTerm
	:	booleanFactor (AND booleanFactor)*
	;

booleanFactor
	:	NOT? booleanTest
	;

booleanTest
	:	booleanPrimary
	;

booleanPrimary
	:	predicate
	|	'(' searchCond ')'
	;

predicate
	:	compareCond
	|	rangeCond
	|	likeCond
	|	nullCond
	|	inCond
	|	existsCond
	;

compareCond
	:	rowVal cmpOp rowVal
	;

rangeCond
	:	rowVal NOT? BETWEEN rowVal AND rowVal
	;

likeCond:	rowVal NOT? LIKE rowVal (ESCAPE rowVal)?
	;

nullCond:	rowVal IS NOT? NULL
	;

inCond	:	rowVal NOT? IN inPredicate
	;

inPredicate
	:	'(' rowVal (',' rowVal)* ')'
	|	subquery
	;

existsCond
	:	EXISTS subquery
	;

groupBy	:	rowVal (',' rowVal)*
	;

orderBy	:	rowVal (ASC|DESC)? (',' rowVal (ASC|DESC)?)*
	;

cmpOp	:	('='|'<>'|'!='|'<'|'<='|'>'|'>=')
	;

subquery:	'(' selectStmt ')'
	;

rowVal	:	expr
	|	stringExpr
	|	subquery
	|	NULL
	;

dateValue
	:	DATE STRING
	|	TIME STRING
	|	TIMESTAMP STRING
	|	dateFunction
	;

intervalValue
	:	INTERVAL ('+'|'-')? STRING intervalQualifier
	;

intervalQualifier
	:	(YEAR|MONTH|DAY|HOUR|MINUTE) ('(' INTEGER ')')?
	|	SECOND ('(' INTEGER (',' INTEGER)?)?
	;

dateFunction
	:	CURRENT_DATE
	|	CURRENT_TIME ('(' INTEGER ')')?
	|	CURRENT_TIMESTAMP ('(' INTEGER ')')?
	;

stringExpr
	:	STRING
	|	ident
	|	charFunction
	;

charFunction
	:	SUBSTRING '(' stringExpr FROM expr (FOR expr)? ')'
	;

extractExpr
	:	EXTRACT '(' extractField FROM expr ')'
	;

extractField
	:	YEAR | MONTH | DAY | HOUR | MINUTE | SECOND
	|	TIMEZONE_HOUR | TIMEZONE_MINUTE
	;

expr	:	term (('+'|'-') term)*
	;

term	:	factor (('*'|'/'|'%') factor)*
	;

factor	:	('+'|'-')? exprItem
	;

exprItem:	ident
	|	function
	| 	number
	|	dateValue
	|	intervalValue
	|	extractExpr
	|	caseExpr
	|	'(' expr ')'
	;

caseExpr:	caseAbbrev
	|	CASE rowVal (WHEN rowVal THEN rowVal)+ (ELSE rowVal)? END
	|	CASE (WHEN searchCond THEN rowVal)+ (ELSE rowVal)? END
	;

caseAbbrev
	:	NULLIF '(' rowVal ',' rowVal ')'
	|	COALESCE '(' rowVal (',' rowVal)* ')'
	;

function
	:	ident '(' ('*' | ((DISTINCT | ALL)? rowVal)) ')'
	;

number	:	NUMBER | INTEGER ;

ident	:	IDENT ('.' IDENT)? ;

SELECT	:	('S'|'s')('E'|'e')('L'|'l')('E'|'e')('C'|'c')('T'|'t') ;
FROM 	: 	('F'|'f')('R'|'r')('O'|'o')('M'|'m') ;
AS	:	('A'|'a')('S'|'s') ;
ALL 	: 	('A'|'a')('L'|'l')('L'|'l') ;
DISTINCT: 	('D'|'d')('I'|'i')('S'|'s')('T'|'t')('I'|'i')('N'|'n')('C'|'c')('T'|'t') ;
WHERE 	: 	('W'|'w')('H'|'h')('E'|'e')('R'|'r')('E'|'e') ;
GROUP 	: 	('G'|'g')('R'|'r')('O'|'o')('U'|'u')('P'|'p') ;
BY 	: 	('B'|'b')('Y'|'y') ;
ORDER 	: 	('O'|'o')('R'|'r')('D'|'d')('E'|'e')('R'|'r') ;
HAVING 	: 	('H'|'h')('A'|'a')('V'|'v')('I'|'i')('N'|'n')('G'|'g') ;
OR 	: 	('O'|'o')('R'|'r') ;
AND 	: 	('A'|'a')('N'|'n')('D'|'d') ;
IN	:	('I'|'i')('N'|'n') ;
NOT	:	('N'|'n')('O'|'o')('T'|'t') ;
EXISTS	:	('E'|'e')('X'|'x')('I'|'i')('S'|'s')('T'|'t')('S'|'s') ;
BETWEEN	:	('B'|'b')('E'|'e')('T'|'t')('W'|'w')('E'|'e')('E'|'e')('N'|'n') ;
LIKE 	: 	('L'|'l')('I'|'i')('K'|'k')('E'|'e') ;
IS 	: 	('I'|'i')('S'|'s') ;
NULL 	: 	('N'|'n')('U'|'u')('L'|'l')('L'|'l') ;
ESCAPE	:	('E'|'e')('S'|'s')('C'|'c')('A'|'a')('P'|'p')('E'|'e') ;
ASC	:	('A'|'a')('S'|'s')('C'|'c') ;
DESC	:	('D'|'d')('E'|'e')('S'|'s')('C'|'c') ;
SUBSTRING:	('S'|'s')('U'|'u')('B'|'b')('S'|'s')('T'|'t')('R'|'r')('I'|'i')('N'|'n')('G'|'g') ;
FOR	: 	('F'|'f')('O'|'o')('R'|'r') ;
DATE	:	('D'|'d')('A'|'a')('T'|'t')('E'|'e') ;
TIME	:	('T'|'t')('I'|'i')('M'|'m')('E'|'e') ;
TIMESTAMP:	('T'|'t')('I'|'i')('M'|'m')('E'|'e')('S'|'s')('T'|'t')('A'|'a')('M'|'m')('P'|'p') ;
INTERVAL:	('I'|'i')('N'|'n')('T'|'t')('E'|'e')('R'|'r')('V'|'v')('A'|'a')('L'|'l') ;
YEAR	:	('Y'|'y')('E'|'e')('A'|'a')('R'|'r') ;
MONTH	:	('M'|'m')('O'|'o')('N'|'n')('T'|'t')('H'|'h') ;
DAY	:	('D'|'d')('A'|'a')('Y'|'y') ;
HOUR	:	('H'|'h')('O'|'o')('U'|'u')('R'|'r') ;
MINUTE	:	('M'|'m')('I'|'i')('N'|'n')('U'|'u')('T'|'t')('E'|'e') ;
SECOND	:	('S'|'s')('E'|'e')('C'|'c')('O'|'o')('N'|'n')('D'|'d') ;
CURRENT_DATE:	('C'|'c')('U'|'u')('R'|'r')('R'|'r')('E'|'e')('N'|'n')('T'|'t')('_')('D'|'d')('A'|'a')('T'|'t')('E'|'e') ;
CURRENT_TIME:	('C'|'c')('U'|'u')('R'|'r')('R'|'r')('E'|'e')('N'|'n')('T'|'t')('_')('T'|'t')('I'|'i')('M'|'m')('E'|'e') ;
CURRENT_TIMESTAMP: ('C'|'c')('U'|'u')('R'|'r')('R'|'r')('E'|'e')('N'|'n')('T'|'t')('_')('T'|'t')('I'|'i')('M'|'m')('E'|'e')('S'|'s')('T'|'t')('A'|'a')('M'|'m')('P'|'p') ;
EXTRACT	:	('E'|'e')('X'|'x')('T'|'t')('R'|'r')('A'|'a')('C'|'c')('T'|'t') ;
TIMEZONE_HOUR :	('T'|'t')('I'|'i')('M'|'m')('E'|'e')('Z'|'z')('O'|'o')('N'|'n')('E'|'e')('_')('H'|'h')('O'|'o')('U'|'u')('R'|'r') ;
TIMEZONE_MINUTE : ('T'|'t')('I'|'i')('M'|'m')('E'|'e')('Z'|'z')('O'|'o')('N'|'n')('E'|'e')('_')('M'|'m')('I'|'i')('N'|'n')('U'|'u')('T'|'t')('E'|'e') ;
COALESCE:	('C'|'c')('O'|'o')('A'|'a')('L'|'l')('E'|'e')('S'|'s')('C'|'c')('E'|'e') ;
NULLIF	:	('N'|'n')('U'|'u')('L'|'l')('L'|'l')('I'|'i')('F'|'f') ;
CASE	:	('C'|'c')('A'|'a')('S'|'s')('E'|'e') ;
WHEN	:	('W'|'w')('H'|'h')('E'|'e')('N'|'n') ;
THEN	:	('T'|'t')('H'|'h')('E'|'e')('N'|'n') ;
ELSE	:	('E'|'e')('L'|'l')('S'|'s')('E'|'e') ;
END	:	('E'|'e')('N'|'n')('D'|'d') ;

STRING	:	'\'' ( ~'\'' | '\'' '\'' )* '\'' ;

SQUOTE	:	'\'' ;

INTEGER	:	('0'..'9')+ ;
NUMBER	:	('0'..'9')+ ('.' ('0'..'9')+)? ;

IDENT	:	('_'|'A'..'Z'|'a'..'z') ('_'|'A'..'Z'|'a'..'z'|'0'..'9')* ;

SL_COMMENT:	'--' (~('\r' | '\n'))* ('\r'? '\n')? {channel=HIDDEN;} ;

ML_COMMENT:	'/*' (options {greedy=false;} : .)* '*/' {channel=HIDDEN;} ;

WS	:	(' '|'\t'|'\n'|'\r')+ {channel=HIDDEN;} ;
