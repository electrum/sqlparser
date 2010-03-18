import org.antlr.runtime.*;

public class Test {
    public static void main(String[] args) throws Exception {
        ANTLRInputStream input = new ANTLRInputStream(System.in);
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
        System.out.println(root.tree.toStringTree());
    }
}
