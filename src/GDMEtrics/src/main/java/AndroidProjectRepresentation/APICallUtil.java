

package AndroidProjectRepresentation;

import Metrics.APIEvaluator;
import Metrics.CyclomaticCalculator;
import Metrics.SourceCodeLineCounter;
import com.github.javaparser.JavaParser;
import com.github.javaparser.ParseException;
import com.github.javaparser.ast.CompilationUnit;
import com.github.javaparser.ast.ImportDeclaration;
import com.github.javaparser.ast.Node;
import com.github.javaparser.ast.body.*;
import com.github.javaparser.ast.expr.MethodCallExpr;
import com.github.javaparser.ast.expr.ObjectCreationExpr;
import com.github.javaparser.ast.expr.QualifiedNameExpr;
import com.github.javaparser.ast.stmt.ExpressionStmt;
import com.github.javaparser.ast.stmt.Statement;
import com.github.javaparser.ast.type.ClassOrInterfaceType;
import com.github.javaparser.ast.type.ReferenceType;
import com.github.javaparser.ast.visitor.VoidVisitorAdapter;
import org.json.simple.JSONObject;

import java.io.*;
import java.util.*;

public class APICallUtil extends VoidVisitorAdapter implements Serializable, JSONSerializable {

    public static ProjectInfo proj = new ProjectInfo();

    public static Map<String, ClassInfo> processedClasses = new HashMap<>();

    public APICallUtil() {
    }

    public APICallUtil(ProjectInfo pi) {
        this.proj = pi;
    }


    public void addClassToApp(String app, ClassInfo ci) {
        if (app == null || app == "") {
            proj.getCurrentApp().allJavaClasses.add(ci);
        }
    }

    private String metId(MethodDeclaration m) {
        return m.getModifiers() + m.getName() + (m.getParameters() != null ? m.getParameters().toString() : m.getModifiers());
    }

    private String metId(ConstructorDeclaration m) {
        return m.getModifiers() + m.getName() + (m.getParameters() != null ? m.getParameters().toString() : m.getModifiers());
    }



    public void processJavaFile(String javaFilePath) throws IOException, ParseException {

        File file = new File(javaFilePath);
        FileInputStream in = new FileInputStream(file);
        CompilationUnit cu;
        try {
            cu = JavaParser.parse(in, null, false);
        } finally {
            in.close();
        }
        for (Node n : cu.getChildrenNodes()) {
            if (n instanceof ClassOrInterfaceDeclaration) {
                this.visit(((ClassOrInterfaceDeclaration) n),cu);
            }
        }
        distributeMethods(cu);
    }



    private void distributeMethods(CompilationUnit cu){
        Map<String,MethodInfo> map =  new APIEvaluator().eval(cu);
        for (AppInfo a : this.proj.apps){
            for (ClassInfo c : a.allJavaClasses){
                for (MethodInfo m : c.classMethods.values()){
                    String metID = m.getMethodID();
                    if (map.containsKey(metID)){
                        m.unknownApi=map.get(metID).unknownApi;
                        m.declaredVars= map.get(metID).declaredVars;
                        m.args=map.get(metID).args;
                    }
                }
                MethodClassifier(c);
            }
        }
    }


    public static boolean hasMatchingBrackets(String s) {
        if (s == null) {
            return false;
        }
        int counter = 0;
        for (int i = 0; i < s.length(); i++) {
            if (s.charAt(i) == '(') {
                counter++;
            } else if (s.charAt(i) == ')') {
                if (counter == 0) {
                    return false;
                }
                counter--;
            }
        }
        return counter == 0;
    }

    private static boolean apimakesSense(String cl, String method) {
        if (!hasMatchingBrackets(cl) || !hasMatchingBrackets(method)) {
            return false;
        }

        return true;
    }

