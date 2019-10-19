package Utils;

import AndroidProjectRepresentation.MethodOfAPI;
import AndroidProjectRepresentation.Variable;;
import Metrics.APIEvaluator;
import com.github.javaparser.ast.Node;
import com.github.javaparser.ast.expr.*;
import com.github.javaparser.ast.stmt.LabeledStmt;
import com.github.javaparser.ast.visitor.GenericVisitor;
import com.github.javaparser.ast.visitor.GenericVisitorAdapter;
import com.github.javaparser.ast.visitor.VoidVisitorAdapter;

import java.util.HashMap;

public class InferAPIEntrypointFromExpression extends VoidVisitorAdapter {



    public boolean isPartOfMethodCall( Expression e){
        return e.getParentNode() instanceof MethodCallExpr || e.getParentNode().getParentNode() instanceof MethodCallExpr;
    }


    @Override
    public void visit(MethodCallExpr n, Object arg) {
        MethodOfAPI moa = ((MethodOfAPI) ((Pair) arg).second);
        APIEvaluator ape = ((APIEvaluator) ((Pair) arg).first);
        if (n.getArgs()!=null){
            for (Expression e : n.getArgs()){
                String type = ape.inferReturnType(  e, MethodOfAPI.unknownType);
                moa.args.add(new Variable(type));
            }
        }
        if (n.getScope()!=null){
            moa.method=n.getName();
            ape.localMethodsUsed.add(moa);
            String scopeType = ape.inferBelongingClass( n.getScope(), moa.returnType);
            MethodOfAPI moa1 = new MethodOfAPI();
            moa1.returnType = MethodOfAPI.unknownType;
            moa1.referenceClass=scopeType;
            moa1.method=null;
            Pair<APIEvaluator, MethodOfAPI> p = new Pair<>(ape,moa1);
            arg=p;
            //ape.localMethodsUsed.add(moa1);
        }

        super.visit(n, arg);
        if (moa.method==null||moa.method.equals(MethodOfAPI.unknownType)) {
            moa.method=n.getName();
            moa.reference= n;
        }
    }



    @Override
    public void visit(ObjectCreationExpr n, Object arg) {
        MethodOfAPI moa = ((MethodOfAPI) ((Pair) arg).second);
        APIEvaluator ape = ((APIEvaluator) ((Pair) arg).first);
        if (n.getArgs()!=null){
            for (Expression e : n.getArgs()){
                String type = ape.inferReturnType(  e, MethodOfAPI.unknownType);
                moa.args.add(new Variable(type));
            }
        }

        super.visit(n, arg);
        if (moa.method==null||moa.method.equals("")) {
            moa.method= n.getScope()!=null? (n.getScope() + "."+  n.getType().getName()) : n.getType().getName();
            moa.returnType=ape.inferReturnType(n,MethodOfAPI.unknownType);
            moa.referenceClass=moa.returnType;
        }
        moa.reference=n;
        ape.localMethodsUsed.add(moa);
    }

    public void visit(Expression n, Object arg) {
        Pair<APIEvaluator, MethodOfAPI> p = ((Pair) arg);
        MethodOfAPI moa = ((MethodOfAPI) ((Pair) arg).second);
        APIEvaluator ape = ((APIEvaluator) ((Pair) arg).first);
        //
        if (n instanceof MethodCallExpr) {
            visit(((MethodCallExpr) n), arg);
        } else if (n instanceof ObjectCreationExpr) {
            visit(((ObjectCreationExpr) n), arg);
        }
        else if ( (moa.method==null || moa.method.equals(MethodOfAPI.unknownType)) && ! ape.inferBelongingClass(n,moa.returnType ).equals(MethodOfAPI.unknownType)) {
               moa.method= ape.inferBelongingClass(n, moa.returnType);
                moa.reference=n;
        }
    }

}
