package AndroidProjectRepresentation;


import java.io.Serializable;

public class NameExpression implements Serializable {
    public String qualifier = "";
    public String name = "";


    public NameExpression(String qualifier, String name) {
        this.qualifier = qualifier;
        this.name = name;
    }

    @Override
    public boolean equals(Object obj) {
        if (obj==null)
            return false;
        NameExpression ne = (NameExpression) obj;
        return this.qualifier.equals(ne.qualifier) && this.name.equals(ne.name);
    }
}
