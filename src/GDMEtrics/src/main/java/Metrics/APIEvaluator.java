package Metrics;

import AndroidProjectRepresentation.MethodInfo;
import AndroidProjectRepresentation.MethodOfAPI;
import AndroidProjectRepresentation.NameExpression;
import AndroidProjectRepresentation.Variable;
import Utils.APIUsageVisitor;
import com.github.javaparser.ast.CompilationUnit;
import com.github.javaparser.ast.ImportDeclaration;
import com.github.javaparser.ast.Node;
import com.github.javaparser.ast.body.*;
import com.github.javaparser.ast.expr.*;
import com.github.javaparser.ast.type.ClassOrInterfaceType;
import com.github.javaparser.ast.type.PrimitiveType;
import com.github.javaparser.ast.type.ReferenceType;
import com.github.javaparser.ast.visitor.VoidVisitorAdapter;

import java.util.*;


public class APIEvaluator {
    public  String packageClass = "";
    public  String extendedClass = "";
    public  String outterClass = "";
    public  static Map<String,MethodInfo> allMethods= new HashMap<>();
    public  static Map<String,String> knownTypes= new HashMap<>();
    public  Set<Variable> classAndInstanceVars = new HashSet<>();
    public  Set<NameExpression> classImports = new HashSet<>();
    public  Map<String,Variable> localVars = new HashMap<>(); //name,type
    public  Map<String,Variable> localArgs = new HashMap<>();
    public  Set<MethodOfAPI> localMethodsUsed = new HashSet<>(); // methods used by a certain methods/public   Map<String,MethodOfAPI> classMethods = new HashSet<>();
    public  Map<String,Set<MethodOfAPI>> apisUsed = new HashMap<>();
    public String className ="";


    private void initTypes(){
        knownTypes= new HashMap<>();
        knownTypes.put("StringLiteralExpr", "String");
        knownTypes.put("IntegerLiteralExpr", "int");
        knownTypes.put("LongLiteralExpr", "long");
        knownTypes.put("DoubleLiteralExpr", "double");
        knownTypes.put("CharLiteralExpr", "char");
        knownTypes.put("System", "System");

    }

    public APIEvaluator(APIEvaluator evaluator){
        this.classAndInstanceVars= evaluator.classAndInstanceVars;
        this.packageClass = evaluator.packageClass;
        this.classImports = classImports;
    }


    public APIEvaluator (Set<Variable> classAndInstanceVars  ){
        initTypes();
        this.classAndInstanceVars = classAndInstanceVars;
        this.classImports= classImports;
        this.localVars = new HashMap<>();
        this.apisUsed=new HashMap<>();
        packageClass = "";
        localArgs = new HashMap<>();
        localMethodsUsed = new HashSet<>();
        className ="";
        outterClass ="";
        localMethodsUsed = new HashSet<>();

    }
    public APIEvaluator ( ){
        initTypes();
        this.classAndInstanceVars = new HashSet<>();
        this.classImports= new HashSet<>();
        this.localVars = new HashMap<>();
        this.apisUsed=new HashMap<>();
        packageClass = "";
        localArgs = new HashMap<>();
        localMethodsUsed = new HashSet<>();
        className ="";
        outterClass="";
        localMethodsUsed = new HashSet<>();

    }

    public void loadImports(List<ImportDeclaration> l){
        if (l != null) {
            for (ImportDeclaration id : l) {
                NameExpression ne = new NameExpression(((QualifiedNameExpr) id.getName()).getQualifier().toString(), ((QualifiedNameExpr) id.getName()).getName());
                this.classImports.add(ne);
                this.knownTypes.put(((QualifiedNameExpr) id.getName()).getName(), ((QualifiedNameExpr) id.getName()).getName());
            }
        }
    }

    public void loadClassVars(List<BodyDeclaration> bd, VoidVisitorAdapter auv){
        if (bd != null) {
            for (BodyDeclaration b : bd){
                if (b instanceof FieldDeclaration){
                  auv.visit(((FieldDeclaration) b),this);
                }
            }
        }
    }


