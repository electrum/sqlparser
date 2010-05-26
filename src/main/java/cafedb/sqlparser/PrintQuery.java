package cafedb.sqlparser;

import org.antlr.runtime.RecognitionException;

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
                String s = TreePrinter.stringTree(ParseDriver.parseQueryList(line));
                System.out.println(s);
            }
            catch (RecognitionException e) {
                // fix race condition with console
                Thread.sleep(1);
            }
            System.out.println();
        }
    }
}
