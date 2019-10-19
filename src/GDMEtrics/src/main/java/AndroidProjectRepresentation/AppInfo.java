package AndroidProjectRepresentation;



import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

import java.io.FileReader;
import java.io.Serializable;
import java.util.HashSet;
import java.util.Set;

public class AppInfo implements Serializable, JSONSerializable {


    public String appID="unknown";
    //public String appLocation="/unknown";
    public String appDescription="";
    public String appPackage="";
    public String appVersion="0.0";
    public String appFlavor="demo"; // demo or full -> https://developer.android.com/studio/build/build-variants
    public String buildType="release"; // debug or release -> https://developer.android.com/studio/build/build-variants
    public Set<String> permissions = new HashSet<>();
    public  Set<ClassInfo> allJavaClasses = new HashSet<>();



    public AppInfo (){
        this.appVersion = "0.0";
        this.appFlavor = "unknown";
        this.buildType = "unknown";
    }

    public String getAppInfoID (String projID ){
        String id =    GDConventions.fieldDelimiter + "V"+GDConventions.fieldDelimiter2+ String.valueOf(appVersion).replaceAll(".|,","") + GDConventions.fieldDelimiter +"Flavor"+GDConventions.fieldDelimiter2 + appFlavor + GDConventions.fieldDelimiter +"BuildType"+GDConventions.fieldDelimiter2  + buildType;
        return appID + GDConventions.fieldDelimiter + id.hashCode();
    }

    public AppInfo(String appID, String appDescription, String appVersion, String appFlavor, String buildType, String appPackage) {
        this.appID = appID;
        //this.appLocation = appLocation;
        this.appDescription = appDescription;
        this.appVersion = appVersion;
        this.appFlavor = appFlavor.equals("")? "demo" : appFlavor;
        this.buildType = buildType.equals("")? "debug" : appFlavor;
        this.appPackage = appPackage;
    }






    @Override
    public JSONObject toJSONObject(String projectID) {
        JSONObject jo = new JSONObject();
        jo.put("app_project", projectID);
        jo.put("app_id", this.getAppInfoID(projectID));
        //jo.put("app_location", this.appLocation);
        jo.put("app_description", this.appDescription);
        jo.put("app_version", this.appVersion);
        jo.put("app_flavor", this.appFlavor);
        jo.put("app_build_type", this.buildType);
        jo.put("app_package", this.appPackage);

        JSONArray classes = new JSONArray();
        for (ClassInfo classe : this.allJavaClasses){
            classes.add(classe.toJSONObject(this.appID));
        }
        jo.put("app_classes", classes);

        JSONArray permissions = new JSONArray();
        for (String perm : this.permissions){
            JSONObject pe = new JSONObject();
            pe.put("permission", perm);
            permissions.add(pe);
        }
        jo.put("app_permissions", permissions);


        return jo;
    }

    @Override
    public JSONSerializable fromJSONObject(JSONObject jo) {

        AppInfo app = new AppInfo();
        app.appID = ((String) jo.get("app_id")).split("\\"+GDConventions.fieldDelimiter)[0];
        //app.appLocation = ((String) jo.get("app_location"));
        app.appDescription = ((String) jo.get("app_description"));
        try {
            app.appVersion = (String) jo.get("app_version");
        }
        catch (ClassCastException cce){
            app.appVersion = ((String) jo.get("app_version"));
        }
       // app.appVersion = Double.parseDouble(((String) jo.get("app_version")));
        app.appPackage = ((String) jo.get("app_package"));
        app.appFlavor = ((String) jo.get("app_flavor"));
        app.buildType = ((String) jo.get("app_build_type"));
        JSONArray permissions = new JSONArray(), classes = new JSONArray();
        try{
            if (jo.containsKey("app_permissions")){
                permissions = ((JSONArray) jo.get("app_permissions"));
                for (Object j : permissions){
                    JSONObject job = ((JSONObject) j);
                    app.permissions.add(((String) job.get("permission")));
                }
            }
        }catch (Exception e){
            e.printStackTrace();

        }
        try{
            if (jo.containsKey("app_classes")){
                classes = ((JSONArray) jo.get("app_classes"));
                if (!classes.isEmpty()){
                    for (Object j : classes){
                        JSONObject job = ((JSONObject) j);
                        app.allJavaClasses.add(((ClassInfo) new ClassInfo(appID).fromJSONObject(job)));
                    }
                }
            }

        }catch (Exception e){
            e.printStackTrace();
        }

        return app;

    }

    @Override
    public JSONObject fromJSONFile(String pathToJSON) {
        JSONParser parser = new JSONParser();
        JSONObject ja = new JSONObject();

        try {
            Object obj = parser.parse(new FileReader(pathToJSON));
            JSONObject jsonObject = (JSONObject)obj;
            if (jsonObject.containsKey("app_id")) {
                return jsonObject;
            }
        } catch (Exception var5) {
            var5.printStackTrace();
        }

        return ja;
    }

    @Override
    public String toString() {
        return "AppInfo{" +
                "appID='" + appID + '\'' +
               // ", appLocation='" + appLocation + '\'' +
                ", appPackage ='" + appPackage + '\'' +
                ", appDescription='" + appDescription + '\'' +
                ", appVersion=" + appVersion +
                ", appFlavor='" + appFlavor + '\'' +
                ", buildType='" + buildType + '\'' +
                ", permissions=" + permissions +
                ", allJavaClasses=" + allJavaClasses +
                '}';
    }




    public ClassInfo getClass(ClassInfo ci){
        for (ClassInfo c : this.allJavaClasses){
            if (c.equals(ci)){
                return c;
            }
        }
        return null;
    }
}
