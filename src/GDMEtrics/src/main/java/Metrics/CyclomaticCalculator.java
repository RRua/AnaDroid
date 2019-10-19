package Metrics;

import AndroidProjectRepresentation.MethodInfo;
import AndroidProjectRepresentation.MethodOfAPI;
import AndroidProjectRepresentation.Variable;
import com.github.javaparser.ast.Node;
import com.github.javaparser.ast.body.ConstructorDeclaration;
import com.github.javaparser.ast.body.MethodDeclaration;
import com.github.javaparser.ast.body.VariableDeclarator;
import com.github.javaparser.ast.expr.*;
import com.github.javaparser.ast.stmt.*;
import com.github.javaparser.ast.type.ReferenceType;

import java.util.ArrayList;
import java.util.List;

public class CyclomaticCalculator  {




    public static int cyclomaticAndAPI(Node n, MethodInfo mi){
        int counter = 0;
        if(n==null) return 0;
        if(n instanceof  MethodDeclaration ){
            if(((MethodDeclaration) n).getBody()==null)
                return 1;
            if(((MethodDeclaration) n).getBody().getStmts()==null || ((MethodDeclaration) n).getBody().getStmts().size()==0)
                return counter;
            List<Statement> x = ((MethodDeclaration) n).getBody().getStmts();
            for (Node s : x) {
                counter += cyclomaticAndAPI(s,mi);
                if(s instanceof SwitchStmt){
                   for(Statement st : ((SwitchStmt) s).getEntries()){
                       counter += 1+ cyclomaticAndAPI(st,mi);
                   }
                }
            }
            if(((MethodDeclaration) n).getThrows()!=null)
                counter  += ((MethodDeclaration) n).getThrows().size();
            return counter+1;
        }
        else  if(n instanceof  ConstructorDeclaration){
            if(((ConstructorDeclaration) n).getBlock().getStmts()==null || ((ConstructorDeclaration) n).getBlock().getStmts().size()==0)
                return counter;
            List<Statement> x = ((ConstructorDeclaration) n).getBlock().getStmts();
            for (Node s : x) {
                counter += cyclomaticAndAPI(s,mi);
                if(s instanceof SwitchStmt){
                    for(Statement st : ((SwitchStmt) s).getEntries()){
                        counter += 1 + cyclomaticAndAPI(st,mi);
                    }

                }
            }
            if(((ConstructorDeclaration) n).getThrows()!=null)
                counter  += ((ConstructorDeclaration) n).getThrows().size();

            return counter+1;

        } else if (n instanceof ContinueStmt) {
            return  1;
        } else if (n instanceof BlockStmt) {
            if(((BlockStmt) n).getStmts()==null)
                return 0;
            for (Statement s : ((BlockStmt) n).getStmts()) {
                counter += cyclomaticAndAPI(s,mi);
            }

        } else if (n instanceof WhileStmt) {
            counter += 1 + cyclomaticAndAPI(((WhileStmt) n).getBody(),mi);
            counter +=  cyclomaticAndAPI(((WhileStmt) n).getCondition(),mi);
            // + countOperations(((WhileStmt) n).getCondition());
        } else if (n instanceof ForStmt) {
            counter += 1 + cyclomaticAndAPI(((ForStmt) n).getBody(),mi);
            if(((ForStmt) n).getInit()!=null)
                counter +=  cyclomaticAndAPI(((ForStmt) n).getInit().get(0),mi);
            if(((ForStmt) n).getCompare()!=null)
                counter +=  cyclomaticAndAPI(((ForStmt) n).getCompare(),mi);
            if(((ForStmt) n).getUpdate()!=null)
                counter +=  cyclomaticAndAPI(((ForStmt) n).getUpdate().get(0),mi);
        } else if (n instanceof DoStmt) {
            counter += 1 + cyclomaticAndAPI(((DoStmt) n).getBody(),mi);
            counter +=  cyclomaticAndAPI(((DoStmt) n).getCondition(),mi);
        } else if (n instanceof ForeachStmt) {
            counter += 1 + cyclomaticAndAPI(((ForeachStmt) n).getBody(), mi);
            counter +=  cyclomaticAndAPI(((ForeachStmt) n).getIterable(),mi);
            counter +=  cyclomaticAndAPI(((ForeachStmt) n).getVariable(),mi);

        } else if (n instanceof MethodCallExpr) {
            counter += cyclomaticAndAPI(((MethodCallExpr) n).getScope(),mi);
            if(((MethodCallExpr) n).getArgs()!=null)
                for (Expression s :((MethodCallExpr) n).getArgs()){
                    counter +=  cyclomaticAndAPI(s,mi);
                }
            return 0;

        } else if (n instanceof VariableDeclarationExpr) {
            int isArray = (((VariableDeclarationExpr) n).getType() instanceof ReferenceType) ? ((ReferenceType) ((VariableDeclarationExpr) n).getType()).getArrayCount() : 0;
            for (VariableDeclarator v : ((VariableDeclarationExpr) n).getVars()){
                counter += cyclomaticAndAPI(v,mi);
                //mi.declaredVars.add(new Variable(v.getId().getName(),((VariableDeclarationExpr) n).getType().toStringWithoutComments(), isArray));
            }
           // mi.unknownApi.add(new MethodOfAPI (((VariableDeclarationExpr) n).getType().toStringWithoutComments()));
        } else if (n instanceof VariableDeclarator) {
            counter +=  cyclomaticAndAPI(((VariableDeclarator) n).getInit(),mi);
        } else if (n instanceof ObjectCreationExpr) {
           // mi.unknownApi.add(new MethodOfAPI(((ObjectCreationExpr) n).getType().getName()));
            //if(((ObjectCreationExpr) n).getScope()!=null)
               // mi.unknownApi.add(new MethodOfAPI(((ObjectCreationExpr) n).getScope().toStringWithoutComments()));
            if(((ObjectCreationExpr) n).getArgs()!=null){
                for (Expression e : ((ObjectCreationExpr) n).getArgs())
                    cyclomaticAndAPI(e,mi);
            }
            return 0;
        } else if (n instanceof SynchronizedStmt) {
            counter += 1 + cyclomaticAndAPI(((SynchronizedStmt) n).getBlock(),mi);
        } else if (n instanceof SwitchStmt) {
            for (Node s : ((SwitchStmt) n).getEntries()) {
                counter +=  cyclomaticAndAPI(s,mi);
            }
            //  counter = (counter == 0 ? 1 : counter) * ((SwitchStmt) n).getEntries().size();
        } else if (n instanceof SwitchEntryStmt) {
            if(((SwitchEntryStmt) n).getStmts()!=null)
                for (Statement s : ((SwitchEntryStmt) n).getStmts() ) {
                    counter +=  cyclomaticAndAPI(s,mi) ;
                }

        } else if (n instanceof IfStmt) {
            counter +=  cyclomaticAndAPI(((IfStmt) n).getElseStmt(),mi) + cyclomaticAndAPI(((IfStmt) n).getThenStmt(),mi) + (((IfStmt) n).getElseStmt()==null ? 0 : 1);
        } else if (n instanceof ReturnStmt) {
            // Check if is the last return
            cyclomaticAndAPI(((ReturnStmt) n).getExpr(),mi);
            if (((n.getParentNode() instanceof MethodDeclaration)) || (n.getParentNode() instanceof BlockStmt && n.getParentNode().getParentNode() instanceof MethodDeclaration))
                return  0;
            else return 1;
        }
        else if (n instanceof CastExpr) {
           counter+= cyclomaticAndAPI(((CastExpr) n).getType(),mi) + cyclomaticAndAPI(((CastExpr) n).getExpr(),mi);
        }
        else if (n instanceof ConditionalExpr) { // x == y ? z : t
            counter +=  2 + cyclomaticAndAPI(((ConditionalExpr) n).getCondition(),mi) + cyclomaticAndAPI(((ConditionalExpr) n).getThenExpr(),mi) + cyclomaticAndAPI(((ConditionalExpr) n).getElseExpr(),mi);

        } else if (n instanceof ArrayAccessExpr) {
            counter += cyclomaticAndAPI(((ArrayAccessExpr) n).getIndex(),mi);
        } else if (n instanceof AssignExpr) {
            counter +=  cyclomaticAndAPI(((AssignExpr) n).getTarget(),mi) + cyclomaticAndAPI(((AssignExpr) n).getValue(),mi);
        } else if (n instanceof EnclosedExpr) {
            counter += cyclomaticAndAPI(((EnclosedExpr) n).getInner(),mi);
        } else if (n instanceof CatchClause) {
            counter += 1 + cyclomaticAndAPI(((CatchClause) n).getCatchBlock(),mi);
        } else if (n instanceof ThrowStmt) {
            return  1;

        } else if (n instanceof TypeDeclarationStmt) {
            //mi.unknownApi.add(new MethodOfAPI(((TypeDeclarationStmt) n).getTypeDeclaration().getName()));
            return  0;
        } else if (n instanceof MethodReferenceExpr) {
            //f(((MethodReferenceExpr) n).getScope()!=null)
           //     mi.unknownApi.add(new MethodOfAPI(((MethodReferenceExpr) n).getScope().toString()));
            return  0;
        } else if (n instanceof FieldAccessExpr) {
           // mi.unknownApi.add(new MethodOfAPI(((FieldAccessExpr) n).getScope().toString()));
            return  0;
        } else if (n instanceof BreakStmt) {
            if( !( n.getParentNode() instanceof  SwitchEntryStmt))
                return 1;
            else  return 0;
        } else if (n instanceof ExpressionStmt) {
            Expression s1 = ((ExpressionStmt) n).getExpression();
            counter += cyclomaticAndAPI(s1,mi);
        } else if (n instanceof SuperExpr) {
           // mi.unknownApi.add(new MethodOfAPI( mi.ci.extendedClass));
            return 0;

        } else if (n instanceof NameExpr) {
            //mi.addRespectiveAPI(new MethodOfAPI(((NameExpr) n).getName()));
            return 0;
        } else {
            return 0;
        }
        return counter;
    }






