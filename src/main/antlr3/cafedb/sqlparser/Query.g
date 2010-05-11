grammar Query;

options {
	output=AST;
	ASTLabelType=CommonTree;
	backtrack=true;
	memoize=true;
}

tokens {
	QUERY_LIST;
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
	QNAME;
	CREATE_TABLE;
	TABLE_ELEMENT_LIST;
	COLUMN_DEF;
	NOT_NULL;
}

@parser::header {
  package cafedb.sqlparser;
}

@lexer::header {
  package cafedb.sqlparser;
}

@parser::members {
  @Override
  protected Object recoverFromMismatchedToken(IntStream input, int ttype, BitSet follow) throws RecognitionException
  { throw new MismatchedTokenException(ttype, input); }

  @Override
  public Object recoverFromMismatchedSet(IntStream input, RecognitionException e, BitSet follow) throws RecognitionException
  { throw e;  }
}

@lexer::members {
  @Override
  public void reportError(RecognitionException re)
  { super.reportError(re); throw new RuntimeException(re); }
}

@rulecatch {
  catch (RecognitionException re) { reportError(re); throw re; }
}

queryList
	:	(query ';')* EOF -> ^(QUERY_LIST query*)
	;

query
	:	selectStmt 	-> ^(SELECT selectStmt)
	|	createTableStmt -> ^(CREATE_TABLE createTableStmt)
	;

selectStmt
	:	selectClause
		fromClause
		whereClause?
		(groupClause havingClause?)?
		orderClause?
		limitClause?
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

limitClause
	:	LIMIT integer -> ^(LIMIT integer)
	;

selectExpr
	:	setQuant? ('*' | columnList)
	;

setQuant:	DISTINCT
	|	ALL ->
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
	:	qname corrSpec?   -> ^(TABLE qname corrSpec?)
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
	:	DATE STRING      -> ^(DATE STRING)
	|	TIME STRING      -> ^(TIME STRING)
	|	TIMESTAMP STRING -> ^(TIMESTAMP STRING)
	|	dateFunction
	;

intervalValue
	:	INTERVAL intervalSign? STRING intervalQualifier -> ^(INTERVAL STRING intervalQualifier intervalSign?)
	;

intervalSign
	:	'+' ->
	|	'-' -> NEGATIVE
	;

intervalQualifier
	:	nonSecond ('(' p=integer ')')?               -> ^(nonSecond $p?)
	|	SECOND ('(' p=integer (',' s=integer)? ')')? -> ^(SECOND $p? $s?)
	;

nonSecond
	:	YEAR | MONTH | DAY | HOUR | MINUTE
	;

dateFunction
	:	CURRENT_DATE                         -> ^(FUNCTION_CALL CURRENT_DATE)
	|	CURRENT_TIME ('(' integer ')')?      -> ^(FUNCTION_CALL CURRENT_TIME integer?)
	|	CURRENT_TIMESTAMP ('(' integer ')')? -> ^(FUNCTION_CALL CURRENT_TIMESTAMP integer?)
	;

stringExpr
	:	STRING
	|	qname
	|	charFunction
	;

charFunction
	:	SUBSTRING '(' stringExpr FROM expr (FOR expr)? ')' -> ^(FUNCTION_CALL SUBSTRING stringExpr expr expr?)
	;

extractExpr
	:	EXTRACT '(' extractField FROM expr ')' -> ^(FUNCTION_CALL EXTRACT extractField expr)
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

exprItem:	qname
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

function:	qname '(' '*' ')'                  -> ^(FUNCTION_CALL qname ALL)
	|	qname '(' setQuant rowVal ')'      -> ^(FUNCTION_CALL qname setQuant rowVal)
	|	qname '(' rowVal (',' rowVal)* ')' -> ^(FUNCTION_CALL qname rowVal+)
	;

createTableStmt
	:	CREATE TABLE qname tableElementList -> qname tableElementList
	;

tableElementList
	:	'(' tableElement (',' tableElement)*  ')' -> ^(TABLE_ELEMENT_LIST tableElement+)
	;

tableElement
	:	columnDef
	;

columnDef
	:	ident dataType columnConstDef* -> ^(COLUMN_DEF ident dataType columnConstDef*)
	;

