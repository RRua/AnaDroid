package AndroidProjectRepresentation;



import com.github.javaparser.ast.body.ModifierSet;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

import java.io.FileReader;
import java.io.Serializable;
import java.util.*;
import java.util.stream.Collectors;


public class ClassInfo extends CodeEntity implements Serializable, JSONSerializable {


    public Set<String> allModifiers = new HashSet<>();
    public Set<String> typeParams = new HashSet<>();
    public boolean isInterface = false;
    public boolean isFinal = false;
    public boolean isAbstract = false;
    public String accessModifier = "public"; //TODO
    public String classPackage = "";
    public String className = "";
    public String extendedClass = "";
    public String outClass = ""; // if is an inner class
    public Set<NameExpression> classImports = new HashSet<>();
    public Map<String, MethodInfo> classMethods = new HashMap<>();
    public Map<String, Variable> classVariables = new HashMap<>();
    public Set< String> parentClasses = new HashSet<>(); // extended and implemetned ifaces
    public Set< String> interfacesImplemented = new HashSet<>(); // map interface name -> full package definition
    public String appID="";

    @Override
    public int hashCode() {
        return this.className.hashCode();
    }


    public void setModifiers(int modifiers) {
        this.isAbstract = ModifierSet.isAbstract(modifiers);
        this.isFinal = ModifierSet.isFinal(modifiers);
        this.accessModifier = ModifierSet.isPublic(modifiers)? "public" : (ModifierSet.isProtected(modifiers)? "protected" : (ModifierSet.isPrivate(modifiers)? "private": "protected"));
    }

    public void setModifiers(List<String> modifiers) {
        modifiers.forEach( x ->  this.setModifier(x));
    }


    public void setModifier(String mod) {
        //this.accessModifier = ModifierSet.isPublic(modifiers)? "public" : (ModifierSet.isProtected(modifiers)? "protected" : (ModifierSet.isPrivate(modifiers)? "private": "protected"));
        if (mod.toLowerCase().equals("public")){
            this.accessModifier="public";
        }
        else if (mod.toLowerCase().equals("private")){
            this.accessModifier="private";
        }
        else if (mod.toLowerCase().equals("protected")){
            this.accessModifier="protected";
        }
        else {
            this.allModifiers.add(mod);
        }
    }



    public ClassInfo (String appID){
        super();
        this.appID = appID;
        this.allModifiers= new HashSet<>();
        this.outClass = "";
        this.extendedClass ="";
        this.classPackage="";
        this.className="";
    }


    /*
    public  static  ClassInfo fromKotlinClass(Node.Decl.Structured nds, String appID ){
        ClassInfo ci = new ClassInfo(appID);
        ci.setModifiers(( nds.component1().stream().map(x -> x.toString()).collect(Collectors.toList())));
        if(nds.getPrimaryConstructor()!=null ){
            nds.getPrimaryConstructor().component2().stream().map( x -> new Variable(x) ).forEach(x -> ci.classVariables.put(x.varName, x));
        }
        nds.component6().forEach(x -> ci.annotations.add(x.toString()));
        nds.getParents().forEach(x -> ci.parentClasses.add(APICallUtilKtln.typeInferer(x)));
        nds.getTypeParams().forEach(x -> ci.typeParams.add(x.toString()));
        ci.className =  nds.getName();
        return ci;
    }*/



    public static JSONObject getClassMetric (String classID, String metricName, Number value, String valueText){
        JSONObject jo = new JSONObject();
        jo.put("cm_class", classID);
        jo.put("cm_metric", metricName);
        jo.put("cm_value", value);
        jo.put("cm_value_text", valueText);
        return jo;
    }


    public JSONObject classInfoToJSON(String appID){

        JSONObject jo = new JSONObject();
        jo.put("class_id", this.getClassID());
        jo.put("class_app", appID);
        jo.put("class_is_interface", this.isInterface);
        jo.put("class_non_acc_mod", (this.isFinal? "final" : "" )+ (this.isAbstract? (GDConventions.fieldDelimiter +"abstract") : ""  ));
        jo.put("class_name", this.className);
        jo.put("class_outterclass", this.outClass);
        jo.put("class_package", this.classPackage);
        jo.put("class_superclass", this.extendedClass);
        jo.put("class_acc_modifier",this.accessModifier );
        JSONArray imports = new JSONArray();
        for (NameExpression ne : this.classImports){
            JSONObject jj = new JSONObject();
            //jj.put("import", ne.qualifier+"."+"name" );
            jj.put("import_name", ne.qualifier+"."+ ne.name);
            jj.put("import_class", this.getClassID());
            imports.add(jj);
        }
        jo.put("class_imports", imports);
        JSONArray methods = new JSONArray();
        for (MethodInfo mi : this.classMethods.values()){
            JSONObject m= mi.methodInfoToJSON(this.getClassID());
            methods.add(m);

        }
        jo.put("class_methods", methods);

        JSONArray vars = new JSONArray();
        for (Variable v : this.classVariables.values()){
            JSONObject var = new JSONObject();
            var.put("var_type", v.type);
            var.put("var_array", v.arrayCount);
            var.put("var_isStatic", v.isStatic);
            var.put("var_isFinal", v.isFinal);
            var.put("var_isVolatile", v.isVolatile);
            var.put("var_isTransient", v.isTransient);
            vars.add(var);
        }
        jo.put("class_vars", vars);
        String ifaces = "";
        for (String s : this.interfacesImplemented){
            ifaces+=s+GDConventions.fieldDelimiter;
        }
        jo.put("class_implemented_ifaces",ifaces );
        return jo;
    }