    public static int countOperations(Node n){
        int counter = 1;
        if(n==null) return 1;
        if(n instanceof  MethodDeclaration){
            if(((MethodDeclaration) n).getBody().getStmts()==null || ((MethodDeclaration) n).getBody().getStmts().size()==0)
                return 1;
            List<Statement> x = ((MethodDeclaration) n).getBody().getStmts();
            for (Node s : x) {
                counter += countOperations(s);

                if(s instanceof SwitchStmt){
                    counter = ((SwitchStmt) s).getEntries().size() * counter;

                }
            }
            if(((MethodDeclaration) n).getThrows()!=null)
                counter  += ((MethodDeclaration) n).getThrows().size();

            if (counter==0) return 1;
        }

        else  if(n instanceof  ConstructorDeclaration){
            if(((ConstructorDeclaration) n).getBlock().getStmts()==null || ((ConstructorDeclaration) n).getBlock().getStmts().size()==0)
                return 1;
            List<Statement> x = ((ConstructorDeclaration) n).getBlock().getStmts();
            for (Node s : x) {
                counter += countOperations(s);

                if(s instanceof SwitchStmt){
                    counter = ((SwitchStmt) s).getEntries().size() * counter;

                }
            }
            if(((ConstructorDeclaration) n).getThrows()!=null)
                counter  += ((ConstructorDeclaration) n).getThrows().size();
            if (counter==0) return 1;
        }
        else{

            if (n instanceof ExpressionStmt) {
                Expression s1 = ((ExpressionStmt) n).getExpression();
                counter += countOperations(s1);

            } else if (n instanceof WhileStmt) {
                counter += 1 + countOperations(((WhileStmt) n).getBody()); // + countOperations(((WhileStmt) n).getCondition());
            } else if (n instanceof ForStmt) {
                counter += 1 + countOperations(((ForStmt) n).getBody());
            } else if (n instanceof DoStmt) {
                counter += 1 + countOperations(((DoStmt) n).getBody());
            } else if (n instanceof ForeachStmt) {
                counter += 1 + countOperations(((ForeachStmt) n).getBody());

            } else if (n instanceof VariableDeclarationExpr) {
                for (VariableDeclarator v : ((VariableDeclarationExpr) n).getVars())
                    counter += countOperations(v);
            } else if (n instanceof VariableDeclarator) {
                counter +=  countOperations(((VariableDeclarator) n).getInit());
            } else if (n instanceof ObjectCreationExpr) {
                return 0;
            } else if (n instanceof SynchronizedStmt) {
                counter += 1 + countOperations(((SynchronizedStmt) n).getBlock());
            } else if (n instanceof SwitchStmt) {
                for (Node s : ((SwitchStmt) n).getEntries()) {
                    counter +=  countOperations(s);
                }
              //  counter = (counter == 0 ? 1 : counter) * ((SwitchStmt) n).getEntries().size();
            } else if (n instanceof SwitchEntryStmt) {
                for (Statement s : ((SwitchEntryStmt) n).getStmts() ) {
                    counter +=  countOperations(s) ;
                }

            } else if (n instanceof IfStmt) {
                //counter += 1+ countOperations(((IfStmt) n).getCondition()) + countOperations(((IfStmt) s).getElseStmt()) + countOperations(((IfStmt) s).getThenStmt());
                counter += 1+ countOperations(((IfStmt) n).getElseStmt()) + countOperations(((IfStmt) n).getThenStmt());
            } else if (n instanceof BlockStmt) {
                if (((BlockStmt) n).getStmts() != null) {
                    for (Statement e : ((BlockStmt) n).getStmts()) {


                        counter += countOperations(e);
                    }
                }
            } else if (n instanceof ReturnStmt) {
                // Check if is the last return
                if (((n.getParentNode() instanceof MethodDeclaration)) || (n.getParentNode() instanceof BlockStmt && n.getParentNode().getParentNode() instanceof MethodDeclaration))
                    return  0;
                else return 1;
                //+ countOperations(((ReturnStmt) n).getExpr()); TODO check this
            //} else if (n instanceof UnaryExpr) {
            //    counter = counter + countOperations(((UnaryExpr) s).getExpr())
            }
           /* else if (n instanceof BinaryExpr) {

                counter = counter + 1 + countOperations(((BinaryExpr) n).getLeft()) + countOperations(((BinaryExpr) n).getRight());

            }*/ else if (n instanceof ConditionalExpr) { // x == y ? z : t
                counter +=  2 + countOperations(((ConditionalExpr) n).getCondition()) + countOperations(((ConditionalExpr) n).getThenExpr()) + countOperations(((ConditionalExpr) n).getElseExpr());

            } else if (n instanceof ArrayAccessExpr) {
                counter += countOperations(((ArrayAccessExpr) n).getIndex());
            } else if (n instanceof AssignExpr) {
                counter +=  countOperations(((AssignExpr) n).getTarget()) + countOperations(((AssignExpr) n).getValue());
            } else if (n instanceof StringLiteralExpr) {
                return 0;
            } else if (n instanceof EnclosedExpr) {
                counter += countOperations(((EnclosedExpr) n).getInner());

            } else if (n instanceof CatchClause) {
                counter += 1 + countOperations(((CatchClause) n).getCatchBlock());
            } else if (n instanceof ContinueStmt) {
               return  1;
            } else if (n instanceof ThrowStmt) {
                return  1;
            } else if (n instanceof ContinueStmt) {
                return  1;
            } else if (n instanceof BlockStmt) {
                for (Statement s : ((BlockStmt) n).getStmts()) {
                    counter += countOperations(s);
                }
            } else if (n instanceof BreakStmt) {
                if( !( n.getParentNode() instanceof  SwitchEntryStmt))
                    return 1;
                else  return 0;
            } else {
                return 0;
            }

        }

        return counter;
        }

//    public static int countOperationsAndAPIUsage(Node n, MethodInfo mi){
//        int counter = 0;
//        if(n==null) return 0;
//        if(n instanceof  MethodDeclaration){
//            counter++;
//            List<Statement> x = ((MethodDeclaration) n).getBody().getStmts();
//            if(((MethodDeclaration) n).getBody().getStmts()==null || ((MethodDeclaration) n).getBody().getStmts().size()==0)
//                return 1;
//            for (Node s : x) {
//                counter += countOperationsAndAPIUsage(s,mi);
//
//                if(s instanceof SwitchStmt){
//                    counter = ((SwitchStmt) s).getEntries().size() * counter;
//
//                }
//            }
//            if(((MethodDeclaration) n).getThrows()!=null)
//                counter  += ((MethodDeclaration) n).getThrows().size();
//
//           // if (counter==0) return 1;
//        }
//        else if(n instanceof ConstructorDeclaration){
//            counter++;
//            List<Statement> x = ((ConstructorDeclaration) n).getBlock().getStmts();
//            if(((ConstructorDeclaration) n).getBlock().getStmts()==null || ((ConstructorDeclaration) n).getBlock().getStmts().size()==0)
//                return 1;
//            for (Node s : x) {
//                counter += countOperationsAndAPIUsage(s,mi);
//
//                if(s instanceof SwitchStmt){
//                    counter = ((SwitchStmt) s).getEntries().size() * counter;
//
//                }
//            }
//            if(((ConstructorDeclaration) n).getThrows()!=null)
//                counter  += ((ConstructorDeclaration) n).getThrows().size();
//            //if (counter==0) return 1;
//        }
//        else{
//
//            if (n instanceof ExpressionStmt) {
//                Expression s1 = ((ExpressionStmt) n).getExpression();
//                counter += countOperationsAndAPIUsage(s1,mi);
//
//            } else if (n instanceof WhileStmt) {
//                counter += 1 + countOperationsAndAPIUsage(((WhileStmt) n).getBody(),mi); // + countOperationsAndAPIUsage(((WhileStmt) n).getCondition());
//            } else if (n instanceof ForStmt) {
//                counter += 1 + countOperationsAndAPIUsage(((ForStmt) n).getBody(),mi);
//                if(((ForStmt) n).getInit()!=null)
//                    counter +=  countOperationsAndAPIUsage(((ForStmt) n).getInit().get(0),mi);
//                if(((ForStmt) n).getCompare()!=null)
//                    counter +=  countOperationsAndAPIUsage(((ForStmt) n).getCompare(),mi);
//                if(((ForStmt) n).getUpdate()!=null)
//                    counter +=  countOperationsAndAPIUsage(((ForStmt) n).getUpdate().get(0),mi);
//
//            } else if (n instanceof DoStmt) {
//                counter += 1 + countOperationsAndAPIUsage(((DoStmt) n).getBody(),mi);
//            } else if (n instanceof ForeachStmt) {
//                counter += 1 + countOperationsAndAPIUsage(((ForeachStmt) n).getBody(),mi);
//                counter +=  countOperationsAndAPIUsage(((ForeachStmt) n).getIterable(),mi);
//                counter +=  countOperationsAndAPIUsage(((ForeachStmt) n).getVariable(),mi);
//            }
//            else if (n instanceof MethodCallExpr) {
//                // is  xx.toString or Integer.toString() or toString()
//                if(((MethodCallExpr) n).getScope()!=null){
//                    mi.addRespectiveAPI(((MethodCallExpr) n).getScope().toStringWithoutComments());
//                    counter += countOperationsAndAPIUsage(((MethodCallExpr) n).getScope(),mi);
//
//                }
//                else {
//                    // WHO knows???
//                }
//                if(((MethodCallExpr) n).getArgs()!=null)
//                    for (Expression s :((MethodCallExpr) n).getArgs()){
//                        counter +=  countOperationsAndAPIUsage(s,mi);
//                    }
//                return 0;
//            } else if (n instanceof VariableDeclarationExpr) {
//                boolean isArray = (((VariableDeclarationExpr) n).getType() instanceof ReferenceType) ? ((ReferenceType) ((VariableDeclarationExpr) n).getType()).getArrayCount()>0 : false;
//                for (VariableDeclarator v : ((VariableDeclarationExpr) n).getVars()){
//                    counter += countOperationsAndAPIUsage(v,mi);
//                    mi.declaredVars.add(new Variable(v.getId().getName(),((VariableDeclarationExpr) n).getType().toStringWithoutComments(), isArray));
//                }
//                mi.unknownApi.add(((VariableDeclarationExpr) n).getType().toStringWithoutComments());
//                return counter;
//            } else if (n instanceof VariableDeclarator) {
//                counter +=  countOperationsAndAPIUsage(((VariableDeclarator) n).getInit(),mi);
//                return counter;
//            } else if (n instanceof ObjectCreationExpr) {
//                mi.unknownApi.add(((ObjectCreationExpr) n).getType().getName());
//                if(((ObjectCreationExpr) n).getScope()!=null)
//                    mi.unknownApi.add(((ObjectCreationExpr) n).getScope().toStringWithoutComments());
//                return 0;
//            } else if (n instanceof SynchronizedStmt) {
//                counter += 1 + countOperationsAndAPIUsage(((SynchronizedStmt) n).getBlock(),mi);
//            } else if (n instanceof SwitchStmt) {
//                for (Node s : ((SwitchStmt) n).getEntries()) {
//                    counter +=  countOperationsAndAPIUsage(s,mi);
//                }
//                //  counter = (counter == 0 ? 1 : counter) * ((SwitchStmt) n).getEntries().size();
//            } else if (n instanceof SwitchEntryStmt) {
//                for (Statement s : ((SwitchEntryStmt) n).getStmts() ) {
//                    counter +=  countOperationsAndAPIUsage(s,mi) ; //TODO get switchesssssss testar com classe com switch
//                }
//
//            } else if (n instanceof IfStmt) {
//                //counter += 1+ countOperationsAndAPIUsage(((IfStmt) n).getCondition()) + countOperationsAndAPIUsage(((IfStmt) s).getElseStmt()) + countOperationsAndAPIUsage(((IfStmt) s).getThenStmt());
//                counter += 1+ countOperationsAndAPIUsage(((IfStmt) n).getElseStmt(),mi) + countOperationsAndAPIUsage(((IfStmt) n).getThenStmt(),mi);
//            } else if (n instanceof BlockStmt) {
//                if (((BlockStmt) n).getStmts() != null) {
//                    for (Statement e : ((BlockStmt) n).getStmts()) {
//
//                        counter += countOperationsAndAPIUsage(e,mi);
//                    }
//                }
//            } else if (n instanceof ReturnStmt) {
//                // Check if is the last return
//                if (((n.getParentNode() instanceof MethodDeclaration)) || (n.getParentNode() instanceof BlockStmt && n.getParentNode().getParentNode() instanceof MethodDeclaration)){
//                    counter+= countOperationsAndAPIUsage(((ReturnStmt) n).getExpr(),mi);
//                    return  0;
//                }
//                else{
//                    counter+= countOperationsAndAPIUsage(((ReturnStmt) n).getExpr(),mi);
//                    return 1;
//                }
//                //+ countOperationsAndAPIUsage(((ReturnStmt) n).getExpr()); TODO check this
//                //} else if (n instanceof UnaryExpr) {
//                //    counter = counter + countOperationsAndAPIUsage(((UnaryExpr) s).getExpr())
//            }
//            else if (n instanceof BinaryExpr) {
//                // TODO depends of  Operators	&&, ||, !!!!!!!
//                counter += countOperationsAndAPIUsage(((BinaryExpr) n).getLeft(),mi) + countOperationsAndAPIUsage(((BinaryExpr) n).getRight(),mi);
//
//            } else if (n instanceof ConditionalExpr) { // x == y ? z : t
//                counter +=  2 + countOperationsAndAPIUsage(((ConditionalExpr) n).getCondition(),mi) + countOperationsAndAPIUsage(((ConditionalExpr) n).getThenExpr(),mi) + countOperationsAndAPIUsage(((ConditionalExpr) n).getElseExpr(),mi);
//
//            } else if (n instanceof ArrayAccessExpr) {
//                counter += countOperationsAndAPIUsage(((ArrayAccessExpr) n).getIndex(),mi);
//            } else if (n instanceof AssignExpr) {
//                counter +=  countOperationsAndAPIUsage(((AssignExpr) n).getTarget(),mi) + countOperationsAndAPIUsage(((AssignExpr) n).getValue(),mi);
//
//            } else if (n instanceof StringLiteralExpr) {
//                return 0;
//            } else if (n instanceof EnclosedExpr) {
//                counter += countOperationsAndAPIUsage(((EnclosedExpr) n).getInner(),mi);
//
//            } else if (n instanceof CatchClause) {
//                counter += 1 + countOperationsAndAPIUsage(((CatchClause) n).getCatchBlock(),mi);
//            } else if (n instanceof ContinueStmt) {
//                return  1;
//            } else if (n instanceof ThrowStmt) {
//                return  1;
//            } else if (n instanceof ContinueStmt) {
//                return  1;
//            } else if (n instanceof TypeDeclarationStmt) {
//                mi.unknownApi.add(((TypeDeclarationStmt) n).getTypeDeclaration().getName());
//                return  0;
//            } else if (n instanceof MethodReferenceExpr) {
//                if(((MethodReferenceExpr) n).getScope()!=null)
//                mi.unknownApi.add(((MethodReferenceExpr) n).getScope().toString());
//                return  0;
//            } else if (n instanceof FieldAccessExpr) {
//                mi.unknownApi.add(((FieldAccessExpr) n).getScope().toString());
//                return  0;
//            } else if (n instanceof BlockStmt) {
//                for (Statement s : ((BlockStmt) n).getStmts()) {
//                    counter += countOperationsAndAPIUsage(s,mi);
//                }
//            } else if (n instanceof BreakStmt) {
//                if( !( n.getParentNode() instanceof  SwitchEntryStmt))
//                    return 1;
//                else  return 0;
//            } else if (n instanceof SuperExpr) {
//                mi.unknownApi.add(mi.ci.extendedClass);
//                return 0;
//            } else if (n instanceof NameExpr) {
//            mi.addRespectiveAPI(((NameExpr) n).getName());
//                return 0;
//            } else {
//                return 0;
//            }
//
//        }
//
//        return counter+1;
//    }
//



}
