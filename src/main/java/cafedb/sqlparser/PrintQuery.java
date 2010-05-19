package cafedb.sqlparser;

import org.antlr.runtime.ANTLRStringStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.RecognitionException;
import org.antlr.runtime.tree.CommonTree;

import java.io.BufferedReader;
import java.io.InputStreamReader;

public class PrintQuery
{
    @SuppressWarnings({"UseOfSystemOutOrSystemErr"})
    public static void main(String[] args) throws Exception
    {
        BufferedReader stdin = new BufferedReader(new InputStreamReader(System.in));
        while (true) {
            System.out.print("Query> ");
            System.out.flush();

            String line = stdin.readLine();
            if (line == null) {
                break;
            }

            try {
                String s = TreePrinter.stringTree(getParser(line).query().tree);
                System.out.println(s);
            }
            catch (RecognitionException e) {
                // fix race condition with console
                Thread.sleep(1);
            }
            System.out.println();
        }
    }

    private static QueryParser getParser(String s)
    {
        ANTLRStringStream input = new ANTLRStringStream(s);
        QueryLexer lexer = new QueryLexer(input);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        return new QueryParser(tokens);
    }
}