dataType:	charType
	|	exactNumType
	|	dateType
	;

charType:	CHAR charlen?              -> ^(CHAR charlen?)
	|	CHARACTER charlen?         -> ^(CHAR charlen?)
	|	VARCHAR charlen?           -> ^(VARCHAR charlen?)
	|	CHAR VARYING charlen?      -> ^(VARCHAR charlen?)
	|	CHARACTER VARYING charlen? -> ^(VARCHAR charlen?)
	;

charlen	:	'(' integer ')' -> integer
	;

exactNumType
	:	NUMERIC numlen? -> ^(NUMERIC numlen?)
	|	DECIMAL numlen? -> ^(NUMERIC numlen?)
	|	DEC numlen?     -> ^(NUMERIC numlen?)
	|	INTEGER         -> ^(INTEGER)
	|	INT             -> ^(INTEGER)
	;

numlen	:	'(' p=integer (',' s=integer)? ')' -> $p $s?
	;

dateType:	DATE -> ^(DATE)
	;

columnConstDef
	:	columnConst -> ^(CONSTRAINT columnConst)
	;

columnConst
	:	NOT NULL -> NOT_NULL
	;

qname	:	a=ident ('.' b=ident ('.' c=ident)?)? -> ^(QNAME $a $b? $c?)
	;

ident	:	IDENT ;

number	:	V_NUMBER | V_INTEGER ;

integer	:	V_INTEGER ;

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
LIMIT 	: 	('L'|'l')('I'|'i')('M'|'m')('I'|'i')('T'|'t') ;
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
CREATE 	:	('C'|'c')('R'|'r')('E'|'e')('A'|'a')('T'|'t')('E'|'e') ;
TABLE 	:	('T'|'t')('A'|'a')('B'|'b')('L'|'l')('E'|'e') ;
CHAR	:	('C'|'c')('H'|'h')('A'|'a')('R'|'r') ;
CHARACTER:	('C'|'c')('H'|'h')('A'|'a')('R'|'r')('A'|'a')('C'|'c')('T'|'t')('E'|'e')('R'|'r') ;
VARYING	:	('V'|'v')('A'|'a')('R'|'r')('Y'|'y')('I'|'i')('N'|'n')('G'|'g') ;
VARCHAR	:	('V'|'v')('A'|'a')('R'|'r')('C'|'c')('H'|'h')('A'|'a')('R'|'r') ;
NUMERIC	:	('N'|'n')('U'|'u')('M'|'m')('E'|'e')('R'|'r')('I'|'i')('C'|'c') ;
NUMBER	:	('N'|'n')('U'|'u')('M'|'m')('B'|'b')('E'|'e')('R'|'r') ;
DECIMAL	:	('D'|'d')('E'|'e')('C'|'c')('I'|'i')('M'|'m')('A'|'a')('L'|'l') ;
DEC	:	('D'|'d')('E'|'e')('C'|'c') ;
INTEGER	:	('I'|'i')('N'|'n')('T'|'t')('E'|'e')('G'|'g')('E'|'e')('R'|'r') ;
INT	:	('I'|'i')('N'|'n')('T'|'t') ;
CONSTRAINT:	('C'|'c')('O'|'o')('N'|'n')('S'|'s')('T'|'t')('R'|'r')('A'|'a')('I'|'i')('N'|'n')('T'|'t') ;

EQ	:	'=' ;
NEQ	:	'<>' | '!=';
LT	:	'<' ;
LTE	:	'<=' ;
GT	:	'>' ;
GTE	:	'>=' ;

STRING	:	'\'' ( ~'\'' | '\'' '\'' )* '\'' ;

V_INTEGER:	('0'..'9')+ ;
V_NUMBER:	('0'..'9')+ ('.' ('0'..'9')+)? ;

IDENT	:	('_'|'A'..'Z'|'a'..'z') ('_'|'A'..'Z'|'a'..'z'|'0'..'9')* ;

SL_COMMENT:	'--' (~('\r' | '\n'))* ('\r'? '\n')? {$channel=HIDDEN;} ;

ML_COMMENT:	'/*' (options {greedy=false;} : .)* '*/' {$channel=HIDDEN;} ;

WS	:	(' '|'\t'|'\n'|'\r')+ {$channel=HIDDEN;} ;
