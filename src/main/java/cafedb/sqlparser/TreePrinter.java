package cafedb.sqlparser;

import org.antlr.runtime.tree.CommonTree;

import java.util.List;

public class TreePrinter
{
    public static String stringTree(CommonTree tree)
    {
        return doStringTree(tree, 1);
    }

    @SuppressWarnings({"unchecked"})
    private static String doStringTree(CommonTree tree, int depth)
    {
        if (tree.getChildCount() == 0) {
            return tree.toString();
        }
        if (tree.isNil()) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        sb.append("(");
        sb.append(tree.toString());
        for (CommonTree t : (List<CommonTree>) tree.getChildren()) {
            if (!isLeaf(tree)) {
                sb.append("\n");
                sb.append(repeatString("   ", depth));
            }
            else {
                sb.append(" ");
            }
            sb.append(doStringTree(t, depth + 1));
        }
        sb.append(")");
        return sb.toString();
    }

    @SuppressWarnings({"unchecked"})
    private static boolean isLeaf(CommonTree tree)
    {
        for (CommonTree t : (List<CommonTree>) tree.getChildren()) {
            if (t.getChildCount() > 0) {
                return false;
            }
        }
        return true;
    }

    private static String repeatString(String s, int n)
    {
        StringBuilder sb = new StringBuilder(s.length() * n);
        for (int i = 0; i < n; i++) {
            sb.append(s);
        }
        return sb.toString();
    }
}
