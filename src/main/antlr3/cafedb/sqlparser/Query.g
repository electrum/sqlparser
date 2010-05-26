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

SELECT: 'SELECT';
FROM: 'FROM';
AS: 'AS';
ALL: 'ALL';
DISTINCT: 'DISTINCT';
WHERE: 'WHERE';
GROUP: 'GROUP';
BY: 'BY';
ORDER: 'ORDER';
HAVING: 'HAVING';
LIMIT: 'LIMIT';
OR: 'OR';
AND: 'AND';
IN: 'IN';
NOT: 'NOT';
EXISTS: 'EXISTS';
BETWEEN: 'BETWEEN';
LIKE: 'LIKE';
IS: 'IS';
NULL: 'NULL';
ESCAPE: 'ESCAPE';
ASC: 'ASC';
DESC: 'DESC';
SUBSTRING: 'SUBSTRING';
FOR: 'FOR';
DATE: 'DATE';
TIME: 'TIME';
TIMESTAMP: 'TIMESTAMP';
INTERVAL: 'INTERVAL';
YEAR: 'YEAR';
MONTH: 'MONTH';
DAY: 'DAY';
HOUR: 'HOUR';
MINUTE: 'MINUTE';
SECOND: 'SECOND';
CURRENT_DATE: 'CURRENT_DATE';
CURRENT_TIME: 'CURRENT_TIME';
CURRENT_TIMESTAMP: 'CURRENT_TIMESTAMP';
EXTRACT: 'EXTRACT';
TIMEZONE_HOUR: 'TIMEZONE_HOUR';
TIMEZONE_MINUTE: 'TIMEZONE_MINUTE';
COALESCE: 'COALESCE';
NULLIF: 'NULLIF';
CASE: 'CASE';
WHEN: 'WHEN';
THEN: 'THEN';
ELSE: 'ELSE';
END: 'END';
JOIN: 'JOIN';
CROSS: 'CROSS';
OUTER: 'OUTER';
INNER: 'INNER';
LEFT: 'LEFT';
RIGHT: 'RIGHT';
FULL: 'FULL';
NATURAL: 'NATURAL';
USING: 'USING';
ON: 'ON';
CREATE: 'CREATE';
TABLE: 'TABLE';
CHAR: 'CHAR';
CHARACTER: 'CHARACTER';
VARYING: 'VARYING';
VARCHAR: 'VARCHAR';
NUMERIC: 'NUMERIC';
NUMBER: 'NUMBER';
DECIMAL: 'DECIMAL';
DEC: 'DEC';
INTEGER: 'INTEGER';
INT: 'INT';
CONSTRAINT: 'CONSTRAINT';

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
