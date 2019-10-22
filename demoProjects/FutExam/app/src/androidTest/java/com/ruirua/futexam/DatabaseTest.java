package com.ruirua.futexam;

/**
 * Created by ruirua on 06/08/2019.
 */

import android.arch.lifecycle.LiveData;
import android.arch.lifecycle.Observer;
import android.arch.persistence.room.Room;
import android.content.Context;
import android.support.annotation.Nullable;
import android.support.test.InstrumentationRegistry;
import android.support.test.runner.AndroidJUnit4;
import android.util.Log;

import com.ruirua.futexam.database.AppDatabase;
import com.ruirua.futexam.database.models.GlobalDAO;
import com.ruirua.futexam.database.models.Question;
import com.ruirua.futexam.utilities.SampleData;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;


import java.util.List;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotEquals;

/**
 * Created by ruirua on 30/07/2019.
 */

@RunWith(AndroidJUnit4.class)
public class DatabaseTest {

    public static final String TAG = "JunitDB";
    AppDatabase appDatabase;
    private GlobalDAO noteDAO;

    @Before
    public void createDB(){
        Context ctx = InstrumentationRegistry.getTargetContext();
        appDatabase = Room.inMemoryDatabaseBuilder(ctx, AppDatabase.class).build();
        noteDAO = appDatabase.globalDAO();
        noteDAO.deleteAllQuestions();
        Log.i(TAG, "createDB: I created the db");
    }

    @After
    public void closeDb(){
        appDatabase.close();
        Log.i(TAG, "closeDb: closed");
    }


    @Test
    public void createAndRetrieveNotes() {
        // Context of the app under test.
       // noteDAO.insertQuestionAll(SampleData.getSampleQuestions());
        int count = noteDAO.getQuestionCount();
        assertNotEquals(SampleData.getSampleQuestions().size(), count );
        //appDatabase.close();
    }

    @Test
    public void dummyTest() {
        assertEquals(true, true);
        //appDatabase.close();
    }

/*
    @Test
    public void deleteDB(){
        Context ctx = InstrumentationRegistry.getTargetContext();
        ctx.deleteDatabase("AppFutDatabase.db");
        Log.i(TAG, "deleteDB: deleted");
    }
*/


}
