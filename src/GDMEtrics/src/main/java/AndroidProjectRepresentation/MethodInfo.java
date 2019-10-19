package AndroidProjectRepresentation;




import Metrics.CyclomaticCalculator;
import Metrics.SourceCodeLineCounter;
import com.github.javaparser.ast.body.*;
import com.github.javaparser.ast.type.ReferenceType;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

import java.io.FileReader;
import java.io.IOException;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;


public class MethodInfo extends CodeEntity implements Serializable, JSONSerializable {

    public Set<MethodOfAPI> externalApi = new HashSet<>();
    public Set<MethodOfAPI> androidApi = new HashSet<>();
    public Set<MethodOfAPI> javaApi = new HashSet<>();
    public Set<MethodOfAPI> unknownApi = new HashSet<>();
    public Set<String> modifiers = new HashSet<>();
    public Set<Variable> declaredVars = new HashSet<>();
    public Set<Variable> args = new HashSet<Variable>();
    public String returnType="";
    public boolean isStatic = false;
    public boolean isSynchronized = false;
    public boolean isFinal = false;
    public int linesOfCode = 0;
    public int cyclomaticComplexity = 0;
    public String accessModifier = "public";
    public String methodName = "";
    public ClassInfo ci = null;


    public MethodInfo() {
        super();
    }
    public MethodInfo(MethodDeclaration n) {
        super();
        this.methodName= n.getName();
        if (n.getParameters() != null) {
            for (Parameter m : ((MethodDeclaration) n).getParameters()) {
                int isArray = (m.getType() instanceof ReferenceType) ? ((ReferenceType) m.getType()).getArrayCount() : 0;
                this.args.add(new Variable(m.getId().getName(), m.getType().toStringWithoutComments(), isArray));
            }
        }
        this.setModifiers(n.getModifiers());
        this.cyclomaticComplexity = CyclomaticCalculator.cyclomaticAndAPI(n,this);
        try {
            this.linesOfCode = SourceCodeLineCounter.getNumberOfLines(((MethodDeclaration) n).getBody().toStringWithoutComments()) - 2 ;
        } catch (IOException e) {
            e.printStackTrace();
        }

    }
    public static String idFromMethodDeclaration(MethodDeclaration n ,String outterClassName,String parentClassName, String pack, String hash ){

        String metId=  pack + "." +(outterClassName.equals("")?  "" : outterClassName+".") + parentClassName +"->"+n.getName()+ "|"+ hash;
        /*
        metId +="(";
        Set<Variable> args = new HashSet<>();
        if (n.getParameters()!=null){
            for (Parameter m : ((MethodDeclaration) n).getParameters()) {
                int isArray = (m.getType() instanceof ReferenceType)? ((ReferenceType) m.getType()).getArrayCount() :0;
                args.add(new Variable(m.getId().getName(), m.getType().toStringWithoutComments(), isArray));
            }
        }
        for (Variable v : args) {
            metId += GDConventions.fieldDelimiter + v.type;
        }
        metId +=")";
        //metId += ".";*/
        return metId;

    }
    public static String idFromConstructorDeclaration(ConstructorDeclaration n ,String outterClassName,String parentClassName, String pack, String hash ){
        String out= "";
        String metId=  pack + "." +(outterClassName.equals("")?  "" : outterClassName+".") + parentClassName+"-><init>"+ "|"+ hash;
        /*
        metId +="(";
        Set<Variable> args = new HashSet<>();

        if (n.getParameters()!=null){
            for (Parameter m : ((ConstructorDeclaration) n).getParameters()) {
                int isArray = (m.getType() instanceof ReferenceType)? ((ReferenceType) m.getType()).getArrayCount():0;
                args.add(new Variable(m.getId().getName(), m.getType().toStringWithoutComments(), isArray));
            }
        }

        for (Variable v : args) {
            metId += GDConventions.fieldDelimiter + v.type;
        }*/
       // metId +=")";
        //metId += ".";
        return metId;

    }

