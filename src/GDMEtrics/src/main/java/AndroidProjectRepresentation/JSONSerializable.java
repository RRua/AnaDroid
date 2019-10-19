package AndroidProjectRepresentation;

import org.json.simple.JSONObject;

public interface JSONSerializable {



     JSONObject toJSONObject(String requiredId ); // Tranforms the object in a JSONObject
     JSONSerializable fromJSONObject(JSONObject jo ); // Transnforms the JSONObject in the object
     JSONObject fromJSONFile( String pathToJSONFile ); // Parse and validate the json object representation
}
