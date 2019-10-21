package com.ruirua.futexam.database.models;

import android.arch.persistence.room.TypeConverter;

import java.util.Date;

/**
 * Created by ruirua on 02/08/2019.
 */

public class EnumConverter {

    @TypeConverter
    public static Category.CategoryDesignation toCategory(int category){

        if (category== Category.CategoryDesignation.CLUB.getCode()){
           return  Category.CategoryDesignation.CLUB;
        }
        else if (category== Category.CategoryDesignation.COMPETITION.getCode()){
            return  Category.CategoryDesignation.COMPETITION;
        }
        else if (category== Category.CategoryDesignation.COUNTRY.getCode()){
            return  Category.CategoryDesignation.COUNTRY;
        }
        else if (category== Category.CategoryDesignation.PLAYER.getCode()){
            return  Category.CategoryDesignation.PLAYER;
        }
        else {
            return Category.CategoryDesignation.MISC;
        }
    }

    @TypeConverter
    public static int toInt(Category.CategoryDesignation cat){
        return cat==null ? null : cat.getCode();
    }
}
