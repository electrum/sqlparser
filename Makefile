GRAMMAR=Query

GENSRC=antlr/$(GRAMMAR)Lexer.java antlr/$(GRAMMAR)Parser.java


.PHONY: all gen test clean

all: test

gen:
	java org.antlr.Tool -o antlr $(GRAMMAR).g

test: gen
	javac -Xmaxerrs 1 Test.java $(GENSRC)

clean:
	rm -f *.class
	rm -rf antlr
