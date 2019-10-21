package com.ruirua.futexam.database;

import android.arch.persistence.db.SupportSQLiteDatabase;
import android.arch.persistence.room.Database;
import android.arch.persistence.room.Room;
import android.arch.persistence.room.RoomDatabase;
import android.arch.persistence.room.TypeConverters;
import android.content.Context;
import android.os.Environment;
import android.support.annotation.NonNull;
import android.util.Log;

import com.ruirua.futexam.database.models.EnumConverter;
import com.ruirua.futexam.database.models.GlobalDAO;
import com.ruirua.futexam.database.models.Image;
import com.ruirua.futexam.database.models.Question;
import com.ruirua.futexam.database.models.User;
import com.ruirua.futexam.utilities.SampleData;

import static com.ruirua.futexam.utilities.FileUtils.copyFile;

import java.io.File;
import java.io.IOException;
import java.util.concurrent.Executors;

/**
 * Created by ruirua on 02/08/2019.
 */

@TypeConverters(EnumConverter.class)
@Database(entities = {Question.class,Image.class, User.class}, version = 1) // 1st version of my dbase
//@Database(entities = {Question.class}, version = 1) // 1st version of my dbase
public abstract class AppDatabase extends RoomDatabase {
    public static final String DATABASE_NAME = "AppFutDatabase.db";
    public static volatile  AppDatabase instance;   // it can be only referenced from main memory
    private static final Object LOCK = new Object();


    public abstract GlobalDAO globalDAO();

    public static AppDatabase getInstance(Context context) {
        if (instance == null) {
            synchronized (LOCK){
                if (instance == null){
                    instance = Room.databaseBuilder(context.getApplicationContext(), AppDatabase.class, DATABASE_NAME).allowMainThreadQueries().addCallback(new Callback() {
                        @Override
                        public void onCreate(@NonNull SupportSQLiteDatabase db) {
                            super.onCreate(db);
                            Executors.newSingleThreadScheduledExecutor().execute(new Runnable() {
                                @Override
                                public void run() {
                                    getInstance(context).globalDAO().insertAllImages(SampleData.getSampleImages(context.getResources()));
                                    getInstance(context).globalDAO().insertQuestionAll(SampleData.getSampleQuestions());

                                }
                            });
                        }
                    }).build();
                }
            }
        }
        return instance;
    }


    // Note: gambiarra para copiar o .db file para um local onde possa acedor on non-rooted devices
    public void copyDbFile(){
        File f=new File("/data/data/" + this.getClass().getPackage().getName().replace(".database","")   +"/databases/"+ DATABASE_NAME);
        if (f.exists()){
            File dest = new File(Environment.getExternalStorageDirectory() + "/futdump.db" );
            try {
                dest.createNewFile();
                copyFile(f,dest);
                Log.i("tacho", "copyDbFile: copiedDb");
            } catch (IOException e) {
                e.printStackTrace();
            }

        }
        else{
            Log.i("tacho", "no hay");
        };
    }

}

