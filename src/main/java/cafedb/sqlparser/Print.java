package cafedb.sqlparser;

import org.antlr.runtime.ANTLRStringStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.tree.CommonTree;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;

public class Print
{
    public static void main(String[] args) throws Exception
    {
        printQuery(getParser("select * from foo").query().tree);

        printQuery(getParser(readFile(getTpchDdl())).queryList().tree);

        printQuery(getParser(readTpchQuery(getTpchQuery(6))).queryList().tree);
    }

    private static void printQuery(CommonTree tree)
    {
        System.out.println(TreePrinter.stringTree(tree));
    }

    private static QueryParser getParser(String s)
    {
        ANTLRStringStream input = new ANTLRStringStream(s);
        QueryLexer lexer = new QueryLexer(input);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        return new QueryParser(tokens);
    }

    private static InputStreamReader getTpchDdl()
    {
        return new InputStreamReader(Print.class.getClassLoader().getResourceAsStream("tpch/dss.ddl"));
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