    public String getFullClassName(){
        String s = outClass.equals("") ? "" : (outClass + ".");
        return classPackage +"."+s + className;
    }

    public MethodInfo getMethod(String methodName){
        for (String s : this.classMethods.keySet()){
            if (s.contains(methodName)){
                MethodInfo m = this.classMethods.get(s);
                String mm =  methodName.replaceAll("\\(.*?\\)", "");
                String mic = m.methodName.replaceAll("\\(.*?\\)", "");
                if (m.getMethodID().contains(methodName)&& mm.equals(mic))
                    return m;
            }
        }
        return null;
    }



    protected String getSimpleClassID(){
        String s = outClass.equals("") ? "" : (outClass + ".");
        return  this.classPackage + "." +s + this.className ;
    }


    public String getClassID(){
        String s = outClass.equals("") ? "" : (outClass + ".");
        return this.appID + GDConventions.fieldDelimiter + this.classPackage + "." + s + this.className ;
    }


    @Override
    public JSONObject toJSONObject(String appID) {
        return classInfoToJSON(appID);
    }

    @Override
    public JSONSerializable fromJSONObject(JSONObject jo) {
        ClassInfo classe = new ClassInfo("");
        classe.appID = ((String) jo.get("class_app"));
        classe.className = ((String) jo.get("class_name"));
        classe.classPackage = ((String) jo.get("class_package"));
        classe.isInterface = ((boolean) jo.get("class_is_interface"));
        classe.isAbstract = ((String) jo.get("class_non_acc_mod")).contains("abstract");
        classe.isFinal = ((String) jo.get("class_non_acc_mod")).contains("final");
        classe.extendedClass = ((String) jo.get("class_superclass"));
        classe.accessModifier = ((String) jo.get("class_acc_modifier"));
        classe.outClass = ((String) jo.get("class_outterclass"));

        for (String  s:((String) jo.get("class_implemented_ifaces")).split( ""+GDConventions.fieldDelimiter)){
            classe.interfacesImplemented.add(s);
        }

        for (Object o : ((JSONArray) jo.get("class_imports"))){
            JSONObject job = ((JSONObject) o);
            if (job.containsKey("import_name")){
                String [] imp = ((String) job.get("import_name")).split("\\.");
                if (imp.length>1){
                    classe.classImports.add(new NameExpression( ((String) job.get("import_name")).replace("." + imp[imp.length-1], "") , imp[imp.length-1]));
                }

            }
        }

        if (jo.containsKey("class_methods")){
            JSONArray jj = ((JSONArray) jo.get("class_methods"));
            if (!jo.isEmpty()){
                for (Object o : jj){
                    JSONObject job = ((JSONObject) o);
                    if (job.containsKey("method_id")){
                        MethodInfo mi = new MethodInfo();
                        mi = ((MethodInfo) new MethodInfo().fromJSONObject(job));
                        mi.ci = classe;
                        classe.classMethods.put(mi.getMethodID(),mi );
                    }
                }
            }

        }

        if (jo.containsKey("class_vars")){
            JSONArray jj = ((JSONArray) jo.get("class_vars"));
            if (!jj.isEmpty()){
                for (Object o : jj){
                    JSONObject job = ((JSONObject) o);
                    if (job.containsKey("var_type")){
                        Variable v = ((Variable) new Variable().fromJSONObject(job));
                        classe.classVariables.put(v.varName, v);
                    }
                }
            }
        }


        return classe;

    }

    @Override
    public JSONObject fromJSONFile(String pathToJSONFile) {
        JSONParser parser = new JSONParser();
        JSONObject ja = new JSONObject();

        try {
            Object obj = parser.parse(new FileReader(pathToJSONFile));
            JSONObject jsonObject = (JSONObject)obj;
            if (jsonObject.containsKey("class_id")) {
                return jsonObject;
            }
        } catch (Exception var5) {
            var5.printStackTrace();
        }

        return ja;

    }

    @Override
    public boolean equals(Object obj) {
        if (obj==null)
            return false;
        ClassInfo ne = (ClassInfo) obj;
        // return this.type.equals(ne.type) && this.varName.equals(ne.varName);
        return this.classPackage.equals(ne.classPackage)  && ((this.extendedClass == null || ne.extendedClass == null) || this.extendedClass.equals(ne.extendedClass)) && this.className.equals(ne.className);
    }
}
