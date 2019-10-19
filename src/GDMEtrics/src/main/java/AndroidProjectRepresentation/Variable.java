package AndroidProjectRepresentation;


import Metrics.APIEvaluator;
import com.github.javaparser.ast.body.ModifierSet;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

import java.io.FileReader;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class Variable  extends CodeEntity implements Serializable, JSONSerializable{

    public  String   type = "";
    public String varName = "";
    public boolean isStatic = false;
    public int arrayCount =    0;
    public boolean isFinal = false;
    public boolean isVolatile = false;
    public boolean isTransient = false;
    public int uuid = 0;
    public String accessModifier = "";
    public List<String> modifiers = new ArrayList();

    public void setModifiers(int modifiers) {
        this.isStatic = ModifierSet.isStatic(modifiers);
        this.isTransient = ModifierSet.isTransient(modifiers);
        this.isFinal = ModifierSet.isFinal(modifiers);
        this.isVolatile = ModifierSet.isVolatile(modifiers);
        this.accessModifier = ModifierSet.isPublic(modifiers)? "public" : (ModifierSet.isProtected(modifiers)? "protected" : (ModifierSet.isPrivate(modifiers)? "private": ""));
    }

    @Override
    public String toString() {
        return "Variable{" +
                "type='" + type + '\'' +
                ", varName='" + varName + '\'' +
                ", isStatic=" + isStatic +
                ", arrayCount=" + arrayCount +
                ", isFinal=" + isFinal +
                ", isVolatile=" + isVolatile +
                ", isTransient=" + isTransient +
                ", accessModifier='" + accessModifier + '\'' +
                '}';
    }

    public Variable(String varName, String type) {
        super();
        this.type = type;
        this.varName = varName;

    }

    public Variable(String varName, String type, int arrayCount) {
        super();
        this.type = type;
        this.varName = varName;
        this.arrayCount = arrayCount;
    }

    public Variable( String type) {
        super();
        this.type = type;
        this.varName = "x";
        this.arrayCount = arrayCount;
    }

    public Variable() {
        super();
        type = "";
        varName = "";
    }
/*
    public  Variable (Node.Decl.Func.Param param){
         this.varName = param.getName();
         this.type = APICallUtilKtln.typeInferer(param.getType());
    }


    public static List<Variable> fromProperty(Node.Decl.Property property){
        List<Variable> l = new ArrayList<>();
        APICallUtilKtln apuk = new APICallUtilKtln();
        for ( Node.Decl.Property.Var v : property.getVars() ){
            Variable var = new Variable();
            var.varName = v.getName();
            property.getAnns().forEach(x -> var.annotations.add(x.toString()));
            property.getMods().forEach( x -> var.modifiers.add( apuk.getModifier( x) ) ) ;
            var.isFinal=property.getReadOnly();
            if (v.getType()!=null){
                var.type = apuk.typeInferer(v.getType());
            }
            else {
                var.type = apuk.typeInferer(property.getExpr());
            }
            if (var.type.equals("")){
                if (property.getExpr() instanceof Node.Expr.BinaryOp ){

                }
                if (var.type.equals("")){
                    var.type = MethodOfAPI.unknownType;
                }
            }
            l.add(var);
        }
        return l;
    }*/


    @Override
    public boolean equals(Object obj) {
        if (obj==null)
            return false;
        Variable ne = (Variable) obj;
       // return this.type.equals(ne.type) && this.varName.equals(ne.varName);
        return (this.varName.equals("")? true: this.varName.equals(ne.varName)) && (this.type.equals("")? true : this.type.equals(ne.type));
    }

    @Override
    public int hashCode() {
        return this.varName.hashCode() +  new Integer(uuid).hashCode();
    }

    @Override
    public JSONObject toJSONObject(String requiredId) {
        JSONObject jo = new JSONObject();
        jo.put("var_type", type);
        jo.put("var_name", varName);
        jo.put("var_arraycount", arrayCount);
        return jo;
    }

    @Override
    public JSONSerializable fromJSONObject(JSONObject jo) {
        Variable v = new Variable();
        v.type = ((String) jo.get("var_type"));
        v.varName = ((String) jo.get("var_name"));
        v.arrayCount =  jo.get("var_is_array") != null ? Integer.parseInt(((String) jo.get("var_is_array"))) : 0 ;
        return v;
    }
    public  static Variable fromJSONString(String representation){
        Variable v = new Variable();
        String [] x = representation.split(GDConventions.fieldDelimiter);
        for (String s : x){
            v.type=s.replaceAll("\\[|\\]","");
            v.arrayCount= s.contains("[")? 1:0;
        }
        return v;
    }

    @Override
    public JSONObject fromJSONFile(String pathToJSONFile) {
        JSONParser parser = new JSONParser();
        JSONObject ja = new JSONObject();

        try {
            Object obj = parser.parse(new FileReader(pathToJSONFile));
            JSONObject jsonObject = (JSONObject)obj;
            if (jsonObject.containsKey("var_type")) {
                return jsonObject;
            }
        } catch (Exception var5) {
            var5.printStackTrace();
        }

        return ja;

    }
}
