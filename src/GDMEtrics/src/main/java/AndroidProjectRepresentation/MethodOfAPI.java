package AndroidProjectRepresentation;


import com.github.javaparser.ast.Node;
import com.github.javaparser.ast.expr.Expression;
import com.github.javaparser.ast.expr.MethodCallExpr;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class  MethodOfAPI extends CodeEntity implements Serializable {

    public  static final String unknownType = "UnknownType";
    public String referenceClass = unknownType;
    public String returnType  = unknownType;
    public String method = unknownType;
    public List<Variable> args = new ArrayList<>();
    public Expression reference = new MethodCallExpr();


    public MethodOfAPI(String apis, String met, List<Variable> args) {
        super();
        this.referenceClass = apis;
        this.method = met;
        this.returnType = unknownType;
        this.args = args;
        reference = new MethodCallExpr();
    }


    public MethodOfAPI(String referenceClass ) {
        super();
        this.referenceClass = referenceClass;
        this.returnType = unknownType;
        args = new ArrayList<>();
        reference = new MethodCallExpr();
    }

    public MethodOfAPI( ) {
        super();
        this.referenceClass = unknownType;
        this.returnType = unknownType;
        args = new ArrayList<>();
        reference = new MethodCallExpr();
    }

    @Override
    public boolean equals(Object obj) {
        if (obj==null)
            return false;
        MethodOfAPI ne = (MethodOfAPI) obj;
        return  this.returnType.equals(ne.returnType) && this.referenceClass.equals(ne.referenceClass) && ((this.method == null || ((MethodOfAPI) obj).method == null) || this.method.equals(ne.method));
    }

    /*
    * return type__class__args(--a,--b)
    * */
    public String toJSONString (){
        String api = this.returnType + GDConventions.fieldDelimiter2  +this.referenceClass + GDConventions.fieldDelimiter2   + this.method + GDConventions.fieldDelimiter2 +"(";
        for (Variable v : this.args){
            api+= GDConventions.fieldDelimiter + v.type +( v.arrayCount>0?"[]":"") ;
        }
        return  api+")";
    }

    public  static MethodOfAPI fromJSONString (String representation){
        MethodOfAPI moa = new MethodOfAPI();
        String [] x = representation.split(GDConventions.fieldDelimiter2);
        if (x.length>=3){
            moa.returnType=x[0];
            moa.referenceClass = x[1];
            moa.method=x[2];
            String [] args =x[3].substring(x[3].indexOf("(")+1,x[3].indexOf(")")).split( GDConventions.fieldDelimiter);
            for ( String arg : args ){
                if ( ! arg.equals("")){
                    moa.args.add( Variable.fromJSONString(arg));
                }
            }
        }
        return moa;
    }




    @Override
    public int hashCode() {
        return this.referenceClass!=null? this.referenceClass.hashCode() + ( this.method!=null? this.method.hashCode() : 0) : ( this.method!=null? this.method.hashCode() : 0);
    }

    @Override
    public String toString() {
        String s = this.returnType + " Class " + this.referenceClass + " Method " + this.method;
        s+="(";
        for (int i = 0; i < this.args.size(); i++) {
            s+= this.args.get(i).type ;
            if (i+1!=this.args.size()){
                s+=",";
            }
        }
        return s+")";
    }
}