    public  Map<String,MethodInfo> eval(CompilationUnit cu){
        APIUsageVisitor auv = new APIUsageVisitor();
        loadImports(cu.getImports());
        packageClass = cu.getPackage().getName().toStringWithoutComments();
        for (Node n : cu.getChildrenNodes()){
            if (n instanceof ClassOrInterfaceDeclaration){
                auv.visit(((ClassOrInterfaceDeclaration) n),this);   
            }
            
        }
        this.apisUsed=cleanSet();
        for (String s : allMethods.keySet()){
            allMethods.get(s).unknownApi=apisUsed.get(s);
        }

        return allMethods;
    }

    public MethodInfo getMethodsAPI ( List<BodyDeclaration> bd, VoidVisitorAdapter auv ){
        if (bd != null) {
            for (BodyDeclaration b : bd) {
                if (b instanceof MethodDeclaration){
                    auv.visit(((MethodDeclaration) b),this);
                    MethodInfo mi = new MethodInfo(((MethodDeclaration) b));
                    mi.declaredVars= new HashSet<>(localVars.values());
                    mi.args= new HashSet<>(this.localArgs.values());
                    this.localVars = new HashMap<>();
                    this.localArgs= new HashMap<>();
                    String id = MethodInfo.idFromMethodDeclaration(((MethodDeclaration) b), this.outterClass, this.className, this.packageClass,"");
                    mi.unknownApi.addAll(this.apisUsed.get(id));
                    allMethods.put(id, mi);
                }
            }
        }
        return null;
    }



    // infers belonging class of methods ?
    public  String inferBelongingClass(Node n , String returnType){

        if (n instanceof ClassOrInterfaceType){
            return ((ClassOrInterfaceType) n).getName();
        }
        else if (n instanceof SuperExpr ){
            return this.extendedClass;
        }
        else if (n instanceof MethodCallExpr){
            if (((MethodCallExpr) n).getScope()!=null){
                if ( ((MethodCallExpr) n).getScope() instanceof FieldAccessExpr ){
                    // e.g System.out.println()
                     return inferBelongingClass(((FieldAccessExpr) ((MethodCallExpr) n).getScope()).getScope(),returnType);
                }
                else if ( ((MethodCallExpr) n).getScope() instanceof SuperExpr ){
                    // super.onCreate(...);
                    return this.extendedClass;
                }
                else {
                    if( ! inferReturnType(((MethodCallExpr) n).getScope(), MethodOfAPI.unknownType).equals(returnType) ){
                        return inferReturnType(((MethodCallExpr) n).getScope(), MethodOfAPI.unknownType);
                    }
                }
            }
        }
        else if (n instanceof ObjectCreationExpr){
            return inferBelongingClass(((ObjectCreationExpr) n).getType(), returnType);
        }
        else if (n instanceof LiteralExpr){
            if (n instanceof NullLiteralExpr){
                return "null";
            }
        }
        String className = n.getClass().getEnclosingClass()==null ? n.getClass().getName().split("\\.")[n.getClass().getName().split("\\.").length-1] : n.getClass().getEnclosingClass().getName() ;
        if (knownTypes.containsKey(className) ){
            return knownTypes.get(className);
        }
        else if (n instanceof NameExpr ||  className.equals("NameExpr") ){
            if (localVars.containsKey(((NameExpr) n).getName())){
                return localVars.get(((NameExpr) n).getName()).type;
            }
            else if (localArgs.containsKey(((NameExpr) n).getName())){
                return localArgs.get(((NameExpr) n).getName()).type;
            }
            else if (knownTypes.containsKey(((NameExpr) n).getName()) ){
                return knownTypes.get(((NameExpr) n).getName());
            }
        }


        return returnType;

    }