   /* private static void cleanAPI(ClassInfo ci) {
        for (MethodInfo m : ci.classMethods.values()) {
            Iterator<MethodOfAPI> it = m.externalApi.iterator();
            while (it.hasNext()) {
                MethodOfAPI ss = it.next();
                if (m.ci.classVariables.containsKey(ss.method) || m.isInDeclaredVars(ss.method)) {
                    ss.method = null;
                    it.remove();
                } else if (!apimakesSense(ss.referenceClass, ss.method)) {
                    it.remove();
                }

            }
            it = m.androidApi.iterator();
            while (it.hasNext()) {
                MethodOfAPI ss = it.next();
                if (m.ci.classVariables.containsKey(ss.method) || m.isInDeclaredVars(ss.method)) {
                    ss.method = null;
                    it.remove();
                } else if (!apimakesSense(ss.referenceClass, ss.method)) {
                    it.remove();
                }
            }
            it = m.javaApi.iterator();
            while (it.hasNext()) {
                MethodOfAPI ss = it.next();
                if (m.ci.classVariables.containsKey(ss.method) || m.isInDeclaredVars(ss.method)) {
                    ss.method = null;
                    it.remove();
                } else if (!apimakesSense(ss.referenceClass, ss.method)) {
                    it.remove();
                }
            }
        }
    }
*/

    private static void MethodClassifier(ClassInfo thisClass) {
        if (thisClass.classMethods.size() > 0) {
            for (MethodInfo m : thisClass.classMethods.values()) {
                Iterator<MethodOfAPI> it = m.unknownApi.iterator();
                while (it.hasNext()) {
                    MethodOfAPI ss = it.next();
                    String s = ss.referenceClass;
                    if (s == null || s.equals("")) {
                        it.remove();
                        continue;
                    }
                    String[] x = s.split("<|,");
                    boolean added = false;
                    if (x.length > 1) {
                        for (String st : x) {
                            st = st.replaceAll(">", "").replace(" ", "");

                            if (s.equals("super")) {
                                st = thisClass.extendedClass;
                            }

                            if (!isPrimitiveType(st)) {

                                if (isAndroidApi(st, thisClass)) {
                                    MethodOfAPI moa = new MethodOfAPI(getCorrespondantImport(st, thisClass).equals("") ? st : getCorrespondantImport(st, thisClass) + "." + st, ss.method, ss.args);
                                    m.androidApi.add(moa);
                                    added = true;

                                } else if (isJavaApi(st, thisClass)) {

                                    m.javaApi.add(new MethodOfAPI(getCorrespondantImport(st, thisClass).equals("") ? st : getCorrespondantImport(st, thisClass) + "." + st, ss.method, ss.args));
                                    added = true;

                                } else {

                                    m.externalApi.add(new MethodOfAPI(getCorrespondantImport(st, thisClass).equals("") ? st : getCorrespondantImport(st, thisClass) + "." + st, ss.method,ss.args));
                                    added = true;

                                }
                            }
                        }
                        if (added) {
                            added = false;
                            it.remove();
                        }
                    } else {

                        if (s.equals("super")) {
                            s = thisClass.extendedClass;
                        }

                        if (!isPrimitiveType(s)) {
                            if (isAndroidApi(s, thisClass)) {

                                m.androidApi.add(new MethodOfAPI(getCorrespondantImport(s, thisClass).equals("") ? s : getCorrespondantImport(s, thisClass) + "." + s, ss.method,ss.args));
                                it.remove();
                            } else if (isJavaApi(s, thisClass)) {

                                m.javaApi.add(new MethodOfAPI(getCorrespondantImport(s, thisClass).equals("") ? s : getCorrespondantImport(s, thisClass) + "." + s, ss.method,ss.args));
                                it.remove();
                            } else {

                                m.externalApi.add(new MethodOfAPI(getCorrespondantImport(s, thisClass).equals("") ? s : getCorrespondantImport(s, thisClass) + "." + s, ss.method,ss.args));
                                it.remove();
                            }
                        } else it.remove();
                    }
                }

            }
        }
    }


    private static boolean isJavaApi(String s, ClassInfo thisClass) {
        return getCorrespondantImport(s, thisClass).startsWith("java") || s.equals("Integer") || s.equals("Double") || s.equals("Byte") || s.equals("Short") || s.equals("Long") || s.equals("Float") || s.equals("Character") || s.equals("Boolean") || s.equals("String") || s.startsWith("System");
    }

    private static boolean isPrimitiveType(String s) {
        return s.equals("int") || s.equals("double") || s.equals("byte") || s.equals("short") || s.equals("long") || s.equals("float") || s.equals("char") || s.equals("boolean");
    }

    private static boolean isAndroidApi(String s, ClassInfo ci) {
        return getCorrespondantImport(s, ci).startsWith("android") || getCorrespondantImport(s, ci).startsWith("com.google.android") || getCorrespondantImport(s, ci).startsWith("org.apache.http") || getCorrespondantImport(s, ci).startsWith("org.xml") || getCorrespondantImport(s, ci).startsWith("org.w3c.dom") ||
                getCorrespondantImport(s, ci).startsWith("com.android.internal") || getCorrespondantImport(s, ci).startsWith("dalvik");

    }

