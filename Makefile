GRAMMAR=Query

GENSRC=$(GRAMMAR)Lexer.java $(GRAMMAR)Parser.java

GEN=$(GENSRC) $(GRAMMAR)__.g $(GRAMMAR).tokens 


.PHONY: all gen test clean

all: test

gen:
	java org.antlr.Tool $(GRAMMAR).g

test: gen
	javac -Xmaxerrs 1 Test.java $(GENSRC)

clean:
	rm -f $(GEN) *.class
