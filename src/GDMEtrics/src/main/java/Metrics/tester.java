package Metrics;

import AndroidProjectRepresentation.*;

import com.github.javaparser.JavaParser;
import com.github.javaparser.ParseException;
import com.github.javaparser.ast.CompilationUnit;
import org.json.simple.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class tester {


    public static String x ="0";
    // deploy -> mvn install:install-file -DgroupId=com.greenlab -DartifactId=Metrics -Dversion=1.0 -Dpackaging=jar -Dfile=target/Metrics-1.0-SNAPSHOT.jar
   public static void main(String[] args) throws Exception {
     //  String file ="/Users/ruirua/GDResults/N2AppTest/MonkeyTest28_02_19_16_02_42/N2AppTest--uminho.di.greenlab.n2apptest.json";
       //String file ="/Users/ruirua/repos/GreenDroid/GDMetrics/src/main/java/Metrics/tester.java";
      String file = "/Users/ruirua/repos/AnaDroid/demoProjects/N2AppTest/_TRANSFORMED_/"  + "N2AppTest--uminho.di.greenlab.n2apptest.json";
           //    + "app/src/main/java/uminho/di/greenlab/n2apptest/MainActivity.java";

       // evaluateAPIMethod(file);
        //testGetMethod(file);
       //String file = "/Users/ruirua/GDResults/N2AppTest/MonkeyTest06_03_19_16_41_19/" +
        //

      // testGetMethod(file);
      // testClassInst();
       //
       testJSONLoad(file);
        //   testServer();
      //
      // testAPIEval(file);

        

   }

    //


    public static void testGetMethod(String file){

        String x = new APICallUtil().fromJSONFile(file).toJSONString();
        JSONObject jo = new APICallUtil().fromJSONFile(file);
        APICallUtil acu = ((APICallUtil) new APICallUtil().fromJSONObject( jo));
        System.out.println(acu.proj);
        MethodInfo mi = acu.getMethodOfClass("onCreate(--Bundle)", "uminho.di.greenlab.n2apptest.MainActivity");
        System.out.println(mi.methodName);

    }


    public static void testClassInst() throws Exception{
      APICallUtil apu =    new APICallUtil();
      String file = "/Users/ruirua/repos/AnaDroid/demoProjects/N2AppTest/_TRANSFORMED_/app/src/main/java/uminho/di/greenlab/n2apptest/MainActivity.java";
      apu.proj.apps.add(new AppInfo());
      apu.processJavaFile(file);
      System.out.println(apu.proj);
      JSONObject jo = apu.proj.getCurrentApp().allJavaClasses.stream().findFirst().get().toJSONObject(apu.proj.getCurrentApp().appID);
        System.out.println(jo);
        ClassInfo cc = ((ClassInfo) new ClassInfo(apu.proj.getCurrentApp().appID).fromJSONObject(jo));
        System.out.println(cc);
    }


    public static void testJSONLoad(String file){

     //  String file = "/Users/ruirua/GDResults/N2AppTest/MonkeyTest06_03_19_16_41_19/" +
    //           "N2AppTest--uminho.di.greenlab.n2apptest.json";

        JSONObject jo = new APICallUtil().fromJSONFile(file);
        APICallUtil acu = ((APICallUtil) new APICallUtil().fromJSONObject( jo));
       // JSONObject jo2 = acu.toJSONObject(acu.proj.projectID);
        JSONObject jo2 = acu.toJSONObject(acu.proj.projectID);
        APICallUtil apu2 = ((APICallUtil) new APICallUtil().fromJSONObject(jo2));
        System.out.println(apu2.proj + acu.proj.toString());

   }

/*
    public static void testServer(){
        JSONObject jo = new JSONObject();
        jo.put("device_serial_number", "1") ;
        jo.put("device_brand", "marroco21") ;
        jo.put("device_model", "ipheno21") ;

        GreenSourceAPI.sendDeviceToDB(jo.toJSONString());

       // GSUtils.sendJSONtoDB("http://greensource.di.uminho.pt/devices/", jo.toJSONString());

    }



    public static void evaluateAPIMethod(String filename) throws IOException {
        File file = new File(filename);
        FileInputStream in = new FileInputStream(file);
        CompilationUnit cu=null;
        try {
            // parse the file
            cu = JavaParser.parse(in, null, false);
        } catch (ParseException e) {
            e.printStackTrace();
        } finally {
            in.close();
        }
        System.out.println(cu);

    }


*/

    public static void testAPIEval(String filename) throws IOException {
        //String filename ="/Users/ruirua/repos/GreenDroid/GDMetrics/src/main/java/Metrics/tester.java";
        APIEvaluator a = new APIEvaluator();
        byte[] mi = filename.getBytes();
        int i [] = new int[10];
        List<String> l = new ArrayList<>();
        Utils.Pair<List<String>, APIEvaluator> p = new Utils.Pair<>(l, a);
        File file = new File(filename);
        FileInputStream in = new FileInputStream(file);
        CompilationUnit cu=null;
        try {
            // parse the file
            cu = JavaParser.parse(in, null, false);
            FileInputStream apaga = new FileInputStream(file);
        } catch (ParseException  | IOException e) {
            e.printStackTrace();
        } finally {
            in.close();
        }
        long start = System.currentTimeMillis();
        a.eval(cu);
        long finish = System.currentTimeMillis();
        long timeElapsed = finish - start;
        System.out.println(timeElapsed);
        System.out.println(APIEvaluator.allMethods);
    }



/*

    public void methodToLoad(){
        Integer i = new Integer(1), z=0;
        testJSONLoad();
        x.getBytes();
        x.replaceAll("x", "cc");
        boolean b = false;
        double d = 2.0;
        long l = 200;
        String file = "";
        JSONObject jo = new APICallUtil().fromJSONFile(file);
        APICallUtil acu = ((APICallUtil) new APICallUtil().fromJSONObject( jo));
    }

*/
}
