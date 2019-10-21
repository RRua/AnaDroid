package com.ruirua.futexam.ui.viewmodels;

import android.app.Application;
import android.arch.lifecycle.AndroidViewModel;
import android.arch.lifecycle.LifecycleOwner;
import android.arch.lifecycle.LiveData;
import android.arch.lifecycle.MutableLiveData;
import android.arch.lifecycle.Observer;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;

import com.ruirua.futexam.database.AppRepository;
import com.ruirua.futexam.database.models.Image;
import com.ruirua.futexam.database.models.Question;
import com.ruirua.futexam.database.models.User;
import com.ruirua.futexam.utilities.SampleData;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executor;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.stream.Collectors;

/**
 * Created by ruirua on 06/08/2019.
 */

public class QuestionViewModel extends AndroidViewModel{

    public static final String TAG = QuestionViewModel.class.getSimpleName();
    public LiveData<List<Question>> questions = new MutableLiveData<>();
    public LiveData<User> currentUser = new MutableLiveData<>();
    private AppRepository repository;
    private Executor executor = Executors.newSingleThreadExecutor();



    public QuestionViewModel(@NonNull Application application) {
        super(application);
        repository = AppRepository.getInstance(application.getApplicationContext());
        questions = repository.questions;
        currentUser = repository.actualUser;
        // getQuestion();
    }

    public void addSampleData(Resources res) {
        repository.addSampleData(res);
    }

    public int getQuestionCount() {
        ExecutorService executor = Executors.newSingleThreadExecutor();
        Callable<Integer> callable = new Callable<Integer>() {
            @Override
            public Integer call() {
                return repository.getQuestionCount();
            }
        };
        Future<Integer> future = executor.submit(callable);
        executor.shutdown();
        try {
            return future.get();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (ExecutionException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public List<Question> loadAllQuestionsSimple(){
       return  repository.getAllQuestionsSimple();
    }


    public Bitmap getImageById(int id){
        return Image.toBitmap(repository.getImageById(id).getImgBlob());
    }

    public void addQuestions(List<Question> answeredQuestions) {
        repository.addQuestionList(answeredQuestions);
    }

    public void setUser(LiveData<User> currentUser) {
        repository.addUser(currentUser);
    }
}
