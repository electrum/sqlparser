package cafedb.sqlparser;

import org.antlr.runtime.ANTLRInputStream;
import org.antlr.runtime.CommonTokenStream;

public class Test
{
    public static void main(String[] args) throws Exception
    {
        ANTLRInputStream input = new ANTLRInputStream(System.in);
        QueryLexer lexer = new QueryLexer(input);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        QueryParser parser = new QueryParser(tokens);
        try {
            System.out.println(parser.prog().tree.toStringTree());
        }
        catch (Exception e) {
            System.exit(100);
        }
    }
}