    public  String inferReturnType(Node n , String returnType){
        if (n==null){
            return returnType;
        }
        else if (n instanceof ClassOrInterfaceType){
            return ((ClassOrInterfaceType) n).getName();
        }
        else if (n instanceof VariableDeclarator){
            return inferReturnType(((VariableDeclarator) n).getId(), returnType);
        }
        else if ( (! ( n instanceof VariableDeclaratorId )) && n.getParentNode() instanceof VariableDeclarator){
                return inferReturnType(((VariableDeclarator) n.getParentNode()).getId(), returnType);
        }
        else if (n instanceof ReferenceType){
            return ((ReferenceType) n).getType().toString();
        }
        else if (n instanceof PrimitiveType){
            return ((PrimitiveType) n).getType().toString();
        }
        else if (n instanceof MethodCallExpr &&  n.getParentNode() instanceof CastExpr){
            return inferReturnType(((CastExpr) n.getParentNode()).getType(), returnType);
        }
        else if (n instanceof ObjectCreationExpr){
            if (((ObjectCreationExpr) n).getType()!=null){
                return ((ObjectCreationExpr) n).getType().getName();
            }
        }
        String className = n.getClass().getEnclosingClass()==null ? n.getClass().getName().split("\\.")[n.getClass().getName().split("\\.").length-1] : n.getClass().getEnclosingClass().getName() ;
        if (knownTypes.containsKey(className) ){
            return knownTypes.get(className);
        }
        else if (n instanceof NameExpr ||  className.equals("NameExpr") ){
            if (localVars.containsKey(((NameExpr) n).getName())){
                return localVars.get(((NameExpr) n).getName()).type;
            }
            else if (localArgs.containsKey(((NameExpr) n).getName())){
                return localArgs.get(((NameExpr) n).getName()).type;
            }
            else if (knownTypes.containsKey(((NameExpr) n).getName()) ){
                return knownTypes.get(((NameExpr) n).getName());
            }
            else if (classAndInstanceVars.contains(((NameExpr) n).getName()) ){
                return ((Variable) classAndInstanceVars.stream().filter(x -> x.varName.equals(((NameExpr) n).getName())).toArray()[0]).type;
            }
        }
        else if ( n instanceof  NameExpr || (className.equals("NameExpr") && localArgs.containsKey(((NameExpr) n).getName())) ){
            return localArgs.get(((NameExpr) n).getName()).type;
        }
        else if( n instanceof VariableDeclaratorId ){
            if (localVars.containsKey(((VariableDeclaratorId) n).getName())){
                return localVars.get(((VariableDeclaratorId) n).getName()).type;
            }
            else if (localArgs.containsKey(((VariableDeclaratorId) n).getName())){
                return localArgs.get(((VariableDeclaratorId) n).getName()).type;
            }
            else if (classAndInstanceVars.contains(((VariableDeclaratorId) n).getName())){
                return ((Variable) classAndInstanceVars.stream().filter(x -> x.varName.equals(((NameExpr) n).getName())).toArray()[0]).type;
            }

        }
        else if (n.getParentNode() instanceof AssignExpr){
            return inferReturnType(((AssignExpr) n.getParentNode()).getTarget(), returnType);
        }

        return returnType;

    }


    public Map<String,Set<MethodOfAPI>> cleanSet(){
        Map<String,Set<MethodOfAPI>> newmap = new HashMap<>();
        for (String s : this.apisUsed.keySet()){
            Set<MethodOfAPI> ss = removeDuplicates(apisUsed.get(s));
            newmap.put(s, ss);
        }
        return newmap;
    }


