package com.ruirua.futexam.database.models;

import android.arch.lifecycle.LiveData;
import android.arch.lifecycle.MutableLiveData;
import android.arch.persistence.room.Dao;
import android.arch.persistence.room.Delete;
import android.arch.persistence.room.Insert;
import android.arch.persistence.room.OnConflictStrategy;
import android.arch.persistence.room.Query;

import java.util.List;

/**
 * Created by ruirua on 02/08/2019.
 */


@Dao
public interface GlobalDAO {

     /*
     *  Questions
     */

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insertQuestion(Question question);

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insertQuestionAll(List<Question> question);

    @Delete
    void deleteQuestion(Question question);

    @Query("select * from questions where id= :questid")
    Question getQuestionById(int questid);

    @Query("select * from questions" )//order by id DESC")
    LiveData<List<Question>> getAllQuestions();

    @Query("select * from questions" )// order by id DESC")
    List<Question> getAllQuestionSimple();

    @Query("update questions set answered = :answered1 where id = :questionid")
    void updateQuestionAnswered(int questionid,boolean answered1);


    @Query("delete from questions")
    void  deleteAllQuestions();

    @Query("select count(*) from questions")
    int getQuestionCount();

    /*
     *  Img
     */

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insertImage(Image image);

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insertAllImages(List<Image> images);

    @Delete
    void deleteImage(Image image);

    // @Query("select * from images where questions.id= :id")
   // Question getImageById(int id);

    @Query("select * from images") // order by date DESC")
    List<Image> getAllImages();


    @Query("delete from images")
    void  deleteAllImages();

    @Query("select count(*) from images")
    int getImageCount();

    @Query("select * from images where id= :imageid")
    Image getImageById(int imageid);


    /*
     *  Users
     */

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insertUser(User image);

    @Delete
    void deleteUser(User image);

    // @Query("select * from images where questions.id= :id")
    // Question getImageById(int id);

    @Query("select * from users") // order by date DESC")
    List<Image> getAllUsers();


    @Query("delete from users")
    void  deleteAllUsers();

    @Query("select count(*) from users")
    int getUsersCount();

    @Query("select * from users where username= :uname")
    Image getUserById(String uname);

    @Query("select * from users order by id limit 1")
    LiveData<User> getFirstUser();
}
