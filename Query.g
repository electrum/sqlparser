grammar Query;

options {
	output=AST;
	ASTLabelType=CommonTree;
	backtrack=true;
	memoize=true;
}

prog	:	query* ;

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
	:	ident (AS? ident)?
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

inCond	:	rowVal NOT? IN '(' rowVal (',' rowVal)* ')'
	;

groupBy	:	rowVal (',' rowVal)*
	;

orderBy	:	rowVal (',' rowVal)*
	;

cmpOp	:	('='|'<>'|'!='|'<'|'<='|'>'|'>=')
	;

rowVal	:	expr
	|	NULL
	;

expr	:	term (('+'|'-') term)*
	;

term	:	factor (('*'|'/'|'%') factor)*
	;

factor	:	('+'|'-')? exprItem
	;

exprItem:	ident
	| 	NUMBER
	|	STRING
	|	'(' expr ')'
	;

ident	:	IDENT ;

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

STRING	:	'\'' ( ~'\'' | '\'' '\'' )* '\'' ;

SQUOTE	:	'\'' ;

NUMBER	:	('0'..'9')+ ;

IDENT	:	('_'|'A'..'Z'|'a'..'z') ('_'|'A'..'Z'|'a'..'z'|'0'..'9')* ;

SL_COMMENT:	'--' (~('\r' | '\n'))* ('\r'? '\n')? {channel=HIDDEN;} ;

ML_COMMENT:	'/*' (options {greedy=false;} : .)* '*/' {channel=HIDDEN;} ;

WS	:	(' '|'\t'|'\n'|'\r')+ {channel=HIDDEN;} ;