    private static int getMatches(MethodOfAPI moa , MethodOfAPI moa1){
        int i =0;
        if (moa.args.size()!=moa1.args.size()){
            return i;
        }
        if (moa.referenceClass.equals(moa1.referenceClass)){
            i++;
        }
        if (moa.method.equals(moa1.method)){
            i++;
        }
        if (moa.returnType.equals(moa1.returnType)){
            i++;
        }
        for (int j = 0; j < moa.args.size() && i>0; j++) {
            if ( ( moa.args.get(j) ==null || moa.args.get(j).type.equals("null") || moa1.args.get(j) ==null || moa1.args.get(j).type.equals("null") ) || moa.args.get(j).type.equals(moa1.args.get(j).type)){
                i++;
            }
            else {
                return 0;
            }
        }
        int j =2;
        Node x = moa.reference.getParentNode();
        while ( j > 0  && x!=null  && ( x != moa1.reference) && (!(x instanceof ClassOrInterfaceDeclaration))){
            x = x.getParentNode();
            j--;
        }
        if (x == moa1.reference){
            i+=2;
        }
        j =2;
        x = moa1.reference.getParentNode();
        while ( j > 0   && x!=null  &&  ( x != moa.reference) && (!(x instanceof ClassOrInterfaceDeclaration))){
            x = x.getParentNode();
            j--;
        }
        if (x == moa.reference){
            i+=2;
        }
        return i;
    }


    private Set<MethodOfAPI> removeDuplicates(Set<MethodOfAPI> s ){
        Set<MethodOfAPI> newset = new HashSet<>();
        Iterator<MethodOfAPI> it = s.iterator();
        while (it.hasNext()) {
            MethodOfAPI moa = it.next();
            if (moa.method!=null && moa.method.startsWith(moa.returnType) && moa.referenceClass.equals(MethodOfAPI.unknownType)){
                // its a constructor, so belongs to the return type
                moa.referenceClass = moa.method;
                newset.add(moa);
            }
            if  (moa.returnType.equals(MethodOfAPI.unknownType)){
                if (! moa.referenceClass.equals(MethodOfAPI.unknownType)){
                    Object [] mm  = s.stream().filter(
                            m -> (!m.returnType.equals(MethodOfAPI.unknownType)) &&
                                    (!m.referenceClass.equals(MethodOfAPI.unknownType)) &&
                                    (!m.method.equals(MethodOfAPI.unknownType)) && moa.method.equals(m.method)).toArray();
                    if (mm.length>0){
                        newset.add(((MethodOfAPI) mm[0]));
                    }
                    else {
                        newset.add(moa);
                    }
                }
            }
            if  (moa.referenceClass.equals(MethodOfAPI.unknownType)){
                if (! moa.returnType.equals(MethodOfAPI.unknownType)){
                    Object [] mm  = s.stream().filter(
                            m -> (!m.returnType.equals(MethodOfAPI.unknownType)) &&
                                    (!m.referenceClass.equals(MethodOfAPI.unknownType)) &&
                                    (!m.method.equals(MethodOfAPI.unknownType)) && moa.method.equals(m.method)).toArray();
                    if (mm.length>0){
                        newset.add(((MethodOfAPI) mm[0]));
                    } else {
                        newset.add(moa);
                    }
                }else{
                    newset.add(moa );
                }
            }
            else {
                newset.add(moa);
            }


            /*Object [] mm = s.stream().filter(x -> getMatches(x, moa)> (4+moa.args.size()) ).toArray();
            Object [] real= s.stream().filter(
                    m -> (!m.returnType.equals(MethodOfAPI.unknownType)) &&
                            (!m.referenceClass.equals(MethodOfAPI.unknownType)) &&
                                (!m.method.equals(MethodOfAPI.unknownType))).toArray();
            if (real.length>0){
                newset.add(((MethodOfAPI) real[0]));
            }else{
                MethodOfAPI elrei= new MethodOfAPI();
                for( Object o : mm){
                    MethodOfAPI z = ((MethodOfAPI) o);
                    elrei.method=z.method.equals(MethodOfAPI.unknownType)? elrei.method : z.method;
                    elrei.returnType=z.returnType.equals(MethodOfAPI.unknownType)? elrei.returnType : z.returnType;
                    elrei.referenceClass=z.referenceClass.equals(MethodOfAPI.unknownType)? elrei.referenceClass : z.referenceClass;
                    elrei.reference=z.reference;
                    it.remove();
                }
                newset.add(elrei);
            }*/

        }
        return newset;
    }







}