    private static String getCorrespondantImport(String apiReference, ClassInfo ci) {
        String s = "";
        for (NameExpression importDec : ci.classImports) {
            if (importDec.name.equals(apiReference))
                return importDec.qualifier;
        }
        return s;
    }


    public static Set<String> getClassesUsed(MethodDeclaration md) {
        List<String> list = new ArrayList<>();
        for (Statement st : md.getBody().getStmts()) {
            if (st instanceof ExpressionStmt) {

                if (((ExpressionStmt) st).getExpression() instanceof MethodCallExpr) {

                    if (((MethodCallExpr) ((ExpressionStmt) st).getExpression()).getScope() != null)
                        list.add(((MethodCallExpr) ((ExpressionStmt) st).getExpression()).getScope().toString());
                }
            }
        }

        return new HashSet<>();

    }

    public MethodInfo getMethodOfClass(String method, String fullClassName) {
        MethodInfo m = new MethodInfo();
        for (ClassInfo ci : proj.getCurrentApp().allJavaClasses) {
            String z = ci.getFullClassName();
            if (ci.getFullClassName().equals(fullClassName)) {
                if (ci.getMethod(method) != null)
                    return ci.getMethod(method);
            }
        }
        return m;
    }


    public static void serializeAPICallUtil(APICallUtil acu, String path) {

        FileOutputStream fout = null;
        ObjectOutputStream oos = null;

        try {

            fout = new FileOutputStream(path);
            oos = new ObjectOutputStream(fout);
            oos.writeObject(acu);

        } catch (Exception ex) {

           // ex.printStackTrace();

        } finally {

            if (fout != null) {
                try {
                    fout.close();
                } catch (IOException e) {
                    //e.printStackTrace();
                }
            }

            if (oos != null) {
                try {
                    oos.close();
                } catch (IOException e) {
                   // e.printStackTrace();
                }
            }

        }
    }

