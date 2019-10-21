package com.ruirua.futexam.database.models;

import android.arch.persistence.room.ColumnInfo;
import android.arch.persistence.room.Embedded;
import android.arch.persistence.room.Entity;
import android.arch.persistence.room.ForeignKey;
import android.arch.persistence.room.Ignore;
import android.arch.persistence.room.Index;
import android.arch.persistence.room.PrimaryKey;

/**
 * Created by ruirua on 02/08/2019.
 */

@Entity(tableName = "questions",
        indices = {@Index(value = {"question"}, unique = true)}
        ,foreignKeys =  @ForeignKey(entity = Image.class, parentColumns = "id",  childColumns = "img_id")
            //            , @ForeignKey(entity = Category.class, parentColumns = "id",  childColumns = "cat_id")}
        )
public class Question {

    @PrimaryKey(autoGenerate = true)
    private int id;

    @ColumnInfo(name = "question")
    private String question;

    @ColumnInfo(name = "answer")
    private String answer;

    @ColumnInfo(name = "answer1")
    private String alternative1;

    @ColumnInfo(name = "answer2")
    private String alternative2;

    @ColumnInfo(name = "answer3")
    private String alternative3;

    @ColumnInfo(name = "img_id")
    private int img_id ;

    @ColumnInfo(name = "difficulty")
    private int difficulty = 1 ;

    @ColumnInfo(name = "answered")
    private boolean answered = false ;



    @Embedded
    private Category category;

    @Ignore
    public Question(int id, String question, String answer, String alternative1, String alternative2, String alternative3, int img_id, int difficulty, Category category) {
        this.id = id;
        this.question = question;
        this.answer = answer;
        this.alternative1 = alternative1;
        this.alternative2 = alternative2;
        this.alternative3 = alternative3;
        this.img_id = img_id;
        this.difficulty = difficulty;
        this.category = category;
    }

    @Ignore
    public Question(int id , String question, String answer, String alternative1, String alternative2, String alternative3) {
        this.id = id;
        this.question = question;
        this.answer = answer;
        this.alternative1 = alternative1;
        this.alternative2 = alternative2;
        this.alternative3 = alternative3;
    }

    @Ignore
    public Question(String question, String answer, String alternative1, String alternative2, String alternative3) {
        this.question = question;
        this.answer = answer;
        this.alternative1 = alternative1;
        this.alternative2 = alternative2;
        this.alternative3 = alternative3;
        this.category = new Category(Category.CategoryDesignation.CLUB);
    }

    public Question(int id, String question, String answer, String alternative1, String alternative2, String alternative3, int img_id, Category category) {
        this.id = id;
        this.question = question;
        this.answer = answer;
        this.alternative1 = alternative1;
        this.alternative2 = alternative2;
        this.alternative3 = alternative3;
        this.img_id = img_id;
        this.category = category;
    }
    @Ignore
    public Question( String question, String answer, String alternative1, String alternative2, String alternative3, int img_id, Category category) {
        this.id = id;
        this.question = question;
        this.answer = answer;
        this.alternative1 = alternative1;
        this.alternative2 = alternative2;
        this.alternative3 = alternative3;
        this.img_id = img_id;
        this.category = category;
    }

    public int getDifficulty() {
        return difficulty;
    }

    public void setDifficulty(int difficulty) {
        this.difficulty = difficulty;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getQuestion() {
        return question;
    }

    public void setQuestion(String question) {
        this.question = question;
    }

    public String getAnswer() {
        return answer;
    }

    public void setAnswer(String answer) {
        this.answer = answer;
    }

    public String getAlternative1() {
        return alternative1;
    }

    public void setAlternative1(String alternative1) {
        this.alternative1 = alternative1;
    }

    public String getAlternative2() {
        return alternative2;
    }

    public void setAlternative2(String alternative2) {
        this.alternative2 = alternative2;
    }

    public String getAlternative3() {
        return alternative3;
    }

    public void setAlternative3(String alternative3) {
        this.alternative3 = alternative3;
    }

    public int getImg_id() {
        return img_id;
    }

    public void setImg_id(int img_id) {
        this.img_id = img_id;
    }

    public Category getCategory() {
        return category;
    }

    public void setCategory(Category cat_id) {
        this.category = cat_id;
    }

    @Override
    public String toString() {
        return "Question{" +
                "id=" + id +
                ", question='" + question + '\'' +
                ", answer='" + answer + '\'' +
                ", alternative1='" + alternative1 + '\'' +
                ", alternative2='" + alternative2 + '\'' +
                ", alternative3='" + alternative3 + '\'' +
                '}';
    }

    public boolean isAnswered() {
        return answered;
    }

    public void setAnswered(boolean answered) {
        this.answered = answered;
    }
}
