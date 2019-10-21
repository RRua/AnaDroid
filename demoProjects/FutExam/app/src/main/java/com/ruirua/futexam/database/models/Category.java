package com.ruirua.futexam.database.models;

import android.arch.persistence.room.Entity;
import android.arch.persistence.room.Ignore;
import android.arch.persistence.room.PrimaryKey;

/**
 * Created by ruirua on 02/08/2019.
 */

@Entity(tableName = "categories")
public class Category {

    @PrimaryKey(autoGenerate = true)
    private int category_id;

    private CategoryDesignation categoryDesignation;


    public enum CategoryDesignation {
        PLAYER (0),
        CLUB(1),
        COMPETITION(2),
        COUNTRY (3),
        MISC (4);
        private int code;

        CategoryDesignation (int code) {
            this.code = code;
        }

        public int getCode() {
            return code;
        }

    }

    public Category(CategoryDesignation categoryDesignation) {
        this.categoryDesignation = categoryDesignation;
    }

    @Ignore
    public Category(int id, CategoryDesignation categoryDesignation) {
        this.category_id = id;
        this.categoryDesignation = categoryDesignation;
    }

    public int getCategory_id() {
        return category_id;
    }

    public void setCategory_id(int id) {
        this.category_id = id;
    }

    public CategoryDesignation getCategoryDesignation() {
        return categoryDesignation;
    }

    public void setCategoryDesignation(CategoryDesignation categoryDesignation) {
        this.categoryDesignation = categoryDesignation;
    }

    @Override
    public String toString() {
        return "Category{" +
                "id=" + category_id +
                ", categoryDesignation=" + categoryDesignation +
                '}';
    }
}
