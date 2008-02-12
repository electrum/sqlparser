grammar Query;

options {
	output=AST;
	ASTLabelType=CommonTree;
}

prog	:	query* ;

query	:	selectStmt ';'
	;

selectStmt
	:	SELECT selectExpr
		FROM tableList
		(WHERE whereClause)?
		(GROUP BY groupBy (HAVING havingClause)?)?
		(ORDER BY orderBy)?
	;

selectExpr
	:	(ALL | DISTINCT)? ('*' | columnList)
	;

columnList
	:	columnExpr (',' columnExpr)*
	;

columnExpr
	:	expr (AS? ident)?
	;

tableList
	:	tableExpr (',' tableExpr)*
	;

tableExpr
	:	ident (AS? ident)?
	;

whereClause
	:	whereExpr ((AND | OR) whereExpr)?
	;

whereExpr
	:	expr cmpOp expr
	|	expr BETWEEN expr AND expr
	|	expr NOT BETWEEN expr AND expr
	|	NOT whereExpr
	;

groupBy	:	expr (',' expr)*
	;

havingClause
	:	whereClause
	;

orderBy	:	expr (',' expr)*
	;

cmpOp	:	('='|'<>'|'!='|'<'|'<='|'>'|'>=')
	;

expr	:	ident | NUMBER;

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

NUMBER	:	('0'..'9')+ ;

IDENT	:	('_'|'A'..'Z'|'a'..'z') ('_'|'A'..'Z'|'a'..'z'|'0'..'9')* ;

SL_COMMENT:	'--' (~('\r' | '\n'))* ('\r'? '\n')? {channel=HIDDEN;} ;

ML_COMMENT:	'/*' (options {greedy=false;} : .)* '*/' {channel=HIDDEN;} ;

WS	:	(' '|'\t'|'\n'|'\r')+ {channel=HIDDEN;} ;
