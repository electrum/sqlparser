package cafedb.sqlparser;

public class Test
{
    public static void main(String[] args) throws Exception
    {
        try {
            String s = ParseDriver.readStream(System.in);
            System.out.println(ParseDriver.parseQueryList(s).toStringTree());
        }
        catch (Exception e) {
            System.exit(100);
        }
    }
}