    public static APICallUtil deserializeAPiCallUtil(String filename) {

        APICallUtil acu = null;

        FileInputStream fin = null;
        ObjectInputStream ois = null;

        try {

            fin = new FileInputStream(filename);
            ois = new ObjectInputStream(fin);
            acu = (APICallUtil) ois.readObject();

        } catch (Exception ex) {
            ex.printStackTrace();
        } finally {

            if (fin != null) {
                try {
                    fin.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }

            if (ois != null) {
                try {
                    ois.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }

        }

        return acu;

    }


    @Override
    public JSONObject toJSONObject(String requiredId) {
        return this.proj.toJSONObject(requiredId);
    }

    @Override
    public JSONSerializable fromJSONObject(JSONObject jo) {
        return new APICallUtil(((ProjectInfo) this.proj.fromJSONObject(jo)));
    }

    @Override
    public JSONObject fromJSONFile(String pathToJSONFile) {
        JSONObject jo = this.proj.fromJSONFile(pathToJSONFile);
        return jo;
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append(this.proj.toString());
        return sb.toString();
    }


    @Override
    public void visit(MethodDeclaration n, Object arg) {
        MethodInfo mi = new MethodInfo();
        if (n.getParameters() != null) {
            for (Parameter m : ((MethodDeclaration) n).getParameters()) {
                int isArray = (m.getType() instanceof ReferenceType) ? ((ReferenceType) m.getType()).getArrayCount() : 0;
                mi.args.add(new Variable(m.getId().getName(), m.getType().toStringWithoutComments(), isArray));
            }
        }


        mi.ci = processedClasses.get( String.valueOf( getRespectiveClass(n))) ;
        mi.methodName = n.getName();
        mi.setModifiers(n.getModifiers());
        mi.cyclomaticComplexity = CyclomaticCalculator.cyclomaticAndAPI(n,mi);
        try {
            mi.linesOfCode = n.getBody() != null ? SourceCodeLineCounter.getNumberOfLines(n.getBody().toStringWithoutComments()) - 2 : 0;
        } catch (IOException e) {
            e.printStackTrace();
        }
        mi.ci.classMethods.put(metId(n),mi);
        super.visit(n,arg);
    }

    private Node getRespectiveClass(Node n) {
        Node x = n.getParentNode();
        if (n instanceof MethodDeclaration && n.getParentNode() instanceof  ObjectCreationExpr){
            return ((ObjectCreationExpr) n.getParentNode());
        }
        while (x != null && (!(x instanceof ClassOrInterfaceDeclaration))) {
            x = x.getParentNode();
        }
        return ((ClassOrInterfaceDeclaration) x);
    }

    @Override
    public void visit(ObjectCreationExpr n, Object arg) {
        CompilationUnit cu = ((CompilationUnit) arg);
        if (n.getAnonymousClassBody()!=null){
            ClassInfo thisClass = new ClassInfo(proj.getCurrentApp().appID);
            thisClass.extendedClass = null;
            thisClass.outClass = ((ClassOrInterfaceDeclaration) getRespectiveClass(n.getParentNode())).getName();
            proj.allPackagesOfProject.add(cu.getPackage().getName().toString());
            thisClass.classPackage = cu.getPackage().getName().toString();
            thisClass.className = n.getType().toStringWithoutComments();
            thisClass.isInterface = false;
            thisClass.setModifiers(ModifierSet.PROTECTED);
            if (cu.getImports() != null) {
                for (ImportDeclaration id : cu.getImports()) {
                    NameExpression ne = new NameExpression(((QualifiedNameExpr) id.getName()).getQualifier().toString(), ((QualifiedNameExpr) id.getName()).getName());
                    thisClass.classImports.add(ne);
                }
            }
            for (Node x : n.getChildrenNodes()) {
                if (x instanceof FieldDeclaration) {
                    for (VariableDeclarator vd : ((FieldDeclaration) x).getVariables()) {
                        Variable cv = new Variable();
                        cv.arrayCount = vd.getId().getArrayCount();
                        cv.type = ((FieldDeclaration) x).getType().toString();
                        cv.varName = vd.getId().getName();
                        cv.setModifiers(((FieldDeclaration) x).getModifiers());
                        thisClass.classVariables.put(cv.varName, cv);
                    }
                }
            }
            this.proj.getCurrentApp().allJavaClasses.add(thisClass);
            processedClasses.put( String.valueOf(n.hashCode()) , thisClass);
        }
        super.visit(n,arg);
    }

    @Override
    public void visit(ClassOrInterfaceDeclaration n, Object arg) {
        CompilationUnit cu = ((CompilationUnit) arg);
        ClassInfo thisClass = new ClassInfo(proj.getCurrentApp().appID);
        thisClass.extendedClass = n.getExtends() == null ? null : n.getExtends().get(0).getName();
        proj.allPackagesOfProject.add(cu.getPackage().getName().toString());
        thisClass.classPackage = cu.getPackage().getName().toString();
        thisClass.className = n.getName();
        thisClass.isInterface = n.isInterface();
        thisClass.setModifiers(n.getModifiers());
        if (cu.getImports() != null) {
            for (ImportDeclaration id : cu.getImports()) {
                NameExpression ne = new NameExpression(((QualifiedNameExpr) id.getName()).getQualifier().toString(), ((QualifiedNameExpr) id.getName()).getName());
                thisClass.classImports.add(ne);
            }
        }
        if (n.getImplements() != null) {
            String ifaceDef = "";
            for (ClassOrInterfaceType cit : n.getImplements()) {
                if (cit.getScope() != null) {
                    ifaceDef = getCorrespondantImport(cit.getScope().toStringWithoutComments(), thisClass);
                }
                thisClass.interfacesImplemented.add(ifaceDef + "." + cit.getName());
            }
        }
        for (Node x : n.getChildrenNodes()) {
            if (x instanceof FieldDeclaration) {
                for (VariableDeclarator vd : ((FieldDeclaration) x).getVariables()) {
                    Variable cv = new Variable();
                    cv.arrayCount = vd.getId().getArrayCount();
                    cv.type = ((FieldDeclaration) x).getType().toString();
                    cv.varName = vd.getId().getName();
                    cv.setModifiers(((FieldDeclaration) x).getModifiers());
                    thisClass.classVariables.put(cv.varName, cv);
                }
            }
        }
        this.proj.getCurrentApp().allJavaClasses.add(thisClass);
        processedClasses.put(String.valueOf(n.hashCode()), thisClass);
        super.visit(n,arg);
    }

    /*
    * mvn install:install-file -DgroupId=com.greenlab -DartifactId=Metrics -Dversion=1.0 -Dpackaging=jar -Dfile=target/Metrics-1.0-SNAPSHOT.jar
    *
    *
    * */
}