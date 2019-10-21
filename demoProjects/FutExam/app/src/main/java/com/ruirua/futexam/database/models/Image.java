package com.ruirua.futexam.database.models;

import android.arch.persistence.room.ColumnInfo;
import android.arch.persistence.room.Entity;
import android.arch.persistence.room.Ignore;
import android.arch.persistence.room.PrimaryKey;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.Arrays;

/**
 * Created by ruirua on 02/08/2019.
 */

@Entity(tableName = "images")
public class Image {

    @PrimaryKey(autoGenerate = true)
    private int id;

    @ColumnInfo(typeAffinity = ColumnInfo.BLOB)
    private byte[] imgBlob;


    public Image(byte[] imgBlob) {
        this.imgBlob = imgBlob;
    }

    @Ignore
    public Image(int id, byte[] imgBlob) {
        this.id = id;
        this.imgBlob = imgBlob;
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

    @Override
    public String toString() {
        return "Image{" +
                "id=" + id +
                ", imgBlob=" + Arrays.toString(imgBlob) +
                '}';
    }

    @Ignore
    public  static byte[] toByteArray(Bitmap bmp){
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bmp.compress(Bitmap.CompressFormat.PNG, 100, stream);
        byte[] byteArray = stream.toByteArray();
        bmp.recycle();
        return byteArray;
    }

    @Ignore
    public  static Bitmap toBitmap(byte [] byteArray){
        return BitmapFactory.decodeByteArray(byteArray, 0, byteArray.length);
    }


}