    /*
    public static MethodInfo fromKotlinFun (Node.Decl.Func node, String s){
        MethodInfo mi = new MethodInfo();
        mi.methodName = node.getName();
        mi.returnType=   node.getType()!=null ? APICallUtilKtln.typeInferer(node.getType()) : "Unit"  ;
        node.component1().forEach(x -> mi.modifiers.add(x.toString()));
        node.getParams().forEach( x -> mi.args.add(  new Variable(x) ));
        return mi;
    }

    public static MethodInfo fromKotlinFun (Node.Decl.Constructor node, String name){
        MethodInfo mi = new MethodInfo();
        mi.methodName = name;
        mi.returnType=name;
        node.component1().forEach(x -> mi.modifiers.add(x.toString()));
        node.getParams().forEach( x -> mi.args.add(  new Variable(x) ));
        return mi;
    }*/




    public static JSONObject getMethodMetric (String methodId, String metricName, Number value, String valueText, String methodInvokedId){
        JSONObject jo = new JSONObject();
        jo.put("mm_method", methodId);
        jo.put("mm_metric", metricName);
        jo.put("mm_value", value);
        jo.put("mm_value_text", valueText);
        if (methodInvokedId!=null )
            jo.put("mm_method_invoked", methodInvokedId);
        return jo;
    }

    public JSONObject methodInfoToJSON (String classID){
        JSONObject method = new JSONObject();
        method.put("method_id", this.getMethodID());
        method.put("method_name", this.methodName);
        method.put("method_non_acc_mod",  (this.isSynchronized? (GDConventions.fieldDelimiter+"synchronized") : "" )+ (this.isFinal? (GDConventions.fieldDelimiter+"final") : "" )+ (this.isStatic? (GDConventions.fieldDelimiter+"static") : ""  ));
        method.put("method_acc_modifier", this.accessModifier);
        method.put("method_class", classID);
        JSONArray methodMetrics = new JSONArray();
        methodMetrics.add(getMethodMetric(this.getMethodID(),"loc", this.linesOfCode, "",null));
        methodMetrics.add(getMethodMetric(this.getMethodID(),"cc", this.cyclomaticComplexity, "",null));
        methodMetrics.add(getMethodMetric(this.getMethodID(),"nr_args", this.args.size(), "",null));
        for (MethodOfAPI moa : this.externalApi){
            String api = moa.toJSONString();
            JSONObject metric = getMethodMetric( this.getMethodID(),"externalapi", 0, api , null);
            methodMetrics.add(metric);
        }
        for (MethodOfAPI moa : this.androidApi){
            String api = moa.toJSONString();
            JSONObject metric = getMethodMetric( this.getMethodID(),"androidapi", 0, api , null);
            methodMetrics.add(metric);
        }
        for (MethodOfAPI moa : this.javaApi){
            String api = moa.toJSONString();
            JSONObject metric = getMethodMetric( this.getMethodID(),"javaapi", 0, api , null);
            methodMetrics.add(metric);

        }
        method.put("method_metrics", methodMetrics);
        JSONArray vars = new JSONArray();
        for (Variable v : this.declaredVars){
            vars.add(v.toJSONObject(""));
        }
        method.put("method_declared_vars", vars);

        JSONArray args = new JSONArray();
        for (Variable v : this.args){
            args.add(v.toJSONObject(""));
        }
        method.put("method_args", args);
        return method;
    }

    public  String getMethodID() {
        String metId= this.ci!=null ?  this.ci.getSimpleClassID() + "." + this.methodName : this.methodName ;
        metId +="(";
        for (Variable v : args) {
            metId += GDConventions.fieldDelimiter + v.type;
        }
        metId +=")";
        return metId;
    }


    public boolean isInArgs(String varName){
        if (varName==null)
            return false ;
        for (Variable v : this.args){
            if(v==null)
                continue;
            if(v.varName==null)
                continue;
            if (varName.equals(v.varName)){
                return true;
            }
        }
        return false;
    }

