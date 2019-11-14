package AndroidProjectRepresentation;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class ProjectInfo implements Serializable, JSONSerializable{

    public String projectID = "unknown";
    public String projectBuildTool = "gradle";
    public String projectDescription = "";
    public String projectLocation = "";
    public List<AppInfo> apps = new ArrayList<>();
    public  Set<String> allPackagesOfProject = new HashSet<>();


    public ProjectInfo(){

    }

    public ProjectInfo(AppInfo app){
        this.apps.add(0,app);
    }



    public ProjectInfo(String projectID, String projectBuildTool, String projectDescription) {
        this.projectID = projectID;
        this.projectBuildTool = projectBuildTool;
        this.projectDescription = projectDescription;
    }


    /**
     * RETURNS the current app being processed. Only one supported for now
     * **/
    public AppInfo getCurrentApp (){

        try{
            return this.apps.get(0); // TODO replace by other mechanism
        }
        catch (IndexOutOfBoundsException e){

        }
        return new AppInfo();
    }

    public ClassInfo getClassOfMethod(String method_id){

        return new ClassInfo(""); //TODO
    }



    @Override
    public JSONObject toJSONObject(String requiredId) {

        JSONObject jo = new JSONObject();
        jo.put("project_id", this.projectID);
        jo.put("project_build_tool", this.projectBuildTool);
        jo.put("project_description", this.projectDescription);
        JSONArray packages = new JSONArray();
        for (String pack : this.allPackagesOfProject){
            JSONObject pa = new JSONObject();
            pa.put("package", pack);
            packages.add(pa);
        }
        jo.put("project_packages", packages);
        JSONArray apps = new JSONArray();
        for (AppInfo app : this.apps){
            apps.add(app.toJSONObject(this.projectID));
        }
        jo.put("project_apps", apps);
        return jo;
    }

    public static ProjectInfo getSimpleProjectJSON (JSONObject jo ){
        JSONObject pro = new JSONObject();
        pro.put("project_id", jo.get("project_id") );
        pro.put("project_build_tool", jo.get("project_build_tool") );
        pro.put("project_description", jo.get("project_description") );
        pro.put("project_location", jo.get("project_location"));
        return ((ProjectInfo) new ProjectInfo().fromJSONObject(pro));
    }

    @Override
    public JSONSerializable fromJSONObject(JSONObject jo) {

        ProjectInfo proj = new ProjectInfo();
        proj.projectID = ((String) jo.get("project_id"));
        proj.projectDescription = ((String) jo.get("project_description"));
        proj.projectLocation = ((String) jo.get("project_location"));
        proj.projectBuildTool = ((String) jo.get("project_build_tool"));
        try{
            JSONArray packages = ((JSONArray) jo.get("project_packages"));
            for (Object j : packages){
                JSONObject job = ((JSONObject) j);
                proj.allPackagesOfProject.add(((String) job.get("package")));
            }
        }catch (Exception e){
         //   e.printStackTrace();
        }
        try{
            JSONArray apps = ((JSONArray) jo.get("project_apps"));
            for (Object j : apps){
                JSONObject job = ((JSONObject) j);
                if (job.containsKey("app_id"))
                    proj.apps.add((AppInfo) new AppInfo().fromJSONObject(job));
            }
        }catch (Exception e){
         //   e.printStackTrace();
        }
        return proj;
    }

    @Override
    public JSONObject fromJSONFile(String pathToJSONFile) {
        JSONParser parser = new JSONParser();
        JSONObject ja = new JSONObject();
        try {
            Object obj = parser.parse(new FileReader(pathToJSONFile));
            JSONObject jsonObject = (JSONObject)obj;
            if (jsonObject.containsKey("project_id") && jsonObject.containsKey("project_packages") && jsonObject.containsKey("project_apps")) {
                return jsonObject;
            }
        } catch (FileNotFoundException var5) {
            //var5.printStackTrace();
        } catch (IOException var6) {
          //  var6.printStackTrace();
        } catch (org.json.simple.parser.ParseException var7) {
           // var7.printStackTrace();
        }

        return ja;
    }



}
