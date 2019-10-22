package com.ruirua.futexam.database;

import android.arch.lifecycle.LiveData;
import android.arch.lifecycle.MutableLiveData;
import android.arch.lifecycle.Observer;
import android.content.Context;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.support.annotation.Nullable;
import android.util.Log;

import com.ruirua.futexam.database.models.Image;
import com.ruirua.futexam.database.models.Question;
import com.ruirua.futexam.database.models.User;
import com.ruirua.futexam.utilities.SampleData;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

/**
 * Created by ruirua on 02/08/2019.
 */

public class AppRepository {

    private static AppRepository ourInstance; // = new AppRepository();
    public LiveData<List<Question>> questions = new MutableLiveData<>();
    public LiveData<User> actualUser = new MutableLiveData<>();

    private AppDatabase mDb;
    private Executor executor = Executors.newSingleThreadExecutor();

    public static AppRepository getInstance(Context context) {
        if (ourInstance == null) {
            ourInstance = new AppRepository( context);
        }
        return ourInstance;
    }

    private AppRepository(Context context) {
        mDb = AppDatabase.getInstance(context);
        questions = getAllQuestions();
        actualUser = loadFirstUser();

    }

    private LiveData<User> loadFirstUser() {
        return mDb.globalDAO().getFirstUser();
    }

    public void addSampleData(Resources res) {
        executor.execute(new Runnable() {
            @Override
            public void run() {
                mDb.globalDAO().insertAllImages(SampleData.getSampleImages(res));
                mDb.globalDAO().insertQuestionAll(SampleData.getSampleQuestions());
                mDb.globalDAO().insertUser(SampleData.getUser(res));
            }
        });
    }



    public void freezeDB(){
        mDb.copyDbFile();
    }

    // could get data from local repo or ws
    // we dont need to use executor to do this in background thread since room already does this automatically
    // General rule : wherever a query retrieves a live data object, room handles the background thread itself.
    // if its another thing then i have to handle myself
    public LiveData<List<Question>> getAllQuestions(){
       // if ( questions==null || questions.getValue()==null ){
            return  ( mDb.globalDAO().getAllQuestions());
      //  }

    }

    public List<Question> getAllQuestionsSimple(){
        // if ( questions==null || questions.getValue()==null ){
        return  ( mDb.globalDAO().getAllQuestionSimple());
        //  }

    }


    public void deleteAllNotes() {
        executor.execute(new Runnable() {
            @Override
            public void run() {
                mDb.globalDAO().deleteAllQuestions();
            }
        });
    }

    public Question  getQuestionById(int id) {
        return mDb.globalDAO().getQuestionById(id);
    }



    public int getQuestionCount() {
      return mDb.globalDAO().getQuestionCount();
    }



    public Image getImageById( int id) {
        return mDb.globalDAO().getImageById(id);
    }

    public void addQuestionList(List<Question> answeredQuestions) {
        executor.execute(new Runnable() {
            @Override
            public void run() {
                mDb.globalDAO().insertQuestionAll(answeredQuestions);
            }
        });
    }

    public void addUser(LiveData<User> currentUser) {
        executor.execute(new Runnable() {
            @Override
            public void run() {
                mDb.globalDAO().insertUser(currentUser.getValue());
            }
        });
    }
}

