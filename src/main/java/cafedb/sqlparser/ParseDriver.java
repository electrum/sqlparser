package cafedb.sqlparser;

import org.antlr.runtime.ANTLRStringStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.RecognitionException;
import org.antlr.runtime.tree.CommonTree;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;

public class ParseDriver
{
    public static CommonTree parseQuery(String s) throws RecognitionException
    {
        return (CommonTree) getParser(s).query().getTree();
    }

    public static CommonTree parseQueryList(String s) throws RecognitionException
    {
        return (CommonTree) getParser(s).queryList().getTree();
    }

    private static QueryParser getParser(String s)
    {
        ANTLRStringStream input = new ANTLRNoCaseStringStream(s);
        QueryLexer lexer = new QueryLexer(input);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        return new QueryParser(tokens);
    }

    private static class ANTLRNoCaseStringStream extends ANTLRStringStream
    {
        public ANTLRNoCaseStringStream(String input)
        {
            super(input);
        }

        @Override
        public int LA(int i)
        {
            return Character.toUpperCase(super.LA(i));
        }
    }

    public static String readStream(InputStream in) throws IOException
    {
        Reader r = new InputStreamReader(in);
        StringBuilder sb = new StringBuilder();
        char[] buf = new char[4096];
        int n;
        while ((n = r.read(buf)) >= 0) {
            sb.append(buf, 0, n);
        }
        return sb.toString();
    }
}