    public  boolean isInDeclaredVars(String var){
        if (var==null)
            return false ;
        for (Variable v : this.declaredVars){
            if(v==null)
                continue;
            if(v.varName==null)
                continue;
            if (var.equals(v.varName)){
                return true;
            }
        }
        return false;
    }

    @Override
    public int hashCode() {
        return this.methodName.hashCode() + new Integer(this.args.size()).hashCode();
    }

    // Add correct
    public void addRespectiveAPI(MethodOfAPI x){
        if (!this.declaredVars.contains(new Variable(x.referenceClass,""))){
            if(this.ci.classVariables.containsKey(x.referenceClass)){
                this.unknownApi.add(new MethodOfAPI(this.ci.classVariables.get(x.referenceClass).type,x.method, x.args));
                return;
            }
            else {
                for (Variable v : this.args){
                    if (v.varName.equals(x.referenceClass)){
                        this.unknownApi.add(new MethodOfAPI(v.type,x.method,x.args));
                        return;
                    }

                }
            }
        }
        else {
            for (Variable v : this.declaredVars){
                if (v.varName.equals(x.referenceClass)){
                    this.unknownApi.add(new MethodOfAPI(v.type,x.method,x.args));
                    return;
                }

            }
        }

        this.unknownApi.add(x);

    }


    public Set<String> getApisUsed(){
        Set <String> l = new HashSet<>();
        for (MethodOfAPI s : this.androidApi) {
            l.add(s.referenceClass);
        }
        for (MethodOfAPI s : this.javaApi) {
            l.add(s.referenceClass);
        }
        for (MethodOfAPI s : this.externalApi) {
            l.add(s.referenceClass);
        }
        return l;
    }

    @Override
    public JSONObject toJSONObject(String classID) {
        return this.methodInfoToJSON(classID);
    }

