package cafedb.sqlparser;

import org.antlr.runtime.tree.CommonTree;

import java.io.IOException;

public class Print
{
    public static void main(String[] args) throws Exception
    {
        printQuery(ParseDriver.parseQuery("select * from foo"));

        printQuery(ParseDriver.parseQueryList(getTpchDdl()));

        printQuery(ParseDriver.parseQueryList(getTpchQuery(6)));
        printQuery(ParseDriver.parseQueryList(getTpchQuery(2)));
    }

    private static void printQuery(CommonTree tree)
    {
        System.out.println(TreePrinter.stringTree(tree));
    }

    private static String getTpchDdl() throws IOException
    {
        return readResource("tpch/dss.ddl");
    }

    private static String getTpchQuery(int q) throws IOException
    {
        return fixTpchQuery(readResource("tpch/queries/" + q + ".sql"));
    }

    private static String readResource(String name) throws IOException
    {
        return ParseDriver.readStream(Print.class.getClassLoader().getResourceAsStream(name));
    }

    private static String fixTpchQuery(String s)
    {
        s = s.replaceFirst("(?m);$", "");
        s = s.replaceAll("(?m)^:[xo]$", "");
        s = s.replaceAll("(?m)^:n -1$", "");
        s = s.replaceAll("(?m)^:n ([0-9]+)$", "LIMIT $1");
        s = s.replaceAll("([^']):([0-9]+)", "$1$2");
        s += ";";
        return s;
    }
}
