grammar Query;

options {
	output=AST;
	ASTLabelType=CommonTree;
	backtrack=true;
	memoize=true;
}

tokens {
	QUERY;
	GROUPBY;
	ORDERBY;
	SORT_SPEC;
	SELECT_LIST;
	SELECT_ELEMENT;
	CORR_LIST;
	SUBQUERY;
	TABLE;
	JOINED_TABLE;
	CROSS_JOIN;
	INNER_JOIN;
	LEFT_JOIN;
	RIGHT_JOIN;
	FULL_JOIN;
	IN_LIST;
	SIMPLE_CASE;
	SEARCHED_CASE;
	FUNCTION_CALL;
	NEGATIVE;
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

prog	:	query* EOF -> query*
	;

query	:	queryType ';' -> ^(QUERY queryType)
	;

queryType
	:	selectStmt -> ^(SELECT selectStmt)
	;

selectStmt
	:	selectClause
		fromClause
		whereClause?
		(groupClause havingClause?)?
		orderClause?
	;

selectClause
	:	SELECT selectExpr -> ^(SELECT_LIST selectExpr)
	;

fromClause
	:	FROM tableList -> ^(FROM tableList)
	;

whereClause
	:	WHERE searchCond -> ^(WHERE searchCond)
	;

groupClause
	:	GROUP BY groupBy -> ^(GROUPBY groupBy)
	;

havingClause
	:	HAVING searchCond -> ^(HAVING searchCond)
	;

orderClause
	:	ORDER BY orderBy -> ^(ORDERBY orderBy)
	;

selectExpr
	:	setQuant? ('*' | columnList)
	;

setQuant:	DISTINCT | ALL
	;

columnList
	:	columnExpr (',' columnExpr)* -> columnExpr+
	;

columnExpr
	:	rowVal (AS? ident)? -> ^(SELECT_ELEMENT rowVal ident?)
	;

tableList
	:	tableRef (',' tableRef)* -> tableRef ^(CROSS_JOIN tableRef)*
	;

tableRef:	 tablePrimary tableJoin*
	;

tablePrimary
	:	ident corrSpec?   -> ^(TABLE ident corrSpec?)
	|	subquery corrSpec -> ^(SUBQUERY subquery corrSpec)
	|	subJoin corrSpec? -> ^(JOINED_TABLE subJoin corrSpec?)
	;

subJoin	:	'(' tablePrimary tableJoin+ ')' -> tablePrimary tableJoin+
	;

tableJoin
	:	CROSS JOIN tablePrimary             -> ^(CROSS_JOIN tablePrimary)
	|	joinType JOIN tablePrimary joinSpec -> ^(joinType tablePrimary joinSpec)
	|	NATURAL joinType JOIN tablePrimary  -> ^(joinType tablePrimary NATURAL)
	;

joinType:	INNER?       -> INNER_JOIN
	|	LEFT OUTER?  -> LEFT_JOIN
	|	RIGHT OUTER? -> RIGHT_JOIN
	|	FULL OUTER?  -> FULL_JOIN
	;

joinSpec:	ON searchCond                    -> ^(ON searchCond)
	|	USING '(' ident (',' ident)* ')' -> ^(USING ident+)
	;

corrSpec:	AS? ident corrList? -> ident corrList?
	;

corrList:	'(' ident (',' ident)* ')' -> ^(CORR_LIST ident+)
	;

searchCond
	:	booleanTerm (OR booleanTerm)+ -> ^(OR booleanTerm+)
	|	booleanTerm
	;

booleanTerm
	:	booleanFactor (AND booleanFactor)+ -> ^(AND booleanFactor+)
	|	booleanFactor
	;

booleanFactor
	:	NOT booleanTest -> ^(NOT booleanTest)
	|	booleanTest
	;

booleanTest
	:	booleanPrimary
	;

booleanPrimary
	:	predicate
	|	'(' searchCond ')' -> searchCond
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
	:	rowVal cmpOp rowVal -> ^(cmpOp rowVal rowVal)
	;

rangeCond
	:	rowVal     BETWEEN rowVal AND rowVal ->       ^(BETWEEN rowVal rowVal rowVal)
	|	rowVal NOT BETWEEN rowVal AND rowVal -> ^(NOT ^(BETWEEN rowVal rowVal rowVal))
	;

likeCond:	rowVal     LIKE rowVal (ESCAPE rowVal)? ->       ^(LIKE rowVal rowVal (ESCAPE rowVal)?)
	|	rowVal NOT LIKE rowVal (ESCAPE rowVal)? -> ^(NOT ^(LIKE rowVal rowVal (ESCAPE rowVal)?))
	;

nullCond:	rowVal IS     NULL ->       ^(IS rowVal NULL)
	|	rowVal IS NOT NULL -> ^(NOT ^(IS rowVal NULL))
	;

inCond	:	rowVal     IN inPredicate ->       ^(IN rowVal inPredicate)
	|	rowVal NOT IN inPredicate -> ^(NOT ^(IN rowVal inPredicate))
	;

inPredicate
	:	'(' rowVal (',' rowVal)* ')' -> ^(IN_LIST rowVal+)
	|	subquery
	;

existsCond
	:	EXISTS subquery -> ^(EXISTS subquery)
	;

groupBy	:	rowVal (',' rowVal)* -> rowVal+
	;

orderBy	:	sortSpec (',' sortSpec)* -> sortSpec+
	;

sortSpec:	rowVal orderSpec? -> ^(SORT_SPEC rowVal orderSpec?)
	;

orderSpec
	:	ASC | DESC
	;

cmpOp	:	EQ | NEQ | LT | LTE | GT | GTE
	;

subquery:	'(' selectStmt ')' -> ^(SELECT selectStmt)
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
	:	SUBSTRING '(' stringExpr FROM expr (FOR expr)? ')' -> ^(FUNCTION_CALL SUBSTRING stringExpr expr expr?)
	;

extractExpr
	:	EXTRACT '(' extractField FROM expr ')'
	;

extractField
	:	YEAR | MONTH | DAY | HOUR | MINUTE | SECOND
	|	TIMEZONE_HOUR | TIMEZONE_MINUTE
	;

expr	:	term (('+'|'-')^ term)*
	;

term	:	factor (('*'|'/'|'%')^ factor)*
	;

factor	:	'+'? exprItem -> exprItem
	|	'-' exprItem  -> ^(NEGATIVE exprItem)
	;

exprItem:	ident
	|	function
	| 	number
	|	dateValue
	|	intervalValue
	|	extractExpr
	|	caseExpr
	|	'(' expr ')' -> expr
	;

caseExpr:	caseAbbrev
	|	simpleCase
	|	searchedCase
	;

caseAbbrev
	:	NULLIF '(' rowVal ',' rowVal ')'      -> ^(NULLIF rowVal rowVal)
	|	COALESCE '(' rowVal (',' rowVal)* ')' -> ^(COALESCE rowVal+)
	;

simpleCase
	:	CASE rowVal simpleWhen+ elseClause? END -> ^(SIMPLE_CASE rowVal simpleWhen+ elseClause?)
	;

simpleWhen
	:	WHEN rowVal THEN rowVal -> ^(WHEN rowVal rowVal)
	;

searchedCase
	:	CASE searchedWhen+ elseClause? END -> ^(SEARCHED_CASE searchedWhen+ elseClause?)
	;

searchedWhen
	:	WHEN searchCond THEN rowVal -> ^(WHEN searchCond rowVal)
	;

elseClause
	:	ELSE rowVal -> ^(ELSE rowVal)
	;

function:	ident '(' '*' ')'                  -> ^(FUNCTION_CALL ident '*')
	|	ident '(' setQuant rowVal ')'      -> ^(FUNCTION_CALL ident setQuant rowVal)
	|	ident '(' rowVal (',' rowVal)* ')' -> ^(FUNCTION_CALL ident rowVal+)
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
JOIN	:	('J'|'j')('O'|'o')('I'|'i')('N'|'n') ;
CROSS	:	('C'|'c')('R'|'r')('O'|'o')('S'|'s')('S'|'s') ;
OUTER	:	('O'|'o')('U'|'u')('T'|'t')('E'|'e')('R'|'r') ;
INNER	:	('I'|'i')('N'|'n')('N'|'n')('E'|'e')('R'|'r') ;
LEFT	:	('L'|'l')('E'|'e')('F'|'f')('T'|'t') ;
RIGHT	:	('R'|'r')('I'|'i')('G'|'g')('H'|'h')('T'|'t') ;
FULL	:	('F'|'f')('U'|'u')('L'|'l')('L'|'l') ;
NATURAL	:	('N'|'n')('A'|'a')('T'|'t')('U'|'u')('R'|'r')('A'|'a')('L'|'l') ;
USING	:	('U'|'u')('S'|'s')('I'|'i')('N'|'n')('G'|'g') ;
ON	:	('O'|'o')('N'|'n') ;

EQ	:	'=' ;
NEQ	:	'<>' | '!=';
LT	:	'<' ;
LTE	:	'<=' ;
GT	:	'>' ;
GTE	:	'>=' ;

STRING	:	'\'' ( ~'\'' | '\'' '\'' )* '\'' ;

INTEGER	:	('0'..'9')+ ;
NUMBER	:	('0'..'9')+ ('.' ('0'..'9')+)? ;

IDENT	:	('_'|'A'..'Z'|'a'..'z') ('_'|'A'..'Z'|'a'..'z'|'0'..'9')* ;

SL_COMMENT:	'--' (~('\r' | '\n'))* ('\r'? '\n')? {channel=HIDDEN;} ;

ML_COMMENT:	'/*' (options {greedy=false;} : .)* '*/' {channel=HIDDEN;} ;

WS	:	(' '|'\t'|'\n'|'\r')+ {channel=HIDDEN;} ;
