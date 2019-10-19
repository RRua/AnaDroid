package Utils;

import AndroidProjectRepresentation.APICallUtil;
import AndroidProjectRepresentation.ClassInfo;
import com.github.javaparser.ast.CompilationUnit;
import com.github.javaparser.ast.Node;
import com.github.javaparser.ast.body.ClassOrInterfaceDeclaration;
import com.github.javaparser.ast.body.MethodDeclaration;
import com.github.javaparser.ast.stmt.DoStmt;
import com.github.javaparser.ast.type.ClassOrInterfaceType;
import com.github.javaparser.ast.visitor.VoidVisitorAdapter;

public class MethodChangerVisitor extends VoidVisitorAdapter {

    @Override
    public void visit(MethodDeclaration n, Object arg) {
        CompilationUnit cu = ((CompilationUnit) arg);
        Node x = n.getParentNode();
        while (x!=null && (!(x instanceof ClassOrInterfaceDeclaration))){
            x = x.getParentNode();
        }





    }



}
