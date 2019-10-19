package Utils;

import AndroidProjectRepresentation.MethodInfo;
import AndroidProjectRepresentation.MethodOfAPI;
import AndroidProjectRepresentation.Variable;

import Metrics.APIEvaluator;
import com.github.javaparser.ast.Node;
import com.github.javaparser.ast.body.*;
import com.github.javaparser.ast.expr.*;
import com.github.javaparser.ast.stmt.ExpressionStmt;
import com.github.javaparser.ast.stmt.IfStmt;
import com.github.javaparser.ast.type.ReferenceType;
import com.github.javaparser.ast.type.Type;
import com.github.javaparser.ast.visitor.VoidVisitorAdapter;


import java.util.HashMap;
import java.util.HashSet;

public class APIUsageVisitor extends VoidVisitorAdapter {



    @Override
    public void visit(MethodCallExpr n, Object arg) {
        APIEvaluator ape = ((APIEvaluator) arg);
        MethodOfAPI moa = new MethodOfAPI();
        moa.referenceClass = ape.inferBelongingClass(n,  MethodOfAPI.unknownType);
        moa.method = n.getName();
        if (n.getArgs()!=null){
            for (Expression e : n.getArgs()){
                String type = ape.inferBelongingClass(  e, MethodOfAPI.unknownType);
                moa.args.add(new Variable(type));
            }
        }
        super.visit(n, arg);
        moa.returnType=ape.inferReturnType(n,MethodOfAPI.unknownType);
        moa.reference=n;
        ape.localMethodsUsed.add(moa);

    }



    @Override
    public void visit(FieldDeclaration n, Object arg) {
        APIEvaluator ape = ((APIEvaluator) arg);
        if (n.getType()!=null){
            String type = ape.inferReturnType(n.getType(), MethodOfAPI.unknownType);
            for (VariableDeclarator vd: n.getVariables()){
                if (vd.getId()!=null){
                    Variable var =  new Variable(vd.getId().getName(),type,vd.getId().getArrayCount());
                    ape.classAndInstanceVars.add(var);
                }
            }
        }
    }


    // e.g catch (ParseException | Exception e)
    @Override
    public void visit(MultiTypeParameter n, Object arg) {
        APIEvaluator ape = ((APIEvaluator) arg);
        if (n.getTypes()!=null){
            for (Type t : n.getTypes() ){
                if (t.toString().contains("Exception")){
                    String type = ape.inferReturnType(t, MethodOfAPI.unknownType);
                    Variable var =  new Variable(n.getId().getName(),"Exception",n.getId().getArrayCount());
                    ape.localVars.put(n.getId().getName(),var);
                }

            }
        }
        super.visit(n,arg);
    }


    @Override
    public void visit(VariableDeclarationExpr n, Object arg) {
        APIEvaluator ape = ((APIEvaluator) arg);
        if (n.getType()!=null){
            String type = ape.inferReturnType(n.getType(), MethodOfAPI.unknownType);
            for (VariableDeclarator vd: n.getVars()){
                MethodOfAPI moa = new MethodOfAPI();
                moa.returnType = type;
                if (vd.getId()!=null){
                    Variable var =  new Variable(vd.getId().getName(),type,vd.getId().getArrayCount());
                    ape.localVars.put(vd.getId().getName(),var);
                }
                moa.method=null;
                InferAPIEntrypointFromExpression iaefe = new InferAPIEntrypointFromExpression();
                iaefe.visit(vd.getInit(),new Pair<APIEvaluator, MethodOfAPI> (ape,moa));
                //moa.referenceClass =type;
                moa.reference=n;
                ape.localMethodsUsed.add(moa);
            }
        }
        super.visit(n, arg);

        //super.visit(n,arg);
    }






    @Override
    public void visit(ObjectCreationExpr n, Object arg) {
        Object arg2 = arg;
        if (n.getAnonymousClassBody()!=null){
            APIEvaluator ape =  new APIEvaluator((APIEvaluator) arg);
            ape.className= n.getType().toStringWithoutComments();
            ape.outterClass= ((APIEvaluator) arg).className;
            ape.extendedClass= (n.getType()!=null && n.getType().getScope()!=null)? n.getType().getScope().toStringWithoutComments() : "";
            ape.loadClassVars(n.getAnonymousClassBody(), this);
            ape.getMethodsAPI(n.getAnonymousClassBody(), this);
            super.visit(n, ape);
            ((APIEvaluator) arg2).apisUsed.putAll(ape.apisUsed);
        }
        else {
            super.visit(n, arg);
        }

    }

    @Override
    public void visit(MethodDeclaration n, Object arg) {
        APIEvaluator ape = ((APIEvaluator) arg);
        String metId = getMethodID(n, ape.packageClass, ape.outterClass);
        if (n.getParameters()!=null){
            for (Parameter m : ((MethodDeclaration) n).getParameters()) {
                int isArray = (m.getType() instanceof ReferenceType)? ((ReferenceType) m.getType()).getArrayCount() : 0;
                ape.localArgs.put( m.getId().getName() , new Variable(m.getId().getName(), m.getType().toStringWithoutComments(), isArray));
            }
        }

        if (n.getBody() != null) {
            for (Node node : n.getBody().getStmts() ){
                if (node instanceof ExpressionStmt){
                    if (((ExpressionStmt) node).getExpression()!=null && ((ExpressionStmt) node).getExpression() instanceof VariableDeclarationExpr){
                        this.visit(((VariableDeclarationExpr) ((ExpressionStmt) node).getExpression()),arg);
                    }
                }
              //  else if ()
            }
        }
        super.visit(n, arg);
        ape.localVars.clear();
        ape.apisUsed.putIfAbsent(metId, ape.localMethodsUsed);
        ape.localMethodsUsed = new HashSet<>();

    }


    public static String  getMethodID (MethodDeclaration n , String packageName, String outter ){
        Node x = n.getParentNode();
        while (x!=null &&  ( (!(x instanceof ClassOrInterfaceDeclaration)) && ( ! (x instanceof ObjectCreationExpr ) ) ) ){
            x = x.getParentNode();
        }
        Node x2 = x.getParentNode();
        while (x2!=null && (!(x2 instanceof ClassOrInterfaceDeclaration))){
            x2 = x2.getParentNode();
        }
        if (x instanceof ObjectCreationExpr && x2!=null){
            return MethodInfo.idFromMethodDeclaration(n, ((ClassOrInterfaceDeclaration) x2).getName(), ((ObjectCreationExpr) x).getType().toStringWithoutComments() , packageName, "" );
        }

        else if (x!=null && x2!=null){
            return MethodInfo.idFromMethodDeclaration(n, ((ClassOrInterfaceDeclaration) x2).getName(), ((ClassOrInterfaceDeclaration) x).getName(), packageName, "" );

        }
        else if (x!=null){
            return MethodInfo.idFromMethodDeclaration(n,  outter, ((ClassOrInterfaceDeclaration) x).getName(), packageName, "" );

        }
        else{
            return MethodInfo.idFromMethodDeclaration(n,outter , MethodOfAPI.unknownType , packageName,"" );

        }
    }

    @Override
    public void visit(ClassOrInterfaceDeclaration n, Object arg) {
        APIEvaluator ape = ((APIEvaluator) arg);
        ape.className= n.getName();
        ape.extendedClass= (n.getExtends()!=null && n.getExtends().size()>0)? n.getExtends().get(0).getName() : "";
        ape.loadClassVars(n.getMembers(), this);
        ape.getMethodsAPI(n.getMembers(), this);
        super.visit(n, arg);
    }

}
