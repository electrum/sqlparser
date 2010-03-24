package cafedb.sqlparser;

import org.antlr.runtime.ANTLRStringStream;
import org.antlr.runtime.CommonTokenStream;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;

public class Print
{
    public static void main(String[] args) throws IOException
    {
        String s = readTpchQuery(getTpchQuery(6));

        ANTLRStringStream input = new ANTLRStringStream(s);
        QueryLexer lexer = new QueryLexer(input);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        QueryParser parser = new QueryParser(tokens);
        QueryParser.prog_return root;
        try {
            root = parser.prog();
        }
        catch (Exception e) {
            System.exit(100);
            return;
        }
        System.out.println(TreePrinter.stringTree(root.tree));
    }

    private static InputStreamReader getTpchQuery(int q)
    {
        String s = "tpch/queries/" + q + ".sql";
        return new InputStreamReader(Print.class.getClassLoader().getResourceAsStream(s));
    }

    private static String readTpchQuery(Reader r) throws IOException
    {
        String s = readFile(r);
        s = s.replaceAll("(?m)^:[xo]$", "");
        s = s.replaceAll("(?m)^:n -?[0-9]+", "");
        s = s.replaceAll("([^']):([0-9]+)", "$1$2");
        return s;
    }

    private static String readFile(Reader r) throws IOException
    {
        StringBuilder sb = new StringBuilder();
        char[] buf = new char[4096];
        int n;
        while ((n = r.read(buf)) >= 0) {
            sb.append(buf, 0, n);
        }
        return sb.toString();
    }
}