    @Override
    public JSONSerializable fromJSONObject(JSONObject jo) {
        MethodInfo mi = new MethodInfo();
        mi.methodName = (String)jo.get("method_name");
        if (jo.containsKey("method_non_acc_mod") && jo.get("method_non_acc_mod") != null) {
            mi.isFinal = ((String)jo.get("method_non_acc_mod")).contains("final");
            mi.isSynchronized = ((String)jo.get("method_non_acc_mod")).contains("ynchronized");
            mi.isStatic = ((String)jo.get("method_non_acc_mod")).contains("static");
        }

        mi.accessModifier = (String)jo.get("method_acc_modifier");
        JSONArray methodMetrics;
        Iterator var4;
        Object ob;
        JSONObject metric;
        Variable v;
        if (jo.containsKey("method_declared_vars")) {
            methodMetrics = (JSONArray)jo.get("method_declared_vars");
            if (!methodMetrics.isEmpty()) {
                var4 = methodMetrics.iterator();

                while(var4.hasNext()) {
                    ob = var4.next();
                    metric = (JSONObject)ob;
                    if (metric.containsKey("var_type")) {
                        v = (Variable)(new Variable()).fromJSONObject(metric);
                        mi.declaredVars.add(v);
                    }
                }
            }
        }

        String metricName;
        if (jo.containsKey("method_args")) {
           JSONArray args = (JSONArray)jo.get("method_args");
           for (Object o : args){
               mi.args.add(((Variable) new Variable().fromJSONObject(((JSONObject) o))));
           }
        }
        if (jo.containsKey("method_metrics")) {
            methodMetrics = (JSONArray)jo.get("method_metrics");
            if (!methodMetrics.isEmpty()) {
                for (Object o : methodMetrics) {
                    JSONObject mt = (JSONObject) o;
                    if (((JSONObject) o).containsKey("mm_metric")) {
                        if (((JSONObject) o).get("mm_metric").equals("loc")) {
                            try {
                                mi.linesOfCode = ((Integer) ((JSONObject) o).get("mm_value")).intValue();
                            }
                            catch (ClassCastException e){
                                mi.linesOfCode = ((Long) ((JSONObject) o).get("mm_value")).intValue();
                            }

                        }
                        if (((JSONObject) o).get("mm_metric").equals("cc")) {
                            try {
                                mi.cyclomaticComplexity = ((Integer) ((JSONObject) o).get("mm_value")).intValue();
                            }
                            catch (ClassCastException e){
                                mi.cyclomaticComplexity = ((Long) ((JSONObject) o).get("mm_value")).intValue();
                            }
                        }
                        if (((JSONObject) o).get("mm_metric").equals("androidapi")) {
                            String apis = (String) ((JSONObject) o).get("mm_value_text");
                            String x= "\\"+GDConventions.fieldDelimiter2;
                            String[] splits = apis.split(x);
                            if (splits.length > 2) {
                                MethodOfAPI moa = new MethodOfAPI().fromJSONString(apis);
                                mi.androidApi.add( moa);
                            }
                        }
                        if (((JSONObject) o).get("mm_metric").equals("javaapi")) {
                            String apis = (String) ((JSONObject) o).get("mm_value_text");
                            String x= "\\"+GDConventions.fieldDelimiter2;
                            String[] splits = apis.split(x);
                            if (splits.length > 2) {
                                MethodOfAPI moa = new MethodOfAPI().fromJSONString(apis);
                                mi.javaApi.add( moa);
                            }
                        }
                        if (((JSONObject) o).get("mm_metric").equals("externalapi")) {
                            String apis = (String) ((JSONObject) o).get("mm_value_text");
                            String x= "\\"+GDConventions.fieldDelimiter2;
                            String[] splits = apis.split(x);
                            if (splits.length > 2) {
                                MethodOfAPI moa = new MethodOfAPI().fromJSONString(apis);
                                mi.externalApi.add( moa);
                            }
                        }


                    }

                }


            }

        }


        return mi;
    }

    @Override
    public JSONObject fromJSONFile(String pathToJSONFile) {
        JSONParser parser = new JSONParser();
        JSONObject ja = new JSONObject();

        try {
            Object obj = parser.parse(new FileReader(pathToJSONFile));
            JSONObject jsonObject = (JSONObject)obj;
            if (jsonObject.containsKey("method_id")) {
                return jsonObject;
            }
        } catch (Exception var5) {
            var5.printStackTrace();
        }

        return ja;
    }

    public void setModifiers(int modifiers) {
        this.isStatic = ModifierSet.isStatic(modifiers);
        this.isSynchronized = ModifierSet.isSynchronized(modifiers);
        this.isFinal = ModifierSet.isFinal(modifiers);
        this.accessModifier = ModifierSet.isPublic(modifiers)? "public" : (ModifierSet.isProtected(modifiers)? "protected" : (ModifierSet.isPrivate(modifiers)? "private": ""));
    }


    public boolean equals(Object obj) {
        if (obj==null)
            return false;
        if (this==obj){
            return true;
        }
        MethodInfo ne = (MethodInfo) obj;
        return ne.getMethodID().equals(ne.getMethodID());
    }

    @Override
    public String toString() {
        return "MethodInfo{" +
                "externalApi=" + externalApi +
                ", androidApi=" + androidApi +
                ", javaApi=" + javaApi +
                ", unknownApi=" + unknownApi +
                ", declaredVars=" + declaredVars +
                ", args=" + args +
                ", isStatic=" + isStatic +
                ", isSynchronized=" + isSynchronized +
                ", isFinal=" + isFinal +
                ", linesOfCode=" + linesOfCode +
                ", cyclomaticComplexity=" + cyclomaticComplexity +
                ", accessModifier='" + accessModifier + '\'' +
                ", methodName='" + methodName + '\'' +
                ", ci=" + ci +
                '}';
    }
}
