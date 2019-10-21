package com.ruirua.futexam.database.models;

import android.arch.persistence.room.ColumnInfo;
import android.arch.persistence.room.Entity;
import android.arch.persistence.room.Ignore;
import android.arch.persistence.room.PrimaryKey;

import java.util.Arrays;


/**
 * Created by ruirua on 22/08/2019.
 */

@Entity(tableName = "users")
public class User {


    @PrimaryKey(autoGenerate = true)
    private int id;

    @ColumnInfo(name = "username")
    private String username;


    @ColumnInfo(name = "points")
    private int points;


    @ColumnInfo(name = "coins")
    private int coins;

    @ColumnInfo(typeAffinity = ColumnInfo.BLOB)
    private byte[] imgBlob;

    public int getCoins() {
        return coins;
    }

    public void setCoins(int coins) {
        this.coins = coins;
    }
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public byte[] getImgBlob() {
        return imgBlob;
    }

    public void setImgBlob(byte[] imgBlob) {
        this.imgBlob = imgBlob;
    }

    public String getUsername() {
        return username;
    }

    public int getPoints() {
        return points;
    }

    public User(String username, int points) {
        this.username = username;
        this.points = points;
    }

    @Ignore
    public User(int id, String username, int points, int coins, byte[] imgBlob) {
        this.id = id;
        this.username = username;
        this.points = points;
        this.imgBlob = imgBlob;
        this.coins = coins;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public void setPoints(int points) {
        this.points = points;
    }

    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", username='" + username + '\'' +
                ", points=" + points +
                ", coins=" + coins +
                '}';
    }
}
